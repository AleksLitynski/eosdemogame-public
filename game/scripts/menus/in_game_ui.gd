extends BoundNode
class_name InGameUi
var logger = Logger.add_module("in_game_ui")

var local_player
func on_bound():
	M.game_over_region.visible = false
	M.quit_to_title.pressed.connect(func():
		# log out and stop server
		Global.eos.logout()
		Global.main.unload_all()
		Global.main.load_menu("main_menu")
	)
	
func _process(_delta):
	if !local_player || !is_instance_valid(local_player):
		local_player = Global.main.local_player()
	else:
		M.username.text = local_player.player_name
		if local_player.character && is_instance_valid(local_player.character):
			M.health.value = local_player.character.hp
			M.health.max_value = local_player.character.max_hp
			M.experience.value = local_player.character.xp
			M.experience.max_value = local_player.character.next_level_xp

	if Global.eos.is_offline():
		Global.eos.logout()
		Global.main.unload_all()
		Global.main.load_menu("main_menu")


func show_game_over():
	if M.game_over_region.visible: return
	
	M.game_over_region.visible = true
	M.restart_button.disabled = Global.eos.is_client()
	M.restart_button.pressed.connect(func():
		Global.main.load_stage("stage_1")
	, CONNECT_ONE_SHOT)
