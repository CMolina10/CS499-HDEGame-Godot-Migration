# character creation scene in Blombos Cave

extends Node2D

@export var next_scene: PackedScene
@export var Elcitrap: PackedScene

@export var hair_count = 12
@export var body_count = 4
@export var clothes_count = 5

signal trigger_animation(anim_name)

var hair_num = 0
var body_num = 0
var clothes_num = 0

var players_ready = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#$AnimationPlayer.play("Zoom")
	#emit_signal("trigger_animation", "Screen_Unwipe") 
	
	# populate elcitraps with data from previous scene
	for i in range(len(gamestate.elcitraps[multiplayer.get_unique_id()])):
		var elcitrap = Elcitrap.instantiate()
		add_child(elcitrap)
		elcitrap.position = Vector2(60, 60*i + 200)
		elcitrap.init((gamestate.elcitraps[multiplayer.get_unique_id()])[i])
		
	MusicController.playMusic(ReferenceManager.get_reference("cave.ogg"))

func mod(num, maximum):
	if num < 0:
		return maximum-1
	elif num > maximum-1:
		return 0
	else:
		return num

func _on_hair_left_pressed() -> void:
	hair_num = mod(hair_num - 1, hair_count)
	$front_hair.set_texture(load(ReferenceManager.get_reference("front_hair/" + str(hair_num) + ".png")))
	$back_hair.set_texture(load(ReferenceManager.get_reference("back_hair/" + str(hair_num) + ".png")))

func _on_hair_right_pressed() -> void:
	hair_num = mod(hair_num + 1, hair_count)
	$front_hair.set_texture(load(ReferenceManager.get_reference("front_hair/" + str(hair_num) + ".png")))
	$back_hair.set_texture(load(ReferenceManager.get_reference("back_hair/" + str(hair_num) + ".png")))

func _on_body_left_pressed() -> void:
	body_num = mod(body_num - 1, body_count)
	$body.set_texture(load(ReferenceManager.get_reference("bodies/" + str(body_num) + ".png")))

func _on_body_right_pressed() -> void:
	body_num = mod(body_num + 1, body_count)
	$body.set_texture(load(ReferenceManager.get_reference("bodies/" + str(body_num) + ".png")))
	
func _on_clothes_left_pressed() -> void:
	clothes_num = mod(clothes_num - 1, clothes_count)
	$clothes.set_texture(load(ReferenceManager.get_reference("clothes/" + str(clothes_num) + ".png")))

func _on_clothes_right_pressed() -> void:
	clothes_num = mod(clothes_num + 1, clothes_count)
	$clothes.set_texture(load(ReferenceManager.get_reference("clothes/" + str(clothes_num) + ".png")))

# wait for everyone to have pressed next to continue to next scene
func _on_next_pressed() -> void:
	rpc("set_features", hair_num, body_num, clothes_num)
	
	if not multiplayer.is_server():
		# Tell server we are ready to start.
		rpc_id(1, "ready_to_start", multiplayer.get_unique_id())
	else:
		ready_to_start(multiplayer.get_unique_id())

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	$ZIndexSetter/ColorRect.visible = !$ZIndexSetter/ColorRect.visible 

# set character features for player on every player's screen
@rpc("any_peer", "call_local") func set_features(hair, body, clothes):
	gamestate.hair[multiplayer.get_remote_sender_id()] = hair
	gamestate.body[multiplayer.get_remote_sender_id()] = body
	gamestate.clothes[multiplayer.get_remote_sender_id()] = clothes
	
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
