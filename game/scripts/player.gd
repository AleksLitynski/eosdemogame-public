class_name Player
extends Node

var logger = Logger.add_module("player")

@export var player_name: String = ""
@export var owner_id: int
@export var character: CardinalPlayer

func _ready():
	if owner_id == multiplayer.get_unique_id():
		# ask the server to set our name to whatever
		set_player_name.rpc_id(1, Global.main.desired_display_name)

@rpc("any_peer", "call_local", "unreliable")
func set_player_name(new_name: String):
	if multiplayer.get_remote_sender_id() == owner_id:
		logger.info("set_player_name called " + new_name)
		player_name = new_name

func on_stage_loaded(idx):
	# when the game loads, server will instruct everyone to spawn a player
	# based on the owner, players will control their own character
	if !Global.eos.is_server(): return
	
	var c = preload("res://scenes/player/cardinal_player.tscn").instantiate()
	c.name = player_name + "_character"
	c.position = Vector3(1 * idx, 2, 0)
	c.owner_id = owner_id
	
	Global.main.M.characters.add_child(c, true)

func is_local_player():
	return owner_id == Global.eos.peer.get_unique_id()
