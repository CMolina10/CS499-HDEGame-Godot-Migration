@tool
class_name GdUnitSettings
extends RefCounted

const MAIN_CATEGORY = "gdunit3"
# Common Settings
const COMMON_SETTINGS = MAIN_CATEGORY + "/settings"

const GROUP_COMMON = COMMON_SETTINGS + "/common"
const UPDATE_NOTIFICATION_ENABLED = GROUP_COMMON + "/update_notification_enabled"
const SERVER_TIMEOUT = GROUP_COMMON + "/server_connection_timeout_minutes"

const GROUP_TEST = COMMON_SETTINGS + "/test"
const TEST_TIMEOUT = GROUP_TEST + "/test_timeout_seconds"
const TEST_ROOT_FOLDER = GROUP_TEST + "/test_root_folder"
const TEST_SITE_NAMING_CONVENTION = GROUP_TEST + "/test_suite_naming_convention"

# UI Setiings
const GROUP_UI = COMMON_SETTINGS + "/ui"
const INSPECTOR_NODE_COLLAPSE = GROUP_UI + "/inspector_node_collapse"


# Report Setiings
const REPORT_SETTINGS = MAIN_CATEGORY + "/report"
const GROUP_GODOT = REPORT_SETTINGS + "/godot"
const REPORT_PUSH_ERRORS = GROUP_GODOT + "/push_error"
const REPORT_SCRIPT_ERRORS = GROUP_GODOT + "/script_error"
const REPORT_ORPHANS  = REPORT_SETTINGS + "/verbose_orphans"
const GROUP_ASSERT = REPORT_SETTINGS + "/assert"
const REPORT_ASSERT_WARNINGS = GROUP_ASSERT + "/verbose_warnings"
const REPORT_ASSERT_ERRORS   = GROUP_ASSERT + "/verbose_errors"
const REPORT_ASSERT_STRICT_NUMBER_TYPE_COMPARE = GROUP_ASSERT + "/strict_number_type_compare"

# Godot stdout/logging settings
const CATEGORY_LOGGING := "logging/file_logging/"
const STDOUT_ENABLE_TO_FILE = CATEGORY_LOGGING + "enable_file_logging"
const STDOUT_WITE_TO_FILE = CATEGORY_LOGGING + "log_path"


# GdUnit Templates
const TEMPLATES = MAIN_CATEGORY + "/templates"
const TEMPLATES_TS = TEMPLATES + "/testsuite"
const TEMPLATE_TS_GD = TEMPLATES_TS + "/GDScript"
const TEMPLATE_TS_CS = TEMPLATES_TS + "/CSharpScript"

# defaults
# server connection timeout in minutes
const DEFAULT_SERVER_TIMEOUT :int = 30
# test case runtime timeout in seconds
const DEFAULT_TEST_TIMEOUT :int = 60*5
# the folder to create new test-suites
const DEFAULT_TEST_ROOT_FOLDER := "test"

enum NAMING_CONVENTIONS {
	AUTO_DETECT,
	SNAKE_CASE,
	PASCAL_CASE,
}

static func setup():
	create_property_if_need(UPDATE_NOTIFICATION_ENABLED, true, "Enables/Disables the update notification on startup.")
	create_property_if_need(SERVER_TIMEOUT, DEFAULT_SERVER_TIMEOUT, "Sets the server connection timeout in minutes.")
	create_property_if_need(TEST_TIMEOUT, DEFAULT_TEST_TIMEOUT, "Sets the test case runtime timeout in seconds.")
	create_property_if_need(TEST_ROOT_FOLDER, DEFAULT_TEST_ROOT_FOLDER, "Sets the root folder where test-suites located/generated.")
	create_property_if_need(TEST_SITE_NAMING_CONVENTION, NAMING_CONVENTIONS.AUTO_DETECT, "Sets test-suite genrate script name convention.", NAMING_CONVENTIONS.keys())
	create_property_if_need(REPORT_PUSH_ERRORS, false, "Enables/Disables report of push_error() as failure!")
	create_property_if_need(REPORT_SCRIPT_ERRORS, true, "Enables/Disables report of script errors as failure!")
	create_property_if_need(REPORT_ORPHANS, true, "Enables/Disables orphan reporting.")
	create_property_if_need(REPORT_ASSERT_ERRORS, true, "Enables/Disables error reporting on asserts.")
	create_property_if_need(REPORT_ASSERT_WARNINGS, true, "Enables/Disables warning reporting on asserts")
	create_property_if_need(REPORT_ASSERT_STRICT_NUMBER_TYPE_COMPARE, true, "Enabled/disabled number values will be compared strictly by type. (real vs int)")
	create_property_if_need(INSPECTOR_NODE_COLLAPSE, true, "Enables/disables that the testsuite node is closed after a successful test run.")
	create_property_if_need(TEMPLATE_TS_GD, GdUnitTestSuiteDefaultTemplate.DEFAULT_TEMP_TS_GD, "Defines the test suite template")

static func create_property_if_need(name :String, default, help :="", value_set := PackedStringArray()) -> void:
	if not ProjectSettings.has_setting(name):
		#prints("GdUnit3: Set inital settings '%s' to '%s'." % [name, str(default)])
		ProjectSettings.set_setting(name, default)
		
	ProjectSettings.set_initial_value(name, default)
	var hint_string := help + ("" if value_set.is_empty() else " %s" % value_set)
	var info = {
			"name": name,
			"type": typeof(default),
			"hint": PROPERTY_HINT_LENGTH,
			"hint_string": hint_string,
		}
	ProjectSettings.add_property_info(info)

static func get_setting(name :String, default) :
	if ProjectSettings.has_setting(name):
		return ProjectSettings.get_setting(name)
	return default

static func is_update_notification_enabled() -> bool:
	if ProjectSettings.has_setting(UPDATE_NOTIFICATION_ENABLED):
		return ProjectSettings.get_setting(UPDATE_NOTIFICATION_ENABLED)
	return false

static func set_update_notification(enable :bool) -> void:
	ProjectSettings.set_setting(UPDATE_NOTIFICATION_ENABLED, enable)
	ProjectSettings.save()

static func get_log_path() -> String:
	return ProjectSettings.get_setting(STDOUT_WITE_TO_FILE)

static func set_log_path(path :String) -> void:
	ProjectSettings.set_setting(STDOUT_ENABLE_TO_FILE, true)
	ProjectSettings.set_setting(STDOUT_WITE_TO_FILE, path)
	ProjectSettings.save()

# the configured server connection timeout in ms
static func server_timeout() -> int:
	return get_setting(SERVER_TIMEOUT, DEFAULT_SERVER_TIMEOUT) * 60 * 1000

# the configured test case timeout in ms
static func test_timeout() -> int:
	return get_setting(TEST_TIMEOUT, DEFAULT_TEST_TIMEOUT) * 1000

# the root folder to store/generate test-suites
static func test_root_folder() -> String:
	return get_setting(TEST_ROOT_FOLDER, DEFAULT_TEST_ROOT_FOLDER) 

static func is_verbose_assert_warnings() -> bool:
	return get_setting(REPORT_ASSERT_WARNINGS, true)

static func is_verbose_assert_errors() -> bool:
	return get_setting(REPORT_ASSERT_ERRORS, true)

static func is_verbose_orphans() -> bool:
	return get_setting(REPORT_ORPHANS, true)

static func is_strict_number_type_compare() -> bool:
	return get_setting(REPORT_ASSERT_STRICT_NUMBER_TYPE_COMPARE, true)

static func is_report_push_errors() -> bool:
	return get_setting(REPORT_PUSH_ERRORS, false)

static func is_report_script_errors() -> bool:
	return get_setting(REPORT_SCRIPT_ERRORS, true)

static func is_inspector_node_collapse() -> bool:
	return get_setting(INSPECTOR_NODE_COLLAPSE, true)

static func is_log_enabled() -> bool:
	return ProjectSettings.get_setting(STDOUT_ENABLE_TO_FILE)

static func list_settings(category :String) -> Array:
	var settings := Array()
	for property in ProjectSettings.get_property_list():
		var property_name = property["name"]
		if property_name.begins_with(category):
			var value = ProjectSettings.get_setting(property_name)
			var default = ProjectSettings.property_get_revert(property_name)
			var help :String = property["hint_string"]
			var value_set := extract_value_set_from_help(help)
			settings.append(GdUnitProperty.new(property_name, property["type"], value, default, help, value_set))
	return settings

static func extract_value_set_from_help(value :String) -> PackedStringArray:
	var regex := RegEx.new()
	regex.compile("\\[(.+)\\]")
	var matches := regex.search_all(value)
	if matches.is_empty():
		return PackedStringArray()
	var values :String =  matches[0].get_string(1)
	return values.replacen(" ", "").split(",", false)

static func update_property(property :GdUnitProperty) -> void:
	ProjectSettings.set_setting(property.name(), property.value())
	save()

static func reset_property(property :GdUnitProperty) -> void:
	ProjectSettings.set_setting(property.name(), property.default())
	save()

static func save_property(name :String, value) -> void:
	ProjectSettings.set_setting(name, value)
	save()

static func save() -> void:
	var err := ProjectSettings.save()
	if err != OK:
		push_error("Save GdUnit3 settings failed : %s" % GdUnitTools.error_as_string(err))
		return

static func get_property(name :String) -> GdUnitProperty:
	for property in ProjectSettings.get_property_list():
		var property_name = property["name"]
		if property_name == name:
			var value = ProjectSettings.get_setting(property_name)
			var default = ProjectSettings.property_get_revert(property_name)
			var help :String = property["hint_string"]
			var value_set := extract_value_set_from_help(help)
			return GdUnitProperty.new(property_name, property["type"], value, default, help, value_set)
	return null

static func migrate_property(old_property :String, new_property :String, converter :FuncRef = null ) -> void:
	var property := get_property(old_property)
	if property == null:
		prints("Migration not possible, property '%s' not found", old_property)
		return
	var value = property.value() if converter == null else converter.call_func(property.value())
	create_property_if_need(new_property, property.default(), property.help(), property.value_set())
	ProjectSettings.set_setting(new_property, value)
	ProjectSettings.clear(old_property)
	prints("Succesfull migrated property '%s' -> '%s' value: %s" % [old_property, new_property, value])

static func dump_to_tmp() -> void:
	ProjectSettings.save_custom("user://project_settings.godot")

static func restore_dump_from_tmp() -> void:
	DirAccess.new().copy("user://project_settings.godot", "res://project.godot")
