extends BoundNode
class_name LobbyMenu

var logger = Logger.add_module("lobby_menu")

func on_bound():
	Global.eos.peer.set_auto_accept_connection_requests(true)
	if Global.eos.is_client(): M.start_game.visible = false
	
	M.user_id.text = Global.main.local_user_id
	
	M.copy_id.pressed.connect(func():
		DisplayServer.clipboard_set(M.user_id.text)
	)
	
	M.start_game.pressed.connect(func():
		# stop letting people into the game
		Global.eos.peer.set_auto_accept_connection_requests(false)
		Global.main.load_stage("stage_1")
	)
	
	M.back.pressed.connect(func():
		# log out and stop server
		Global.eos.logout()
		Global.main.unload_all()
		Global.main.load_menu("main_menu")
	)

func _process(_delta):
	for c in M.connected_players_list.get_children():
		c.queue_free()
		c.get_parent().remove_child(c)
	
	for player in Global.main.get_players():
		var l = Label.new()
		l.text = "[" + player.name + "] " + player.player_name
		M.connected_players_list.add_child(l)
	
	if Global.eos.is_offline():
		Global.eos.logout()
		Global.main.unload_all()
		Global.main.load_menu("main_menu")
