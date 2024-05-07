extends BaseWeapon


var DEFAULT_UPGRADES = {
	0: func(): pass,
	1: func():
		fire_rate_buff -= 1,
	2: func():
		rounds_per_shot_buff += 1,
	3: func():
		bullet_speed_buff += 1
		round_fire_rate_buff -= .2,
	4: func():
		fire_rate_buff -= 1
		damage_buff += 1,
	5: func():
		rounds_per_shot_multiplier += 1,
	6: func():
		fire_rate_multiplier += 1,
	7: func():
		round_fire_rate_buff = .2
}

var level = 0
const MAX_LEVEL = 7
var logger = Logger.add_module("base_weapon")
var DEFAULT_FIRE_RATE = 4.0 #in seconds? seems simple
var DEFAULT_ROUNDS_PER_SHOT = 1.0
var DEFAULT_ROUND_FIRE_RATE = .5
var DEFAULT_BULLET_SIZE = 1.0
var DEFAULT_BULLET_SPEED = 1.0
var DEFAULT_TARGETING_PATTERN = TargetingPattern.NEAREST_ENEMY

var DEFAULT_DAMAGE = 2

var real_damage
var damage_buff = 0
var damage_multiplier = 1

var gun_state = FireState.RELOADING

var real_target

var real_fire_rate
var fire_rate_buff = 0
var fire_rate_multiplier = 1

var real_rounds_per_shot
var rounds_per_shot_buff = 0
var rounds_per_shot_multiplier = 1

var real_round_fire_rate
var round_fire_rate_buff = 0
var round_fire_rate_multiplier = 1

var real_bullet_size
var bullet_size_buff = 0
var bullet_size_multipler = 1

var real_bullet_speed
var bullet_speed_buff = 0
var bullet_speed_multipler = 1

@onready var bullet = preload("res://scenes/player/bullets/autotarget_bullet.tscn")
@onready var stages = get_tree().get_nodes_in_group('stages')
var controlling_player


func _ready():
	logger.info('autofire ready!')
	calc_properties()
	if Global.eos.is_server():
		start_gun_loop()


func start_gun_loop():
	while true:
		await get_tree().create_timer(real_fire_rate).timeout
		fire()


func fire():
	if controlling_player.is_dead():
		return
	gun_state = FireState.FIRING
	#logger.info('firing')
	for a in range(real_rounds_per_shot):
		await get_tree().create_timer(real_round_fire_rate).timeout
		fire_round(a)
	gun_state = FireState.RELOADING


func upgrade():
	clear_buffs()
	level += 1
	recalc_weapon_stats()
	fire()

func set_gun_level(to_level):
	if to_level > 0:
		if to_level > MAX_LEVEL:
			to_level = MAX_LEVEL
		clear_buffs()
		level = to_level


func clear_buffs():
	fire_rate_buff = 0
	fire_rate_multiplier = 1
	rounds_per_shot_buff = 0
	rounds_per_shot_multiplier = 1
	round_fire_rate_buff = 0
	round_fire_rate_multiplier = 1
	bullet_size_buff = 0
	bullet_size_multipler = 1
	bullet_speed_buff = 0
	bullet_speed_multipler = 1


func recalc_weapon_stats():
	var next_level = min(level + 1, MAX_LEVEL)
	for a in range(next_level):
		DEFAULT_UPGRADES[a].call()


func fire_round(_a):
	if Global.eos.is_client(): return
	
	logger.info('firing a bullet')
	var new_bullet = bullet.instantiate()
	if controlling_player.current_stage:
		new_bullet.target = real_target
		new_bullet.damage = real_damage
		new_bullet.name = "bullet_0"
		#print(controlling_player.global_position)
		Global.main.M.bullets.add_child(new_bullet, true)
		new_bullet.global_position = controlling_player.global_position
		new_bullet.begin_moving()
		new_bullet.global_position.y = .5
		#print(new_bullet.global_position)
	pass


func calc_properties():
	real_damage = (DEFAULT_DAMAGE + damage_buff) * damage_multiplier
	real_fire_rate = (DEFAULT_FIRE_RATE + fire_rate_buff) * fire_rate_multiplier
	real_rounds_per_shot = (DEFAULT_ROUNDS_PER_SHOT + rounds_per_shot_buff) * rounds_per_shot_multiplier
	real_round_fire_rate = (DEFAULT_ROUND_FIRE_RATE + round_fire_rate_buff) * round_fire_rate_multiplier
	real_bullet_size = (DEFAULT_BULLET_SIZE + bullet_size_buff) * bullet_size_multipler
	real_bullet_speed = (DEFAULT_BULLET_SPEED + bullet_speed_buff) * bullet_speed_multipler
	pass


func dist_to_first_enemy():
	var stage_to_find_targets_in = null
	#for stage in stages:
		#for player in stage.get_tree().get_nodes_in_group('players'):
			#if player == controlling_player:
				#stage_to_find_targets_in = stage
	if not controlling_player.current_stage:
		return
	var first_enemy = controlling_player.current_stage.get_tree().get_nodes_in_group('enemies')[0]
	logger.info(controlling_player.position.distance_to(first_enemy.position))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Engine.get_process_frames() % 4:
		calc_properties()
		if controlling_player.closest_enemy:
			real_target = controlling_player.closest_enemy
	
