class_name EOSClient
extends Node

var logger = Logger.add_module("eos client")

# singals emitted on the client
signal client__host_joined
signal client__self_parted

# signals emitted on the host
signal host__client_joined(client_id)
signal host__client_parted(client_id)

## Paste your product keys here ##
@onready var product_id: String = "d22cbf03cb0c4de980b1b91757d865d0"
@onready var sandbox_id: String = "8c9e2ad839134d53820e5738ae93e5d9"
@onready var deployment_id: String = "095f97697f334f97970c24de9a67641c"
@onready var client_id: String = "xyza7891eprCFSDybfE3FxNhtEhwLWwj"
@onready var client_secret: String = "FpqS81ZHB9jmJ3pOILptv9RMsvIPE6J+mKJYu+s9SQ8"
@onready var encryption_key: String = "96e0f312b85f6f9c338abaefb51d0cf14028adcbc0053771c4ce12cac4a96cf3"

var EOSReady: Gate = Gate.new()
var peer: EOSGMultiplayerPeer

class Gate:
	signal OnReady
	var Ready: bool = false
	func OpenGate():
		Ready = true
		OnReady.emit()
	func AwaitGate():
		if Ready: return
		await OnReady

func active_mode():
	if peer.get_active_mode() == 0: return "MODE_NONE"
	if peer.get_active_mode() == 1: return "MODE_SERVER"
	if peer.get_active_mode() == 2: return "MODE_CLIENT"
	if peer.get_active_mode() == 3: return "MODE_MESH"
	return "MODE_NONE"

func is_offline(): return peer.get_active_mode() == 0
func is_server(): return peer.get_active_mode() == 1
func is_client(): return peer.get_active_mode() == 2

func _enter_tree():
	Global.eos = self

func _ready():
	rebuild_eos()
	
func rebuild_eos():
	peer = EOSGMultiplayerPeer.new()
	
	# Initialize the SDK
	var init_options = EOS.Platform.InitializeOptions.new()
	init_options.product_name = "hackingwithfriends"
	init_options.product_version = "0.1"

	var init_result := EOS.Platform.PlatformInterface.initialize(init_options)
	if init_result != EOS.Result.Success:
		logger.info("Failed to initialize EOS SDK: ", EOS.result_str(init_result))
		return
	logger.info("Initialized EOS Platform")

	# Create platform
	var create_options = EOS.Platform.CreateOptions.new()
	create_options.product_id = product_id
	create_options.sandbox_id = sandbox_id
	create_options.deployment_id = deployment_id
	create_options.client_id = client_id
	create_options.client_secret = client_secret
	create_options.encryption_key = encryption_key
	
	var create_result = 0
	create_result = EOS.Platform.PlatformInterface.create(create_options)
	if not create_result:
		logger.info("Failed to create EOS Platform")
	logger.info("EOS Platform Created")
	
	# Setup Logs from EOS
	EOS.get_instance().logging_interface_callback.connect(func(msg):
		msg = EOS.Logging.LogMessage.from(msg) as EOS.Logging.LogMessage
		logger.info("SDK %s | %s" % [msg.category, msg.message]))
		
	var res := EOS.Logging.set_log_level(EOS.Logging.LogCategory.AllCategories, EOS.Logging.LogLevel.Info)
	if res != EOS.Result.Success:
		logger.info("Failed to set log level: ", EOS.result_str(res))
	
	peer.peer_connected.connect(func(peer_id: int):
		#var peers = peer.get_all_peers()
		#if !peers.has(peer_id): return
		logger.info("peer connected " + str(peer_id))
		if peer.get_active_mode() == EOS.P2P.Mode.Client and peer_id == 1:
			client__host_joined.emit()
		if peer.get_active_mode() == EOS.P2P.Mode.Server:
			host__client_joined.emit(peer_id)
	)
	peer.peer_connection_closed.connect(func(data: Dictionary):
		match data.reason:
			EOS.P2P.ConnectionClosedReason.ClosedByPeer:
				if peer.get_active_mode() != EOS.P2P.Mode.Server:
					client__self_parted.emit()
			_: #There was an error
				logout()
				Global.main.unload_all()
				Global.main.load_menu("main_menu")
		
		)
	peer.peer_disconnected.connect(func(peer_id: int):
		logger.info("Peer has disconnected. Peer id: " + str(peer_id))
		if peer.get_active_mode() == EOS.P2P.Mode.Server:
			host__client_parted.emit(peer_id)
			logger.info("player disconnected on purpose and we're the server. Despawn their avatar")
		)
		
	EOSReady.OpenGate()

func do_device_login(display_name: String):
	await EOSReady.AwaitGate()
	
	# Login using Device ID (no user interaction/credentials required)
	var opts = EOS.Connect.CreateDeviceIdOptions.new()
	opts.device_model = OS.get_name() + " " + OS.get_model_name()
	EOS.Connect.ConnectInterface.create_device_id(opts)
	await EOS.get_instance().connect_interface_create_device_id_callback

	var credentials = EOS.Connect.Credentials.new()
	credentials.token = null
	credentials.type = EOS.ExternalCredentialType.DeviceidAccessToken
	
	var user_login_info = EOS.Connect.UserLoginInfo.new()
	user_login_info.display_name = display_name
	
	var login_options = EOS.Connect.LoginOptions.new()
	login_options.credentials = credentials
	login_options.user_login_info = user_login_info
	EOS.Connect.ConnectInterface.login(login_options)
	
	var data = await EOS.get_instance().connect_interface_login_callback
	if not data.success:
		logger.info("Login failed")
		EOS.print_result(data)
	else:
		logger.info("Login successfull: local_user_id=" + str(data.local_user_id))
	return data

func do_developer_login(retrying = false):
	await EOSReady.AwaitGate()
	
	var credentials = EOS.Auth.Credentials.new()
	credentials.token = DevSettings.settings.dev_credential
	credentials.type = EOS.Auth.LoginCredentialType.Developer
	credentials.id = "localhost:7878"
	
	var login_options = EOS.Auth.LoginOptions.new()
	login_options.credentials = credentials
	login_options.scope_flags = EOS.Auth.ScopeFlags.BasicProfile \
		|  EOS.Auth.ScopeFlags.FriendsList | EOS.Auth.ScopeFlags.Presence
	
	EOS.Auth.AuthInterface.login(login_options)
	var data: Dictionary = await EOS.get_instance().auth_interface_login_callback
	
	if not data.success || data.local_user_id == "":
		logger.info("Login failed")
		EOS.print_result(data)
	else:
		var epic_account_id = data.local_user_id
		logger.info("Epic Account Id: " + str(epic_account_id))

		var copy_user_auth_token = EOS.Auth.AuthInterface.copy_user_auth_token(EOS.Auth.CopyUserAuthTokenOptions.new(), epic_account_id)
		var token = copy_user_auth_token.token
		#

		# Get user info of logged in user
		var options = EOS.UserInfo.QueryUserInfoOptions.new()
		options.local_user_id = epic_account_id
		options.target_user_id = epic_account_id
		EOS.UserInfo.UserInfoInterface.query_user_info(options)
		# Connect the account to get a Product User Id from the Epic Account Id
		var connect_credentials = EOS.Connect.Credentials.new()
		connect_credentials.token = token.access_token
		connect_credentials.type = EOS.ExternalCredentialType.Epic
	
		var connect_login_options = EOS.Connect.LoginOptions.new()
		connect_login_options.credentials = connect_credentials
		EOS.Connect.ConnectInterface.login(connect_login_options)
		
		var connect_data = await EOS.get_instance().connect_interface_login_callback
		if not connect_data.success:
			logger.info("Login failed")
			EOS.print_result(connect_data)
			
			if connect_data.result_code == 3 and retrying == false: # user account not found, per https://dev.epicgames.com/docs/epic-online-services/sdk-error-codes
																	# retrying prevents infinite recursion
				logger.info("Failed to log in because dev user did not exist. User has been created, but retry loop has not been implemented. Please just log in again")
				var create_user_options := EOS.Connect.CreateUserOptions.new()
				create_user_options.continuance_token = connect_data.continuance_token
				EOS.Connect.ConnectInterface.create_user(create_user_options)
				do_developer_login(true)
		else:
			logger.info("Login successfull: local_user_id=" + str(connect_data.local_user_id))
		return connect_data


func create_server():
	var result := peer.create_server("gamesocketid") # can run multiple sockets for different channels (I think), but we only need one socket, so hard code a name 
	if result != OK:
		logger.info("create server failed")
	else:
		logger.info("create server succeeded")
		multiplayer.multiplayer_peer = peer
		#
		#multiplayer.peer_connected.connect(func(_client_id):
		#)
		Global.eos.host__client_joined.connect(func(_client_id):
			spawn_player(_client_id)
		)
		Global.eos.host__client_parted.connect(func(_client_id):
			despawn_player(_client_id)
		)
	spawn_player(1)
		
	return result

func spawn_player(_client_id: int):
	if Global.main.get_player_by_id(_client_id): return # we're already spawned
	logger.info("spawning player for client " + str(_client_id))
	var player_node = preload("res://scenes/player.tscn").instantiate()
	player_node.name = str(_client_id)
	player_node.owner_id = _client_id
	Global.main.M.players.add_child(player_node, true) # spawn the player for everyone via MultiplayerSpawner

func despawn_player(_client_id: int):
	peer.disconnect_peer(_client_id)
	for player in Global.main.M.players.get_children():
		if player.owner_id == _client_id:
			if player.character:
				player.character.queue_free()
				Global.main.M.characters.remove_child(player.character)
			player.queue_free()
			Global.main.M.players.remove_child(player)

func logout():
	peer.disconnect_peer(1)
	for peer_id in multiplayer.get_peers():
		peer.disconnect_peer(peer_id)
	peer.close()
	var opts = EOS.Auth.LogoutOptions.new()
	opts.local_user_id = Global.main.local_user_id
	EOS.Auth.AuthInterface.logout(opts)

func connect_client(remote_user_id: String):
	var result := peer.create_client("gamesocketid", remote_user_id)
	if result != OK:
		logger.info("failed to connect to server")
	else:
		multiplayer.multiplayer_peer = peer
		logger.info("connected to server")
	return result


#func lookup_peer(peer_id: int):
	#var product_user_id = Global.eos.peer.get_peer_user_id(peer_id)
	#var opts := EOS.Connect.QueryProductUserIdMappingsOptions.new()
	#opts.product_user_ids = [product_user_id]
	#EOS.Connect.ConnectInterface.query_product_user_id_mappings(opts)
	#var query_ret = await IEOS.connect_interface_query_product_user_id_mappings_callback
	#
	#
	#var get_opts = EOS.Connect.GetProductUserIdMappingOptions.new()
	#get_opts.target_product_user_id = product_user_id
	#get_opts.account_id_type = EOS.ExternalAccountType.Epic
	#var get_ret = EOS.Connect.ConnectInterface.get_product_user_id_mapping(get_opts)
	#if not EOS.is_success(get_ret):
		#print("--- Lobby: Connect: get_product_user_id_mapping: error: ", EOS.result_str(get_ret))
#
	#return get_ret["account_id"]
#

