class_name Stage
extends Node

var logger = Logger.add_module("stage")

var rng = RandomNumberGenerator.new()

func _ready():
	logger.info("stage created")
	Global.main.load_menu("in_game_ui")
	
	if Global.eos.is_server():
		do_enemy_waves()

func do_enemy_waves():
	while true:
		await get_tree().create_timer(rng.randf_range(0, 3)).timeout
		
		var enemy = preload("res://scenes/enemy/follower_enemy.tscn").instantiate()
		enemy.name = "enemy_0"
		Global.main.M.enemies.add_child(enemy, true)
		
		var chars 
		var target_player = Global.main.get_random_living_character()
		if target_player:
			enemy.global_position = target_player.global_position
		enemy.global_position.x += rng.randf_range(-5, 5)
		enemy.global_position.z += rng.randf_range(-5, 5)
		enemy.global_position.y = 1

func _process(_delta):
	if Global.main.get_characters().filter(func(c): return !c.is_dead()).size() <= 0:
		Global.main.get_menu().show_game_over()
