extends Node
class_name BaseWeapon

enum TargetingPattern {
	AIMED,
	NEAREST_ENEMY,
	RANDOM_ENEMY,
	RANDOM
}

enum FireState {
	RELOADING,
	FIRING
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
