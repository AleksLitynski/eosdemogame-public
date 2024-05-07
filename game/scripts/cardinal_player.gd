class_name CardinalPlayer
extends CharacterBody3D

var logger = Logger.add_module("cardinal_player")

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var hp: int = 100
@export var max_hp: int = 100
@export var xp: int = 0
@export var next_level_xp: int = 100


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var collision_area = $DetectorZone
@onready var autofire_test_weapon = preload("res://scenes/player/weapons/autotarget_weapon.tscn")
@onready var stages = get_tree().get_nodes_in_group('stages')

var weapons = []
var enemy_distances = []
var closest_enemy
var current_stage

var owning_player: Player
@export var owner_id: int:
	set(id):
		logger.info(name + " set owner id to " + str(id))
		owner_id = id
		owning_player = Global.main.get_player_by_id(owner_id)
		$player_name.text = owning_player.player_name
		$Camera3D.current = locally_owned()
		$Camera3D.visible = locally_owned()
		owning_player.character = self

func locally_owned():
	return owner_id == Global.eos.peer.get_unique_id()

func _process(_delta):
	if get_multiplayer_authority() != owner_id:
		set_multiplayer_authority(owner_id)
	
	if Engine.get_process_frames() % 6:
		calc_enemy_distances()
	
	if owning_player.is_local_player():
		for enemy in Global.main.M.enemies.get_children():
			enemy.set_message("")
		if closest_enemy && is_instance_valid(closest_enemy):
			closest_enemy.set_message("closest")
	
	if Global.eos.is_server():
		check_for_damage()


func _ready():
	if process_mode != Node.PROCESS_MODE_DISABLED:
		logger.info("cardinal player ready " + name)
		var test_wep = autofire_test_weapon.instantiate()
		equip_weapon(test_wep)
	determine_stage()

func equip_weapon(new_weapon: BaseWeapon):
	print("equipped new weapon")
	weapons.append(new_weapon)
	add_child(new_weapon)
	new_weapon.controlling_player = self


func determine_stage():
	for stage in stages:
		for player in stage.get_tree().get_nodes_in_group('players'):
			if player == self:
				current_stage = stage


func calc_enemy_distances():
	if not current_stage:
		return
	var closest = 9223372036854775807
	enemy_distances.clear()
	for enemy in current_stage.get_tree().get_nodes_in_group('enemies'):
		var dist = self.global_position.distance_to(enemy.global_position)
		if dist < closest:
			closest = dist
			closest_enemy = enemy
		enemy_distances.append(dist)

func _physics_process(delta):
	if !locally_owned(): return
	
	if not is_on_floor() && hp > 0:
		velocity.y -= gravity * delta

	# Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
		
	if Input.is_action_pressed('weapon_action'):
		print('upgrading')
		weapons[0].upgrade()

	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if hp > 0:
		move_and_slide()
		

@rpc("any_peer", "call_local", "unreliable")
func set_is_dead(dead = true):
	if multiplayer.get_remote_sender_id() != 1: return # only server can set dead
	$CollisionShape3D.disabled = dead
	$DetectorZone.monitoring = !dead
	$DetectorZone.monitorable = !dead
	if dead:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.ORANGE_RED
		mat.albedo_color.a = 0.1
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		$Pivot/dummy_model/coin.set_surface_override_material(0, mat)
		$player_name.text = "X " + owning_player.player_name + " X"
	else:
		$Pivot/dummy_model/coin.set_surface_override_material(0, null)

func is_dead():
	return hp <= 0

#func _on_detector_zone_area_entered(area):
	#if area.get_parent().is_in_group("enemies"):
		#flash.rpc(Color.RED)

var invulnerable = false
func check_for_damage():
	if invulnerable || is_dead(): return

	# take damage
	var all_enemies = $DetectorZone.get_overlapping_areas().filter(func(e): return e.get_parent().is_in_group("enemies"))
	if all_enemies.size() == 0: return
	var selected_enemy = all_enemies.pick_random()
	if selected_enemy:
		take_damage(selected_enemy)
	
	# set invuln timer
	invulnerable = true
	get_tree().create_timer(0.25).timeout.connect(func():
		invulnerable = false
	)

@rpc("any_peer", "call_remote", "unreliable")
func update_stats_from_server(hp, max_hp, xp, next_level_xp):
	# the server can tell us to update the player's stats
	if multiplayer.get_remote_sender_id() == 1:
		self.hp = hp
		self.max_hp = max_hp
		self.xp = xp
		self.next_level_xp = next_level_xp

func take_damage(enemy):
	flash.rpc(Color.RED)
	hp -= 10
	update_stats_from_server.rpc(hp, max_hp, xp, next_level_xp)
	if is_dead():
		set_is_dead.rpc(true)

@rpc("any_peer", "call_local", "unreliable")
func flash(color: Color):
	if is_dead(): return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	var old_map = $Pivot/dummy_model/coin.get_surface_override_material(0)
	$Pivot/dummy_model/coin.set_surface_override_material(0, mat)
	get_tree().create_timer(0.2).timeout.connect(func():
		if is_dead(): return
		$Pivot/dummy_model/coin.set_surface_override_material(0, old_map)
	)
