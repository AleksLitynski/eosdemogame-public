class_name Main
extends BoundNode

var logger = Logger.add_module("main")

var local_user_id: String = ""
var desired_display_name: String = ""

func on_bound():
	M.autoloading_warning.visible = false
	load_menu("main_menu")
	if DevSettings.settings.level_autoload:
		M.autoloading_warning.visible = true
		await M.current_menu.get_children()[0].do_login()
		Global.eos.create_server()
		Global.main.load_stage("stage_1")
		M.autoloading_warning.visible = false
	
func _enter_tree():
	Global.main = self

@onready var TRIANGLE_SHIP = "res://assets/entities/triangle.png"
@onready var DIAMOND_SHIP = "res://assets/entities/diamond.png"

func load_stage(stage_name: String):
	unload_stage()
	M.current_stage.add_child(load("res://scenes/stage/" + stage_name + ".tscn").instantiate())
	
	var players = get_players()
	for player_idx in len(players):
		players[player_idx].on_stage_loaded(player_idx)

func load_menu(menu_name: String):
	for child in M.current_menu.get_children():
		child.queue_free()
		child.get_parent().remove_child(child)
	M.current_menu.add_child(load("res://scenes/menus/" + menu_name + ".tscn").instantiate())

func unload_stage():
	for child in M.current_stage.get_children():
		child.queue_free()
		child.get_parent().remove_child(child)
	for child in M.characters.get_children():
		child.queue_free()
		child.get_parent().remove_child(child)
	for child in M.bullets.get_children():
		child.queue_free()
		child.get_parent().remove_child(child)
	for child in M.enemies.get_children():
		child.queue_free()
		child.get_parent().remove_child(child)
		
func unload_all():
	unload_stage()
	for child in M.players.get_children():
		child.queue_free()
		child.get_parent().remove_child(child)



func get_players():
	return M.players.get_children()
func get_characters():
	return M.characters.get_children()

func get_living_characters():
	return get_characters().filter(func(c): return !c.is_dead())

func get_random_living_character():
	var living_characters = Global.main.get_living_characters()
	if living_characters.size() <= 0: return null
	return living_characters.pick_random()

func get_player_by_id(id: int):
	for player in get_players():
		if player.owner_id == id:
			return player
			
func local_player():
	return get_player_by_id(Global.eos.peer.get_unique_id())

func get_menu():
	return M.current_menu.get_children()[0]
	
func get_stage():
	return M.current_stage.get_children()[0]

func _process(_delta):
	M.peers.text = "Peers:"
	for peer in Global.eos.peer.get_all_peers():
		M.peers.text += "\n    " + str(peer)
		
