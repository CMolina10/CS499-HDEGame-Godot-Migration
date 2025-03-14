# prototype of console with CSI support
# https://notes.burke.libbey.me/ansi-escape-codes/
class_name CmdConsole
extends RefCounted

const BOLD = 0x1
const ITALIC = 0x2
const UNDERLINE = 0x4

const __CSI_BOLD = "[1m"
const __CSI_ITALIC = "[3m"
const __CSI_UNDERLINE = "[4m"

enum {
	COLOR_TABLE,
	COLOR_RGB
}

# Control Sequence Introducer
#var csi := PoolByteArray([0x1b]).get_string_from_ascii()
var _debug_show_color_codes := false
var _color_mode = COLOR_TABLE


func color(color :Color) -> CmdConsole:
	# using color table 16 - 231 a  6 x 6 x 6 RGB color cube  (16 + R * 36 + G * 6 + B)
	if _color_mode == COLOR_TABLE:
		var c2 = 16 + (int(color.r8/42) * 36) + (int(color.g8/42) * 6) + int(color.b8/42)
		if _debug_show_color_codes:
			printraw("%6d" % [c2])
		printraw("[38;5;%dm" % c2 )
	else:
		if _debug_show_color_codes:
			printraw("%s" % color.to_html(false))
		printraw("[38;2;%d;%d;%dm" % [color.r8, color.g8, color.b8] )
	return self

func end_color() -> CmdConsole:
	printraw("[0m")
	return self

func row_pos(row :int) -> CmdConsole:
	printraw("[%d;0H" % row )
	return self

func scrollArea(from :int, to :int ) -> CmdConsole:
	printraw("[%d;%dr" % [from ,to])
	return self

func progressBar(progress :int) -> CmdConsole:
	#printraw(  "[%-100s][%d]\r" % [bar, progress])
	return self

func printl(value :String) -> CmdConsole:
	printraw(value)
	return self

func new_line() -> CmdConsole:
	prints()
	return self

func reset() -> CmdConsole:
	return self

func bold(enable :bool) -> CmdConsole:
	if enable:
		printraw(__CSI_BOLD)
	return self

func italic(enable :bool) -> CmdConsole:
	if enable:
		printraw(__CSI_ITALIC)
	return self

func underline(enable :bool) -> CmdConsole:
	if enable:
		printraw(__CSI_UNDERLINE)
	return self

func prints_error(message :String) -> CmdConsole:
	return color(Color.CRIMSON).printl(message).end_color().new_line()

func prints_warning(message :String) -> CmdConsole:
	return color(Color.GOLDENROD).printl(message).end_color().new_line()
	return self

func prints_color(message :String, color :Color, flags := 0) -> CmdConsole:
	return print_color(message, color, flags).new_line()

func print_color( message :String, color :Color, flags := 0) -> CmdConsole:
	return color(color)\
		super.bold(flags&BOLD == BOLD)\
		super.italic(flags&ITALIC == ITALIC)\
		super.underline(flags&UNDERLINE == UNDERLINE)\
		super.printl(message)\
		super.end_color()

func print_color_table():
	prints_color("Color Table 6x6x6", Color.ANTIQUE_WHITE)
	_debug_show_color_codes = true
	for green in range(0, 6):
		for red in range(0, 6):
			for blue in range(0, 6):
				print_color("████████ ", Color8(red*42, green*42, blue*42))
			new_line()
		new_line()
		
	prints_color("Color Table RGB", Color.ANTIQUE_WHITE)
	_color_mode = COLOR_RGB
	for green in range(0, 6):
		for red in range(0, 6):
			for blue in range(0, 6):
				print_color("████████ ", Color8(red*42, green*42, blue*42))
			new_line()
		new_line()
	_color_mode = COLOR_TABLE
	_debug_show_color_codes = false
