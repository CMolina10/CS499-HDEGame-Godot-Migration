# lobby scene where players enter the game
class_name Lobby
extends Control

func _ready():
	# Called every time the node is added to the scene.
	gamestate.connect("connection_failed", Callable(self, "_on_connection_failed"))
	gamestate.connect("connection_succeeded", Callable(self, "_on_connection_success"))
	gamestate.connect("player_list_changed", Callable(self, "refresh_lobby"))
	gamestate.connect("game_ended", Callable(self, "_on_game_ended"))
	gamestate.connect("game_error", Callable(self, "_on_game_error"))
	SaveManager.connect("load_save_scene", Callable(self, "handle_level"))
	# Set the player name according to the system username. Fallback to the path.
	if OS.has_environment("USERNAME"):
		set_name_text(OS.get_environment("USERNAME"))
	else:
		var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
		set_name_text(desktop_path[desktop_path.size() - 2])

#test commit push
	
	$LoadButton.visible = false
	
	var ips = IP.get_local_addresses()
	print(ips)

	# set IP to any of the user's valid IP addresses
	for ip in ips:
		if ip.begins_with("192.168") or ip.begins_with("10") or ip.begins_with("172"):
			$Connect/JoinBox/IPAddress.text = ip
			break


func _on_host_pressed():
	if get_name_text() == "":
		set_error_text("Invalid name!")
		return

	$Connect.hide()
	$TitleBox/Title.visible = false
	$LevelSelect/Popup.visible = false
	$LoadButton.visible = true
	set_error_text("")
	#$Players/FindPublicIP.text = "IP: " + $Connect/JoinBox/IPAddress.text
	$Players/FindPublicIP.text = "Host: " + $Connect/StartBox/Name.text

func _on_join_pressed():
	if get_name_text() == "":
		set_error_text("Invalid name!")
		return
	
	#var ip =  $Connect/JoinBox/IPAddress.text
	#if not ip.is_valid_ip_address():
		#set_error_text("Invalid IP Address")
		#return
		
	#get host name
	var host_name = $Connect/JoinBox/IPAddress.text
	if host_name == $Connect/StartBox/Name.text:
		set_error_text("Host and player can not have the same name.")
		return

	set_error_text("")
	$Connect/StartBox/Host.disabled = true
	$Connect/JoinBox/Join.disabled = true

	var player_name = get_name_text()
	#$Players/FindPublicIP.text = "IP: " + $Connect/IPAddress.text
	$Players/FindPublicIP.text = "Host: " + host_name

	#gamestate.join_game(ip, player_name)
	gamestate.join_game(host_name, player_name)

func _on_connection_success():
	$Connect.hide()
	$Players.show()


func _on_connection_failed():
	$Connect/StartBox/Host.disabled = false
	$Connect/JoinBox/Join.disabled = false
	$Connect/ErrorLabel.set_text("Connection failed.")


func _on_game_ended():
	show()
	$Connect.show()
	$Players.hide()
	$Connect/StartBox/Host.disabled = false
	$Connect/JoinBox/Join.disabled = false


func _on_game_error(errtxt):
	$ErrorDialog.dialog_text = errtxt
	$ErrorDialog.popup_centered_clamped()
	$Connect/StartBox/Host.disabled = false
	$Connect/JoinBox/Join.disabled = false


func refresh_lobby():
	var players = gamestate.get_player_list()
	players.sort()
	$Players/List.clear()
	for p in players:
		$Players/List.add_item(p)

	$Players/Start.disabled = not get_tree().is_server()


func _on_start_pressed():
	gamestate.begin_game()


func _on_find_public_ip_pressed():
	OS.shell_open("https://icanhazip.com/")


# handle which level to begin at / randomize dominos
func handle_level(level):
	gamestate.first_level = level

	for top in range(10):
		for bottom in range(top + 1):
			gamestate.dominos.append([bottom, top])

	randomize()
	gamestate.random_seed = randi() % 10000000
	seed(gamestate.random_seed)

	gamestate.dominos.shuffle()
	$LoadButton.visible = false
	$LevelSelect/Popup.visible = true
	$Players.show()
	$TitleBox/Title.visible = true
	var player_name = $Connect/StartBox/Name.text
	gamestate.host_game(player_name)
	refresh_lobby()


func _on_Level1_pressed() -> void:
	handle_level("Agency")


func _on_Level2_pressed() -> void:
	handle_level("Pond")


func _on_Level3_pressed() -> void:
	handle_level("DominoWorld")


func _on_Level4_pressed():
	handle_level("Sandbox")


func set_name_text(new_name: String) -> void:
	$Connect/StartBox/Name.text = new_name


func get_name_text() -> String:
	return $Connect/StartBox/Name.text


func set_error_text(new_error: String):
	$Connect/ErrorLabel.set_text(new_error)
