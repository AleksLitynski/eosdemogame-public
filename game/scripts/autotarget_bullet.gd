extends CharacterBody3D

var target
var target_dir
var damage
@onready var speed = 1.5
@onready var max_enemies_hit = 1


# Called when the node enters the scene tree for the first time.

var rng = RandomNumberGenerator.new()
func begin_moving():
	if target && is_instance_valid(target):
		velocity = global_position.direction_to(target.global_position).normalized() * speed
	else:
		velocity = Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)) * speed
	velocity.y = 0

func _ready():
	await get_tree().create_timer(15).timeout
	despawn()


func _physics_process(delta):
	if Global.eos.is_server():
		move_and_slide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func despawn():
	queue_free()
	await get_tree().process_frame
	if get_parent(): get_parent().remove_child(self)
	

func _on_detector_zone_area_entered(area):
	if Global.eos.is_client(): return
	if area.get_parent().is_in_group('enemies'):
		area.get_parent().take_damage(damage)
		despawn()
	elif area.get_parent().is_in_group('players'):
		pass
	#for idx in range(get_slide_collision_count()):
		#print('collided')
		#var collision = get_slide_collision(idx)
		#if collision.get_collider() == null:
			#continue
		#if collision.get_collider().is_in_group("enemies"):
			#print('hit an enemy')
