class_name GdUnitSignalAssertImpl
extends GdUnitSignalAssert

const DEFAULT_TIMEOUT := 2000
const NO_ARG = "<--null-->"

var _emitter :Object
var _current_error_message = null
var _custom_failure_message = null
var _line_number := -1
var _expect_fail := false
var _is_failed := false
var _timeout := DEFAULT_TIMEOUT
var _expect_result :int
var _report_consumer : GdUnitReportConsumer
var _caller : WeakRef
var _interrupted := false
var _signal_collector := SignalCollector.instantiate()

const _singletons :Dictionary = Dictionary()
# This is an singelton implementation and reused for each GdUnitSignalAssert
# It connects to all signals of given emitter and collects received signals and arguments
# The collected signals are cleand finally when the emitter is freed.
class SignalCollector:
	
	const CLASS_NAME = "SignalCollector"
	const SIGNAL_BLACK_LIST = []#["tree_exiting", "tree_exited", "child_exiting_tree"]
	
	# {
	#	emitter<Object> : {
	#		signal_name<String> : [signal_args<Array>],
	#		...
	#	}
	# }
	var _collected_signals :Dictionary = {}
	
	static func instance() -> SignalCollector:
		if not _singletons.has(CLASS_NAME):
			_singletons[CLASS_NAME] = SignalCollector.new()
		return _singletons[CLASS_NAME]
	
	# connect to all possible signals defined by the emitter
	# prepares the signal collection to store received signals and arguments
	func register_emitter(emitter :Object):
		if is_instance_valid(emitter):
			# check emitter is already registerd
			if _collected_signals.has(emitter):
				return
			_collected_signals[emitter] = Dictionary()
			# connect to 'tree_exiting' of the emitter to finally release all acquired resources/connections.
			if !emitter.is_connected("tree_exiting", Callable(self, "unregister_emitter")):
				emitter.connect("tree_exiting", Callable(self, "unregister_emitter").bind(self, emitter))
			# connect to all signals of the emitter we want to collect
			for signal_def in emitter.get_signal_list():
				var signal_name = signal_def["name"]
				# set inital collected to empty
				if not is_signal_collecting(emitter, signal_name):
					_collected_signals[emitter][signal_name] = Array()
				if SIGNAL_BLACK_LIST.find(signal_name) != -1:
					continue
				if !emitter.is_connected(signal_name, Callable(self, "_on_signal_emmited")):
					emitter.connect(signal_name, Callable(self, "_on_signal_emmited").bind(emitter, signal_name))
	
	# unregister all acquired resources/connections, otherwise it ends up in orphans
	# is called when the emitter is removed from the parent
	func unregister_emitter(receiver :SignalCollector, emitter :Object):
		if is_instance_valid(receiver):
			#prints("disconnect_signals", receiver)
			for connection in receiver.get_incoming_connections():
				var source :Object = connection["source"]
				var signal_name :String = connection["signal_name"]
				var method_name :String = connection["method_name"]
				#prints("disconnect", signal_name, source, receiver, method_name)
				source.disconnect(signal_name, Callable(receiver, method_name))
		if is_instance_valid(emitter):
			_collected_signals.erase(emitter)
	
	# receives the signal from the emitter with all emitted signal arguments and additional the emitter and signal_name as last two arguements
	func _on_signal_emmited( arg0=NO_ARG, arg1=NO_ARG, arg2=NO_ARG, arg3=NO_ARG, arg4=NO_ARG, arg5=NO_ARG, arg6=NO_ARG, arg7=NO_ARG, arg8=NO_ARG, arg9=NO_ARG, arg10=NO_ARG, arg11=NO_ARG):
		var signal_args = GdObjects.array_filter_value([arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11], NO_ARG)
		# extract the emitter and signal_name from the last two arguments (see line 61 where is added)
		var signal_name :String = signal_args.pop_back()
		var emitter :Object = signal_args.pop_back()
		#prints("_on_signal_emmited:", emitter, signal_name, signal_args)
		if is_signal_collecting(emitter, signal_name):
			_collected_signals[emitter][signal_name].append(signal_args)
	
	func reset_received_signals(emitter :Object):
		#debug_signal_list("before claer");
		if _collected_signals.has(emitter):
			for signal_name in _collected_signals[emitter]:
				_collected_signals[emitter][signal_name].clear()
		#debug_signal_list("after claer");
	
	func is_signal_collecting(emitter :Object, signal_name :String) -> bool:
		return _collected_signals.has(emitter) and _collected_signals[emitter].has(signal_name)
	
	func match(emitter :Object, signal_name :String, args :Array) -> bool:
		#prints("match", signal_name,  _collected_signals[emitter][signal_name]);
		if _collected_signals.is_empty():
			return false
		for received_args in _collected_signals[emitter][signal_name]:
			#prints("testing", signal_name, received_args, "vs", args)
			if GdObjects.equals(received_args, args):
				return true
		return false
	
	func _debug_signal_list(message :String):
		prints("-----", message, "-------")
		prints("senders {")
		for emitter in _collected_signals:
			prints("\t", emitter)
			for signal_name in _collected_signals[emitter]:
				var args = _collected_signals[emitter][signal_name]
				prints("\t\t", signal_name, args)
		prints("}")

func _init(caller :WeakRef, emitter :Object, expect_result := EXPECT_SUCCESS):
	_line_number = GdUnitAssertImpl._get_line_number()
	_caller = caller
	_emitter =  emitter
	_expect_result = expect_result
	GdAssertReports.reset_last_error_line_number()
	# set report consumer to be use to report the final result
	_report_consumer = caller.get_ref().get_meta(GdUnitReportConsumer.META_PARAM)
	# we expect the test will fail
	if expect_result == EXPECT_FAIL:
		_expect_fail = true

func _notification(what):
	#prints(GdObjects.notification_as_string(what))
	if what == NOTIFICATION_PREDELETE:
		_caller = null

func report_success() -> GdUnitAssert:
	return GdAssertReports.report_success(self)

func report_warning(message :String) -> GdUnitAssert:
	return GdAssertReports.report_warning(self, message, GdUnitAssertImpl._get_line_number())

func report_error(error_message :String) -> GdUnitAssert:
	if _custom_failure_message == null:
		return GdAssertReports.report_error(error_message, self, _line_number)
	return GdAssertReports.report_error(_custom_failure_message, self, _line_number)

func send_report(report :GdUnitReport)-> void:
	if is_instance_valid(_report_consumer):
		_report_consumer.consume(report)

# -------- Base Assert wrapping ------------------------------------------------
func has_failure_message(expected: String) -> GdUnitSignalAssert:
	var current_error := GdUnitAssertImpl._normalize_bbcode(_current_error_message)
	if current_error != expected:
		_expect_fail = false
		var diffs := GdDiffTool.string_diff(current_error, expected)
		var current := GdAssertMessages.colorDiff(diffs[1])
		_custom_failure_message = null
		report_error(GdAssertMessages.error_not_same_error(current, expected))
	return self

func starts_with_failure_message(expected: String) -> GdUnitSignalAssert:
	var current_error := GdUnitAssertImpl._normalize_bbcode(_current_error_message)
	if not current_error.begins_with(expected):
		_expect_fail = false
		var diffs := GdDiffTool.string_diff(current_error, expected)
		var current := GdAssertMessages.colorDiff(diffs[1])
		_custom_failure_message = null
		report_error(GdAssertMessages.error_not_same_error(current, expected))
	return self

func override_failure_message(message :String) -> GdUnitSignalAssert:
	_custom_failure_message = message
	return self

func wait_until(timeout := 2000) -> GdUnitSignalAssert:
	if timeout <= 0:
		report_warning("Invalid timeout parameter, allowed timeouts must be greater than 0, use default timeout instead!")
		_timeout = DEFAULT_TIMEOUT
	else:
		_timeout = timeout
	return self

# Verifies the signal exists on the emitter
func is_signal_exists(signal_name :String) -> GdUnitSignalAssert:
	if not _emitter.has_signal(signal_name):
		report_error("The signal '%s' not exists on object '%s'." % [signal_name, _emitter.get_class()])
	return self

# Verifies that given signal is emitted until waiting time
func is_emitted(name :String, args := []) -> GdUnitSignalAssert:
	_line_number = GdUnitAssertImpl._get_line_number()
	return _wail_until_signal(name, args, false)

# Verifies that given signal is NOT emitted until waiting time
func is_not_emitted(name :String, args := []) -> GdUnitSignalAssert:
	_line_number = GdUnitAssertImpl._get_line_number()
	return _wail_until_signal(name, args, true)

func _wail_until_signal(signal_name :String, expected_args :Array, expect_not_emitted: bool):
	if _emitter == null:
		report_error("Can't wait for signal on a NULL object.")
		await Engine.get_main_loop().idle_frame
		return self
	# first verify the signal is defined
	if not _emitter.has_signal(signal_name):
		report_error("Can't wait for non-existion signal '%s' on object '%s'." % [signal_name,_emitter.get_class()])
		await Engine.get_main_loop().idle_frame
		return self
	_signal_collector.register_emitter(_emitter)
	var caller = _caller.get_ref()
	var time_scale = Engine.get_time_scale()
	var timeout = Timer.new()
	caller.add_child(timeout)
	timeout.set_one_shot(true)
	timeout.connect("timeout", Callable(self, "_on_timeout"))
	timeout.start((_timeout/1000.0)*time_scale)
	var is_signal_emitted = false
	while not _interrupted and not is_signal_emitted:
		await Engine.get_main_loop().idle_frame
		is_signal_emitted = _signal_collector.match(_emitter, signal_name, expected_args)
		if is_signal_emitted and expect_not_emitted:
			report_error(GdAssertMessages.error_signal_emitted(signal_name, expected_args, LocalTime.elapsed(_timeout-timeout.time_left*1000)))
	
	if _interrupted and not expect_not_emitted:
		report_error(GdAssertMessages.error_wait_signal(signal_name, expected_args, LocalTime.elapsed(_timeout)))
	timeout.free()
	_signal_collector.reset_received_signals(_emitter)
	return self

func _on_timeout():
	_interrupted = true
