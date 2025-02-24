# elcitrap selection scene

extends Node

@export var Elcitrap: PackedScene
@export var next_scene: PackedScene

@export var trait_queue = [] + curriculum.traits

signal trigger_animation(anim_name)
signal five_selected()

# x, y positions of each elcitrap
var red_pos = [[361, 121], [321, 163], [294, 214], [278, 272], [284, 333]]
var blue_pos = [[398, 500], [454, 519], [514, 528], [574, 519], [628, 499]]
var green_pos = [[663, 124], [700, 169], [726, 219], [738, 274], [736, 333]]

@export var selected = []

var players_ready = []

var narration_text = ["You can see clearly now the choices before you.",
"Click on these elcitraps to make them part of your identity.",
"You can be whoever you want to be, all you have to do is choose."]
var narration_count = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var r_i = 0
	var b_i = 0
	var g_i = 0
	
	# populate elcitraps on screen
	for i in range(len(trait_queue)):
		var elcitrap = Elcitrap.instantiate()
		
		# red particles
		if i % 3 == 0:
			elcitrap.position = Vector2(red_pos[r_i][0], red_pos[r_i][1])
			r_i += 1
			
		# blue particles
		elif i % 3 == 1:
			elcitrap.position = Vector2(blue_pos[b_i][0], blue_pos[b_i][1])
			b_i += 1
			
		# green particles
		elif i % 3 == 2:
			elcitrap.position = Vector2(green_pos[g_i][0], green_pos[g_i][1])
			g_i += 1
		
		elcitrap.init(trait_queue[i], elcitrap.position)
		
		add_child(elcitrap)
		
	$Narration.text = narration_text[0]
	$Narration/TextAnimationPlayer.play("Reveal", -1, 2)

# reveal next button after player has selected 5 traits
func _process(delta: float) -> void:
	if len(selected) == 5:
		emit_signal("five_selected")

# tell host we're done when next is clicked
func _on_Button_pressed() -> void:
#	print("id", get_tree().get_network_unique_id())
	rpc("set_elcitraps", selected)
#	print("debug: ", gamestate.elcitraps)

	$Button.visible = false
	$Narration.visible = false
	
	emit_signal("trigger_animation", "Fade")
	
@rpc("any_peer", "call_local") func set_elcitraps(elcitraps):
	gamestate.elcitraps[multiplayer.get_remote_sender_id()] = elcitraps
	
@rpc("any_peer") func start_game():
	get_parent().change_level(next_scene)

func _on_TextAnimationPlayer_animation_finished(anim_name: String) -> void:
	if narration_count < len(narration_text):
		$Narration.text = narration_text[narration_count]
		$Narration/TextAnimationPlayer.play("Reveal")
		narration_count += 1

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if (anim_name == "Fade"):
		$ZIndexSetter/ColorRect.visible = !$ZIndexSetter/ColorRect.visible
		emit_signal("trigger_animation", "Screen_Wipe")
	else:
		start_game()
