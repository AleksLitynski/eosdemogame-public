extends BoundNode
class_name JoinGameMenu
var logger = Logger.add_module("join_game")

func on_bound():
	M.join_game.pressed.connect(func():
		var res = Global.eos.connect_client(M.host_id.text)
		if res == OK:
			M.connecting.visible = true
			M.join_buttons.visible = false
			await Global.eos.client__host_joined
			Global.main.load_menu("lobby_menu")
	)
	
	M.back.pressed.connect(func():
		Global.eos.logout()
		Global.main.load_menu("main_menu")
	)

func _process(_delta):
	M.join_game.disabled = len(M.host_id.text) == 0
	
