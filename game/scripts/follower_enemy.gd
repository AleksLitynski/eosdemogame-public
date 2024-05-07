extends Enemy

const DEFAULT_SPEED = 1.5
const DEFAULT_HEALTH = 6
@export var hp: int


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var player_target


func _ready():
	hp = DEFAULT_HEALTH

func _physics_process(delta):
	if Global.eos.is_client(): return
	
	if player_target && is_instance_valid(player_target) && !player_target.is_dead():
		# move_speed = director.follower_speed_multiplier * DEFAULT_SPEED
		var move_speed = DEFAULT_SPEED
		var to_player = global_position.direction_to(player_target.global_position).normalized()
		velocity.x = to_player.x
		velocity.z = to_player.z
		if global_position.distance_to(player_target.global_position) > 0.2:
			move_and_collide(to_player * move_speed * delta)
	
	else:
		player_target = Global.main.get_random_living_character()
		
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	#move_and_collide(velocity * SPEED * delta)


func take_damage(dmg):
	flash.rpc(Color.RED)
	hp -= dmg
	if hp <= 0:
		die()

@rpc("authority", "call_local", "unreliable")
func flash(color: Color):
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	var old_mat_0 = $Pivot/machine_barrelLarge2/tmpParent/machine_barrelLarge.get_surface_override_material(0)
	var old_mat_1 = $Pivot/machine_barrelLarge2/tmpParent/machine_barrelLarge.get_surface_override_material(1)
	var old_mat_2 = $Pivot/machine_barrelLarge2/tmpParent/machine_barrelLarge.get_surface_override_material(2)
	var old_mat_3 = $Pivot/machine_barrelLarge2/tmpParent/machine_barrelLarge.get_surface_override_material(3)
	$Pivot/machine_barrelLarge2/tmpParent/machine_barrelLarge.set_surface_override_material(0, mat)
	$Pivot/machine_barrelLarge2/tmpParent/machine_barrelLarge.set_surface_override_material(1, mat)
	$Pivot/machine_barrelLarge2/tmpParent/machine_barrelLarge.set_surface_override_material(2, mat)
	$Pivot/machine_barrelLarge2/tmpParent/machine_barrelLarge.set_surface_override_material(3, mat)
	get_tree().create_timer(0.2).timeout.connect(func():
		$Pivot/machine_barrelLarge2/tmpParent/machine_barrelLarge.set_surface_override_material(0, old_mat_0)
		$Pivot/machine_barrelLarge2/tmpParent/machine_barrelLarge.set_surface_override_material(1, old_mat_1)
		$Pivot/machine_barrelLarge2/tmpParent/machine_barrelLarge.set_surface_override_material(2, old_mat_2)
		$Pivot/machine_barrelLarge2/tmpParent/machine_barrelLarge.set_surface_override_material(3, old_mat_3)
	)

func set_message(msg: String):
	$Label.text = msg

func die():
	# explosion effect?
	# sound effect
	get_parent().remove_child(self)
	queue_free()
