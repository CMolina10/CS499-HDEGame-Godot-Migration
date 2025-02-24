# quantum realm scene where player captures wavy elcitraps

extends Node

# Declare member variables here. Examples:
@export var Elcitrap: PackedScene
@export var next_scene: PackedScene
@export var total_captured = 0

@export var trait_queue = [] + curriculum.traits

var players_ready = []

var dialogue = ["You now have the power to shape your future.",
"Now, use your Oauabae to help you see through the chaos!"]
var page = 0

@onready var dialogue_label = $DialogueBox/DialogueText  # Assumes dialogue is a RichTextLabel node
@onready var timer = $DialogueBox/Timer  # Assumes there's a Timer node for text animation

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(15):
		trait_queue[i].append([i*60 + 100, 550])
		
	randomize()
	new_game()

func new_game():
	dialogue_label.text = dialogue[page]
	dialogue_label.set_visible_characters(0)
	timer.start()  # Start text reveal effect
	play_audio(page)  # Play first dialogue's audio    
	
	MusicController.playMusic(ReferenceManager.get_reference("quantum.ogg"))

# source: https://docs.godotengine.org/en/3.2/getting_started/step_by_step/your_first_game.html#enemy-scene
#func _on_StartTimer_timeout():
#	print("start timer end")
	#$ElcitrapTimer.start()
#	print("e timer start")

func _on_ElcitrapTimer_timeout():
	# if there are still uncaptured elcitraps, release one from edge of screen
	if len(trait_queue) > 0:
		
		# Choose a random location on Path2D.
		$EPath/EPathFollow.progress = randi()
		
		# Create a Mob instance and add it to the scene.
		var elcitrap = Elcitrap.instantiate()
		elcitrap.init(trait_queue[0])
		trait_queue.pop_front()
		add_child(elcitrap)
		
		# Set the mob's direction perpendicular to the path direction.
		var direction = $EPath/EPathFollow.rotation + PI / 2
		
		# Set the mob's position to a random location.
		elcitrap.position = $EPath/EPathFollow.position
		
		# Add some randomness to the direction/rotation.
		direction += randf_range(-PI / 4, PI / 4)
		elcitrap.rotation = direction
		
		# Set the velocity (speed & direction).
		elcitrap.linear_velocity = Vector2(randf_range(elcitrap.min_speed, elcitrap.max_speed), 0)
		elcitrap.linear_velocity = elcitrap.linear_velocity.rotated(direction)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if total_captured == 15:
		$EndTimer.start()
		total_captured = 16
		
func _on_EndTimer_timeout() -> void:
#	print('end timer end')
	
	if not multiplayer.is_server():
		# Tell server we are ready to start.
		rpc_id(1, "ready_to_start", multiplayer.get_unique_id())
	else:
		ready_to_start(multiplayer.get_unique_id())
	
@rpc("any_peer", "call_local") func set_elcitraps(elcitraps):
	gamestate.elcitraps[multiplayer.get_remote_sender_id()] = elcitraps
	
@rpc("any_peer") func start_game():
	get_parent().change_level(next_scene)

@rpc("any_peer") func ready_to_start(id):
	assert(multiplayer.is_server())

	if not id in players_ready:
		players_ready.append(id)

	if players_ready.size() == gamestate.players.size():
		for p in gamestate.players:
			rpc_id(p, "start_game")
		start_game()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if dialogue_label.get_visible_characters() >= dialogue_label.get_total_character_count():
			if page < dialogue.size() - 1:
				page += 1
				dialogue_label.text = dialogue[page]
				dialogue_label.set_visible_characters(0)
				timer.start()  # Restart text reveal effect
				play_audio(page)  # Play next dialogue's audio
			else:
				$ElcitrapTimer.start()
				$DialogueBox.hide()


func play_audio(page_index):
	# Stop all audio players
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()

	# Play the corresponding audio
	var audio_node_name = "AudioStreamPlayer" + str(page_index+1)
	var current_player = get_node(audio_node_name)
	if current_player:
		current_player.play()
	else:
		print("Audio node not found: ", audio_node_name)

func _on_Timer_timeout():
	dialogue_label.set_visible_characters(dialogue_label.get_visible_characters() + 1)
	if dialogue_label.get_visible_characters() >= dialogue_label.get_total_character_count():
		timer.stop()  # Stop timer when all text is revealed
