class_name IntFuzzer
extends Fuzzer

enum {
	NORMAL,
	EVEN,
	ODD
}

var _from :int = 0
var _to : int = 0
var _mode : int = NORMAL

func _init(from: int, to: int, mode :int = NORMAL):
	assert(from <= to, "Invalid range!")
	_from = from
	_to = to
	_mode = mode

func next_value() -> int:
	var value = randf_range(_from, _to) as int
	match _mode:
		NORMAL:
			return value
		EVEN:
			return (value / 2) * 2
		ODD:
			return (value / 2) * 2 + 1
		_:
			return value
