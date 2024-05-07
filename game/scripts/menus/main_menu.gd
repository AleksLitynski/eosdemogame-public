extends BoundNode
class_name MainMenu

var logger = Logger.add_module("main_menu")


func use_dev_account():
	return M.use_dev_account.button_pressed

func do_login():
	Global.main.desired_display_name = M.display_name.text
	var client_data: Dictionary = {}
	if use_dev_account():
		client_data = await Global.eos.do_developer_login()
	else:
		client_data = await Global.eos.do_device_login(M.display_name.text)
		
	if client_data.has("local_user_id"):
		Global.main.local_user_id = client_data.local_user_id

func on_bound():
	M.display_name.text = ["Sir Donotshmove", "warlord", "digtal nightmare", "hackintosh", "jim", "keydowner", "caterpiller", "l33t feller", "cruncle sam", "diabetes destroyer", "slimeball jr", "slimeball sr", "ham solo", "godette", "godot", "silky-smooth_gamer", "xxX_UrMom_Xxx_69"].pick_random()
	M.start_new_game.pressed.connect(func():
		await do_login()
		if Global.main.local_user_id != null:
			Global.eos.create_server()
			Global.main.load_menu("lobby_menu")
	)
	
	M.join_game.pressed.connect(func():
		await do_login()
		if Global.main.local_user_id != null:
			Global.main.load_menu("join_game_menu")
	)
