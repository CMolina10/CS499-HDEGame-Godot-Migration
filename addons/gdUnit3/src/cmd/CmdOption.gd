class_name CmdOption
extends RefCounted


var _commands :PackedStringArray
var _help :String
var _description :String
var _type :int
var _arg_optional :bool = false

# constructs a command option by given arguments
# commands : a string with comma separated list of available commands begining with the short form
# help: a help text show howto use
# description: a full description of the command
# type: the argument type
# arg_optional: defines of the argument optional
func _init(commands :String, help :String, description :String, type :int = TYPE_NIL, arg_optional :bool = false):
	_commands = commands.replace(" ", "").replace("\t", "").split(",")
	_help = help
	_description = description
	_type = type
	_arg_optional = arg_optional

func commands() -> PackedStringArray:
	return _commands

func short_command() -> String:
	return _commands[0]

func help() -> String:
	return _help

func description() -> String:
	return _description

func type() -> int:
	return _type

func is_argument_optional() -> bool:
	return _arg_optional

func has_argument() -> bool:
	return _type != TYPE_NIL
	
func describe() -> String:
	if help().is_empty():
		return "  %-32s %s \n" % [commands(), description()]
	return "  %-32s %s \n  %-32s %s\n" % [commands(), description(), "", help()]
	
func _to_string():
	return describe()
