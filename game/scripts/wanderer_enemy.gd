extends Enemy

const SPEED = 5.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
