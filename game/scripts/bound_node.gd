class_name BoundNode
extends Node

static var bui_logger = Logger.add_module("bound_ui")

@export var M: Dictionary = {}

# override in child class
func on_bound(): pass

func _ready():
	rebuild_ui_bindings()

func rebuild_ui_bindings(binding_root: Node = self, clear_bindings: bool = true):
	if clear_bindings:
		M = {}
	for child in binding_root.get_children():
		if child.name.begins_with("__"):
			M[child.name.substr(2)] = child
		rebuild_ui_bindings(child, false)
	if binding_root == self:
		on_bound()
