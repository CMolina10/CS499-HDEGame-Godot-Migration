# This class provides a runner for scense to simulate interactions like keyboard or mouse
class_name GdUnitSceneRunnerImpl
extends GdUnitSceneRunner

# mapping of mouse buttons and his masks
const MAP_MOUSE_BUTTON_MASKS := {
	MOUSE_BUTTON_LEFT : MOUSE_BUTTON_MASK_LEFT,
	MOUSE_BUTTON_RIGHT : MOUSE_BUTTON_MASK_RIGHT,
	MOUSE_BUTTON_MIDDLE : MOUSE_BUTTON_MASK_MIDDLE,
	MOUSE_BUTTON_WHEEL_UP : 8,
	MOUSE_BUTTON_WHEEL_DOWN : 16,
	MOUSE_BUTTON_XBUTTON1 : MOUSE_BUTTON_MASK_XBUTTON1,
	MOUSE_BUTTON_XBUTTON2 : MOUSE_BUTTON_MASK_XBUTTON2,
}

var _test_suite :WeakRef
var _scene_tree :SceneTree = null
var _current_scene :Node = null
var _verbose :bool
var _simulate_start_time :LocalTime
var _last_input_event :InputEvent = null
var _mouse_button_on_press := []
var _key_on_press := []

# time factor settings
var _time_factor := 1.0
var _saved_time_scale :float
var _saved_iterations_per_second :float

func _init(test_suite :WeakRef, scene, verbose :bool, hide_push_errors = false):
	_verbose = verbose
	_test_suite = test_suite
	_saved_iterations_per_second = ProjectSettings.get_setting("physics/common/physics_fps")
	set_time_factor(1)
	# handle scene loading by resource path
	if typeof(scene) == TYPE_STRING:
		if !File.new().file_exists(scene):
			if not hide_push_errors:
				push_error("GdUnitSceneRunner: Can't load scene by given resource path: '%s'. The resource not exists." % scene)
			return
		if !str(scene).ends_with("tscn"):
			if not hide_push_errors:
				push_error("GdUnitSceneRunner: The given resource: '%s'. is not a scene." % scene)
			return
		_current_scene =  load(scene).instantiate()
	else:
		# verify we have a node instance
		if not scene is Node:
			if not hide_push_errors:
				push_error("GdUnitSceneRunner: The given instance '%s' is not a Node." % scene)
			return
		_current_scene = scene
	if _current_scene == null:
		if not hide_push_errors:
			push_error("GdUnitSceneRunner: Scene must be not null!")
		return
	_scene_tree = Engine.get_main_loop()
	_scene_tree.root.add_child(_current_scene)
	_simulate_start_time = LocalTime.now()

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# reset time factor to normal
		__deactivate_time_factor()
		_reset_input_to_default()
		if is_instance_valid(_current_scene):
			_scene_tree.root.remove_child(_current_scene)
			# don't free already memory managed instances
			if not GdUnitTools.is_auto_free_registered(_current_scene):
				_current_scene.free()
		_scene_tree = null
		_current_scene = null
		_test_suite = null
		# we hide the scene/main window after runner is finished 
		#OS.window_maximized = false
		#OS.set_window_minimized(true)

func simulate_key_pressed(key_code :int, shift :bool = false, control := false) -> GdUnitSceneRunner:
	simulate_key_press(key_code, shift, control)
	simulate_key_release(key_code, shift, control)
	return self

func simulate_key_press(key_code :int, shift :bool = false, control := false) -> GdUnitSceneRunner:
	__print_current_focus()
	var event = InputEventKey.new()
	event.button_pressed = true
	event.keycode = key_code
	event.physical_keycode = key_code
	event.alt = key_code == KEY_ALT
	event.shift = shift or key_code == KEY_SHIFT
	event.control = control or key_code == KEY_CTRL
	_apply_input_modifiers(event)
	_key_on_press.append(key_code)
	return _handle_input_event(event)

func simulate_key_release(key_code :int, shift :bool = false, control := false) -> GdUnitSceneRunner:
	__print_current_focus()
	var event = InputEventKey.new()
	event.button_pressed = false
	event.keycode = key_code
	event.physical_keycode = key_code
	event.alt = key_code == KEY_ALT
	event.shift = shift or key_code == KEY_SHIFT
	event.control = control or key_code == KEY_CTRL
	_apply_input_modifiers(event)
	_key_on_press.erase(key_code)
	return _handle_input_event(event)

func set_mouse_pos(pos :Vector2) -> GdUnitSceneRunner:
	var event := InputEventMouseMotion.new()
	event.position = pos
	event.global_position = get_global_mouse_position()
	_apply_input_modifiers(event)
	return _handle_input_event(event)

func get_mouse_position() -> Vector2:
	if _last_input_event is InputEventMouse:
		return _last_input_event.position
	return _current_scene.get_viewport().get_mouse_position()

func get_global_mouse_position() -> Vector2:
	return _scene_tree.root.get_mouse_position()

func simulate_mouse_move(pos :Vector2) -> GdUnitSceneRunner:
	var event := InputEventMouseMotion.new()
	event.position = pos
	event.relative = pos - get_mouse_position()
	event.global_position = get_global_mouse_position()
	_apply_input_mouse_mask(event)
	_apply_input_modifiers(event)
	return _handle_input_event(event)

func simulate_mouse_move_relative(relative :Vector2, speed :Vector2 = Vector2.ONE) -> GdUnitSceneRunner:
	if _last_input_event is InputEventMouse:
		var current_pos :Vector2 = _last_input_event.position
		var final_pos := current_pos + relative
		var delta_milli := speed.x * 0.1
		var t := 0.0
		while not current_pos.is_equal_approx(final_pos):
			t += delta_milli * speed.x
			simulate_mouse_move(current_pos)
			await _scene_tree.create_timer(delta_milli).timeout
			current_pos = current_pos.lerp(final_pos, t)
		simulate_mouse_move(final_pos)
		await _scene_tree.idle_frame
	return self

func simulate_mouse_button_pressed(buttonIndex :int, double_click := false) -> GdUnitSceneRunner:
	simulate_mouse_button_press(buttonIndex, double_click)
	simulate_mouse_button_release(buttonIndex)
	return self

func simulate_mouse_button_press(buttonIndex :int, double_click := false) -> GdUnitSceneRunner:
	var event := InputEventMouseButton.new()
	event.button_index = buttonIndex
	event.button_pressed = true
	event.doubleclick = double_click
	_apply_input_mouse_position(event)
	_apply_input_mouse_mask(event)
	_apply_input_modifiers(event)
	_mouse_button_on_press.append(buttonIndex)
	return _handle_input_event(event)

func simulate_mouse_button_release(buttonIndex :int) -> GdUnitSceneRunner:
	var event := InputEventMouseButton.new()
	event.button_index = buttonIndex
	event.button_pressed = false
	_apply_input_mouse_position(event)
	_apply_input_mouse_mask(event)
	_apply_input_modifiers(event)
	_mouse_button_on_press.erase(buttonIndex)
	return _handle_input_event(event)

func set_time_factor(time_factor := 1.0) -> GdUnitSceneRunner:
	_time_factor = min(9.0, time_factor)
	__activate_time_factor()
	__print("set time factor: %f" % _time_factor)
	__print("set physics physics_ticks_per_second: %d" % (_saved_iterations_per_second*_time_factor))
	return self

func simulate_frames(frames: int, delta_milli :int = -1) -> GdUnitSceneRunner:
	var time_shift_frames := max(1, frames / _time_factor)
	for frame in time_shift_frames:
		if delta_milli == -1:
			await _scene_tree.idle_frame
		else:
			await _scene_tree.create_timer(delta_milli * 0.001).timeout
	return self

func simulate_until_signal(signal_name :String, arg0=NO_ARG, arg1=NO_ARG, arg2=NO_ARG, arg3=NO_ARG, arg4=NO_ARG, arg5=NO_ARG, arg6=NO_ARG, arg7=NO_ARG, arg8=NO_ARG, arg9=NO_ARG) -> GdUnitSceneRunner:
	var args = GdObjects.array_filter_value([arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9], NO_ARG)
	await GdUnitAwaiter.await_signal_idle_frames(_test_suite, _current_scene, signal_name, args, 10000).completed
	return self

func simulate_until_object_signal(source :Object, signal_name :String, arg0=NO_ARG, arg1=NO_ARG, arg2=NO_ARG, arg3=NO_ARG, arg4=NO_ARG, arg5=NO_ARG, arg6=NO_ARG, arg7=NO_ARG, arg8=NO_ARG, arg9=NO_ARG) -> GdUnitSceneRunner:
	var args = GdObjects.array_filter_value([arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9], NO_ARG)
	await GdUnitAwaiter.await_signal_idle_frames(_test_suite, source, signal_name, args, 10000).completed
	return self

func await_func(func_name :String, args := [], expeced := GdUnitAssert.EXPECT_SUCCESS) -> GdUnitFuncAssert:
	return GdUnitFuncAssertImpl.new(_test_suite, _current_scene, func_name, args, expeced)

func await_func_on(instance :Object, func_name :String, args := [], expeced := GdUnitAssert.EXPECT_SUCCESS) -> GdUnitFuncAssert:
	return GdUnitFuncAssertImpl.new(_test_suite, instance, func_name, args, expeced)

func await_signal(signal_name :String, args := [], timeout := 2000 ):
	await GdUnitAwaiter.await_signal_on(_test_suite, _current_scene, signal_name, args, timeout).completed

func await_signal_on(source :Object, signal_name :String, args := [], timeout := 2000 ):
	await GdUnitAwaiter.await_signal_on(_test_suite, source, signal_name, args, timeout).completed

# maximizes the window to bring the scene visible
func maximize_view() -> GdUnitSceneRunner:
	get_window().mode = Window.MODE_MAXIMIZED if (true) else Window.MODE_WINDOWED
	OS.center_window()
	get_window().grab_focus()
	return self

func get_property(name :String):
	var property = _current_scene.get(name)
	if property != null:
		return property
	return  "The property '%s' not exist on loaded scene." % name

func invoke(name :String, arg0=NO_ARG, arg1=NO_ARG, arg2=NO_ARG, arg3=NO_ARG, arg4=NO_ARG, arg5=NO_ARG, arg6=NO_ARG, arg7=NO_ARG, arg8=NO_ARG, arg9=NO_ARG):
	var args = GdObjects.array_filter_value([arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9], NO_ARG)
	if _current_scene.has_method(name):
		return _current_scene.callv(name, args)
	return "The method '%s' not exist on loaded scene." % name

func find_child(name :String, recursive :bool = true, owned :bool = false) -> Node:
	return _current_scene.find_child(name, recursive, owned)

func _scene_name() -> String:
	var scene_script :GDScript = _current_scene.get_script()
	if not scene_script:
		return _current_scene.get_name()
	if not _current_scene.get_name().begins_with("@"):
		return _current_scene.get_name()
	return scene_script.resource_name.get_basename()

func __activate_time_factor() -> void:
	Engine.set_time_scale(_time_factor)
	Engine.set_physics_ticks_per_second(_saved_iterations_per_second * _time_factor)

func __deactivate_time_factor() -> void:
	Engine.set_time_scale(1)
	Engine.set_physics_ticks_per_second(_saved_iterations_per_second)

# copy over current active modifiers
func _apply_input_modifiers(event :InputEvent) -> void:
	if _last_input_event is InputEventWithModifiers and event is InputEventWithModifiers:
		event.alt = event.alt or _last_input_event.alt
		event.shift = event.shift or _last_input_event.shift
		event.control = event.control or _last_input_event.control
		event.meta = event.meta or _last_input_event.meta
		event.command = event.command or _last_input_event.command

# copy over current active mouse mask and combine with curren mask
func _apply_input_mouse_mask(event :InputEvent) -> void:
	# first apply last mask
	if _last_input_event is InputEventMouse and event is InputEventMouse:
		event.button_mask |= _last_input_event.button_mask
	if event is InputEventMouseButton:
		var button_mask = MAP_MOUSE_BUTTON_MASKS.get(event.get_button_index(), 0)
		if event.is_pressed():
			event.button_mask |= button_mask
		else:
			event.button_mask ^= button_mask

# copy over last mouse position if need
func _apply_input_mouse_position(event :InputEvent) -> void:
	if _last_input_event is InputEventMouse and event is InputEventMouseButton:
		event.position = _last_input_event.position
		event.global_position = get_global_mouse_position()


# for handling read https://docs.godotengine.org/en/3.5/tutorials/inputs/inputevent.html
func _handle_input_event(event :InputEvent):
	if event is InputEventMouse:
		Input.warp_mouse(event.position)
	
	# before v3.5 the use_accumulated_input is false but should be true
	if Engine.get_version_info().hex < 0x030500:
		Input.set_use_accumulated_input(true)
	Input.parse_input_event(event)
	# do explicit flush input events: https://github.com/godotengine/godot/issues/63969
	#if Engine.get_version_info().hex >= 0x030500 and Input.use_accumulated_input:
	Input.flush_buffered_events()
	
	if is_instance_valid(_current_scene):
		__print("	process event %s (%s) <- %s" % [_current_scene, _scene_name(), event.as_text()])
		if(_current_scene.has_method("_gui_input")):
			_current_scene._gui_input(event)
		if(_current_scene.has_method("_unhandled_input")):
			_current_scene._unhandled_input(event)
		_scene_tree.set_input_as_handled()
	# save last input event needs to be merged with next InputEventMouseButton
	_last_input_event = event
	return self

func _reset_input_to_default() -> void:
	# reset all mouse button to inital state if need
	for m_button in _mouse_button_on_press.duplicate():
		if Input.is_mouse_button_pressed(m_button):
			simulate_mouse_button_release(m_button)
	_mouse_button_on_press.clear()
	
	for key_scancode in _key_on_press.duplicate():
		if Input.is_key_pressed(key_scancode):
			simulate_key_release(key_scancode)
	_key_on_press.clear()
	Input.flush_buffered_events()

func __print(message :String) -> void:
	if _verbose:
		prints(message)

func __print_current_focus() -> void:
	if not _verbose:
		return
	var focused_node = _current_scene.get_viewport().gui_get_focus_owner()
	if focused_node:
		prints("	focus on %s" % focused_node)
	else:
		prints("	no focus set")

func scene() -> Node:
	return _current_scene
