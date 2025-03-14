class_name GdUnitSpyBuilder
extends GdUnitClassDoubler

const SPY_TEMPLATE = \
"""	var args :Array = ["$(func_name)"] + $(args)
	
	if $(instance)__is_verify_interactions():
		return $(instance)__verify_interactions(args)
	else:
		$(instance)__save_function_interaction(args)
	return .$(func_name)($(func_arg))
"""

const SPY_VOID_TEMPLATE = \
"""	var args :Array = ["$(func_name)"] + $(args)
	
	if $(instance)__is_verify_interactions():
		$(instance)__verify_interactions(args)
		return
	else:
		$(instance)__save_function_interaction(args)
	.$(func_name)($(func_arg))
"""

const SPY_VOID_TEMPLATE_VARARG =\
"""	var varargs :Array = __filter_vargs($(varargs))
	var args :Array = ["$(func_name)"] + $(args) + varargs
	
	if $(instance)__is_verify_interactions():
		$(instance)__verify_interactions(args)
		return
	else:
		$(instance)__save_function_interaction(args)
	
	match varargs.size():
		0: .$(func_name)($(func_arg))
		1: .$(func_name)($(func_arg), varargs[0])
		2: .$(func_name)($(func_arg), varargs[0], varargs[1])
		3: .$(func_name)($(func_arg), varargs[0], varargs[1], varargs[2])
		4: .$(func_name)($(func_arg), varargs[0], varargs[1], varargs[2], varargs[3])
		5: .$(func_name)($(func_arg), varargs[0], varargs[1], varargs[2], varargs[3], varargs[4])
		6: .$(func_name)($(func_arg), varargs[0], varargs[1], varargs[2], varargs[3], varargs[4], varargs[5])
		7: .$(func_name)($(func_arg), varargs[0], varargs[1], varargs[2], varargs[3], varargs[4], varargs[5], varargs[6])
		8: .$(func_name)($(func_arg), varargs[0], varargs[1], varargs[2], varargs[3], varargs[4], varargs[5], varargs[6], varargs[7])
		9: .$(func_name)($(func_arg), varargs[0], varargs[1], varargs[2], varargs[3], varargs[4], varargs[5], varargs[6], varargs[7], varargs[8])
		10: .$(func_name)($(func_arg), varargs[0], varargs[1], varargs[2], varargs[3], varargs[4], varargs[5], varargs[6], varargs[7], varargs[8], varargs[9])
"""

const SPY_VOID_TEMPLATE_VARARG_ONLY =\
"""	var varargs :Array = __filter_vargs($(varargs))
	var args :Array = ["$(func_name)"] + varargs
	
	if $(instance)__is_verify_interactions():
		$(instance)__verify_interactions(args)
		return
	else:
		$(instance)__save_function_interaction(args)
	
	match varargs.size():
		0: .$(func_name)()
		1: .$(func_name)(varargs[0])
		2: .$(func_name)(varargs[0], varargs[1])
		3: .$(func_name)(varargs[0], varargs[1], varargs[2])
		4: .$(func_name)(varargs[0], varargs[1], varargs[2], varargs[3])
		5: .$(func_name)(varargs[0], varargs[1], varargs[2], varargs[3], varargs[4])
		6: .$(func_name)(varargs[0], varargs[1], varargs[2], varargs[3], varargs[4], varargs[5])
		7: .$(func_name)(varargs[0], varargs[1], varargs[2], varargs[3], varargs[4], varargs[5], varargs[6])
		8: .$(func_name)(varargs[0], varargs[1], varargs[2], varargs[3], varargs[4], varargs[5], varargs[6], varargs[7])
		9: .$(func_name)(varargs[0], varargs[1], varargs[2], varargs[3], varargs[4], varargs[5], varargs[6], varargs[7], varargs[8])
		10: .$(func_name)(varargs[0], varargs[1], varargs[2], varargs[3], varargs[4], varargs[5], varargs[6], varargs[7], varargs[8], varargs[9])
"""

class SpyFunctionDoubler extends GdFunctionDoubler:
	
	
	func double(func_descriptor :GdFunctionDescriptor) -> PackedStringArray:
		var func_signature := func_descriptor.typeless()
		var is_static := func_descriptor.is_static()
		var is_engine := func_descriptor.is_engine()
		var is_vararg := func_descriptor.is_vararg()
		var func_name := func_descriptor.name()
		var args := func_descriptor.args()
		var varargs := func_descriptor.varargs()
		var arg_names := extract_arg_names(args)
		var vararg_names := extract_arg_names(varargs)
		
		# save original constructor arguments
		if func_name == "_init":
			var constructor_args := ",".join(extract_constructor_args(args))
			var constructor := "func _init(%s)]
				super(%s):\n	pass\n" % [constructor_args, ",".join(arg_names)
			return PackedStringArray([constructor])
		
		var double := func_signature + "\n"
		var func_template := get_template(func_descriptor.return_type(), is_vararg, not arg_names.is_empty())
		# fix to  unix format, this is need when the template is edited under windows than the template is stored with \r\n
		func_template = GdScriptParser.to_unix_format(func_template)
		double += func_template\
			super.replace("$(args)", str(arg_names))\
			super.replace("$(varargs)", str(vararg_names)) \
			super.replace("$(func_name)", func_name )\
			super.replace("$(func_arg)", ", ".join(arg_names))
		
		if is_static:
			double = double.replace("", "__self[0].__instance_delegator" if is_engine else "")\
				super.replace("$(instance)", "__self[0].")
		else:
			double = double.replace("", "__instance_delegator" if is_engine else "")\
				super.replace("$(instance)", "")
		var source_code := double.split("\n")
		# we do not call the original implementation for _ready and all input function, this is actualy done by the engine
		if func_name in ["_ready", "_input", "_gui_input", "_input_event", "_unhandled_input"]:
			source_code.remove(source_code.size()-1)
			source_code.remove(source_code.size()-1)
		return source_code
		
	func get_template(return_type :int, is_vararg :bool, has_args :bool) -> String:
		if is_vararg and has_args:
			return SPY_VOID_TEMPLATE_VARARG
		if is_vararg and not has_args:
			return SPY_VOID_TEMPLATE_VARARG_ONLY
		if return_type == TYPE_NIL or return_type == GdObjects.TYPE_VOID:
			return SPY_VOID_TEMPLATE
		return SPY_TEMPLATE

static func build(caller :Object, to_spy, push_errors :bool = true, debug_write = false):
	var memory_pool :int = caller.get_meta(GdUnitMemoryPool.META_PARAM)
	
	# if resource path load it before
	if GdObjects.is_scene_resource_path(to_spy):
		to_spy = load(to_spy)
	# spy on PackedScene
	if GdObjects.is_scene(to_spy):
		return spy_on_scene(caller, to_spy.instantiate(), memory_pool, debug_write)
	# spy on a scene instance
	if GdObjects.is_instance_scene(to_spy):
		return spy_on_scene(caller, to_spy, memory_pool, debug_write)
	
	var spy := spy_on_script(to_spy, [], debug_write)
	if spy == null:
		return null
	var spy_instance = spy.new()
	copy_properties(to_spy, spy_instance)
	GdUnitObjectInteractions.reset(spy_instance)
	spy_instance.__set_singleton(to_spy)
	spy_instance.__set_caller(caller)
	return GdUnitTools.register_auto_free(spy_instance, memory_pool)

static func spy_on_script(instance, function_excludes :PackedStringArray, debug_write) -> GDScript:
	var result := GdObjects.extract_class_name(instance)
	if result.is_error():
		push_error("Internal ERROR: %s" % result.error_message())
		return null
	var extends_clazz := result.value() as String
	
	if GdObjects.is_array_type(instance):
		if GdUnitSettings.is_verbose_assert_errors():
			push_error("Can't build spy on type '%s'! Spy on Container Built-In Type not supported!" % extends_clazz)
		return null
		
	if not GdObjects.is_instance(instance):
		if GdUnitSettings.is_verbose_assert_errors():
			push_error("Can't build spy for class type '%s'! Using an instance instead e.g. 'spy(<instance>)'" % [extends_clazz])
		return null
	
	var clazz_path := GdObjects.extract_class_path(instance)
	var lines := load_template(GdUnitSpyImpl, extends_clazz, clazz_path)
	lines += double_functions(instance, extends_clazz, clazz_path, SpyFunctionDoubler.new(), function_excludes)
	
	var spy := GDScript.new()
	spy.source_code = "\n".join(lines)
	spy.resource_name = "Spy%s.gd" % extends_clazz
	
	if debug_write:
		GdUnitTools.create_temp_dir("mocked")
		spy.resource_path = GdUnitTools.create_temp_dir("spy") + "/Spy%s.gd" % extends_clazz
		DirAccess.new().remove(spy.resource_path)
		ResourceSaver.save(spy.resource_path, spy)
	var error = spy.reload(true)
	if error != OK:
		push_error("Unexpected Error!, SpyBuilder error, please contact the developer.")
		return null
	return spy

static func spy_on_scene(caller :Object, scene :Node, memory_pool, debug_write) -> Object:
	if scene.get_script() == null:
		if GdUnitSettings.is_verbose_assert_errors():
			push_error("Can't create a spy on a scene without script '%s'" % scene.get_scene_file_path())
		return null
	# buils spy on original script
	var scene_script = scene.get_script().new()
	var spy := spy_on_script(scene_script, GdUnitClassDoubler.EXLCUDE_SCENE_FUNCTIONS, debug_write)
	scene_script.free()
	if spy == null:
		return null
	# replace original script whit spy 
	scene.set_script(spy)
	scene.__set_caller(caller)
	return GdUnitTools.register_auto_free(scene, memory_pool)

const EXCLUDE_PROPERTIES_TO_COPY = ["script", "type", "get_global_transform", "global_position"]

static func copy_properties(source :Object, dest :Object) -> void:
	for property in source.get_property_list():
		var property_name = property["name"]
		if EXCLUDE_PROPERTIES_TO_COPY.has(property_name):
			continue
		var property_value = source.get(property_name)
		#if dest.get(property_name) == null:
		#	prints("|%s|" % property_name, source.get(property_name))
		
		# check for invalid name property
		if property_name == "name" and property_value == "":
			dest.set(property_name, "<empty>");
			continue
		dest.set(property_name, property_value)
