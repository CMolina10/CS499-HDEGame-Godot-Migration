class_name GdUnitTask
extends RefCounted

const TASK_NAME = "task_name"
const TASK_ARGS = "task_args"

var _task_name :String
var _fref :FuncRef

func _init(task_name :String, instance :Object, func_name :String):
	_task_name = task_name
	if not instance.has_method(func_name):
		push_error("Can't create GdUnitTask, Invalid func name '%s' for instance '%s'" % [instance, func_name])
	_fref = funcref(instance, func_name)

func name() -> String:
	return _task_name

func execute(args :Array) -> Result:
	if args.is_empty():
		return _fref.call_func()
	return _fref.call_funcv(args)
