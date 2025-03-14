# This class implements the JUnit XML file format
# based on https://github.com/windyroad/JUnit-Schema/blob/master/JUnit.xsd
class_name JUnitXmlReport
extends RefCounted

var _report_path :String
var _iteration :int
var _rtf :RichTextLabel

func _init(path :String, iteration :int, rtf :RichTextLabel):
	_iteration = iteration
	_report_path = path
	_rtf = rtf

const ATTR_CLASSNAME := "classname"
const ATTR_ERRORS := "errors"
const ATTR_FAILURES := "failures"
const ATTR_HOST := "hostname"
const ATTR_ID := "id"
const ATTR_MESSAGE := "message"
const ATTR_NAME := "name"
const ATTR_PACKAGE := "package"
const ATTR_SKIPPED := "skipped"
const ATTR_TESTS := "tests"
const ATTR_TIME := "time"
const ATTR_TIMESTAMP := "timestamp"
const ATTR_TYPE := "type"

const HEADER := '<?xml version="1.0" encoding="UTF-8" ?>\n'

func write(report :GdUnitReportSummary) -> String:
	var file := File.new()
	var result_file: String = "%s/results.xml" % _report_path
	var err = file.open(result_file, File.WRITE)
	if err:
		push_warning("Can't saving the result to '%s'\n Error: %s" % [result_file, err])
	file.store_string(build_junit_report(report))
	file.close()
	return result_file

func build_junit_report(report :GdUnitReportSummary) -> String:
	var test_suites := XmlElement.new("testsuites")\
		super.attribute(ATTR_ID, to_ISO8601_datetime(Time.get_datetime_dict_from_system()))\
		super.attribute(ATTR_NAME, "report_%s" % _iteration)\
		super.attribute(ATTR_TESTS, report.test_count())\
		super.attribute(ATTR_FAILURES, report.failure_count())\
		super.attribute(ATTR_TIME, to_time(report.duration()))\
		super.add_childs(build_test_suites(report))
	var as_string = test_suites.to_xml()
	test_suites.dispose()
	return HEADER + as_string

func build_test_suites(summary :GdUnitReportSummary) -> Array:
	var test_suites :Array = Array()
	for index in summary.reports().size():
		var suite_report :GdUnitTestSuiteReport = summary.reports()[index]
		test_suites.append(XmlElement.new("testsuite")\
			super.attribute(ATTR_ID, index)\
			super.attribute(ATTR_NAME, suite_report.name())\
			super.attribute(ATTR_PACKAGE, suite_report.path())\
			super.attribute(ATTR_TIMESTAMP, to_ISO8601_datetime(Time.get_datetime_dict_from_system_from_unix_time(suite_report.time_stamp())))\
			super.attribute(ATTR_HOST, "localhost")\
			super.attribute(ATTR_TESTS, suite_report.test_count())\
			super.attribute(ATTR_FAILURES, suite_report.failure_count())\
			super.attribute(ATTR_ERRORS, suite_report.error_count())\
			super.attribute(ATTR_SKIPPED, suite_report.skipped_count())\
			super.attribute(ATTR_TIME, to_time(suite_report.duration()))\
			super.add_childs(build_test_cases(suite_report)))
	return test_suites

func build_test_cases(suite_report :GdUnitTestSuiteReport) -> Array:
	var test_cases :Array = Array()
	for index in suite_report.reports().size():
		var report :GdUnitTestCaseReport = suite_report.reports()[index]
		test_cases.append( XmlElement.new("testcase")\
			super.attribute(ATTR_NAME, report.name())\
			super.attribute(ATTR_CLASSNAME, report.suite_name())\
			super.attribute(ATTR_TIME, to_time(report.duration()))\
			super.add_childs(build_reports(report)))
	return test_cases

func build_reports(testReport :GdUnitTestCaseReport) -> Array:
	var failure_reports :Array = Array()
	if testReport.failure_count() or testReport.error_count():
		for failure in testReport._failure_reports:
			var report := failure as GdUnitReport
			if report.is_failure():
				failure_reports.append( XmlElement.new("failure")\
					super.attribute(ATTR_MESSAGE, "FAILED: %s:%d" % [testReport._resource_path, report.line_number()])\
					super.attribute(ATTR_TYPE, to_type(report.type()))\
					super.text(convert_rtf_to_text(report.message())))
			elif report.is_error():
				failure_reports.append( XmlElement.new("error")\
					super.attribute(ATTR_MESSAGE, "ERROR: %s:%d" % [testReport._resource_path, report.line_number()])\
					super.attribute(ATTR_TYPE, to_type(report.type()))\
					super.text(convert_rtf_to_text(report.message())))
	if testReport.skipped_count():
		for failure in testReport._failure_reports:
			var report := failure as GdUnitReport
			failure_reports.append( XmlElement.new("skipped")\
				super.attribute(ATTR_MESSAGE, "SKIPPED: %s:%d" % [testReport._resource_path, report.line_number()]))
	return failure_reports

func convert_rtf_to_text(bbcode :String) -> String:
	_rtf.clear()
	_rtf.parse_bbcode(bbcode)
	return _rtf.text

static func to_type(type :int) -> String:
	match type:
		GdUnitReport.SUCCESS:
			return "SUCCESS"
		GdUnitReport.WARN:
			return "WARN"
		GdUnitReport.FAILURE:
			return "FAILURE"
		GdUnitReport.ORPHAN:
			return "ORPHAN"
		GdUnitReport.TERMINATED:
			return "TERMINATED"
		GdUnitReport.INTERUPTED:
			return "INTERUPTED"
		GdUnitReport.ABORT:
			return "ABORT"
	return "UNKNOWN"

static func to_time(duration :int) -> String:
	return "%4.03f" % (duration / 1000.0)

static func to_ISO8601_datetime(date :Dictionary) -> String:
	return "%04d-%02d-%02dT%02d:%02d:%02d" % [date["year"], date["month"], date["day"],  date["hour"], date["minute"], date["second"]]
