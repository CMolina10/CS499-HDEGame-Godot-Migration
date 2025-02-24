# manager node that handles which level is shown

extends Node2D

var current_level = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if gamestate.get_tutorial_mode():
		current_level = load(ReferenceManager.get_reference(gamestate.first_level + "Tutorial.tscn")).instantiate()
	else:
		current_level = load(ReferenceManager.get_reference(gamestate.first_level + ".tscn")).instantiate()
	
	add_child(current_level)
	
func change_level(next_scene):
	current_level.queue_free()
	current_level = next_scene.instantiate()
	add_child(current_level)
