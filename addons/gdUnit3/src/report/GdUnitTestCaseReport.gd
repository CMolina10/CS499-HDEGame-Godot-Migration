class_name GdUnitTestCaseReport
extends GdUnitReportSummary

var _suite_name :String
var _failure_reports :Array
var _rtf :RichTextLabel

func _init(rtf :RichTextLabel, resource_path :String, suite_name :String, test_name :String, is_error := false, is_failed := false, orphans :int = 0, is_skipped := false, failure_reports :Array = [], duration :int = 0):
	_rtf = rtf
	_resource_path = resource_path
	_suite_name = suite_name
	_name = test_name
	_test_count = 1
	_error_count = is_error
	_failure_count = is_failed
	_orphan_count = orphans
	_skipped_count = is_skipped
	_failure_reports = failure_reports
	_duration = duration

func suite_name() -> String:
	return _suite_name

func failure_report() -> String:
	var html_report := ""
	for r in _failure_reports:
		var report: GdUnitReport = r
		# TODO convert rtf to html
		html_report += convert_rtf_to_text(report._to_string())
	return html_report

func convert_rtf_to_text(bbcode :String) -> String:
	_rtf.clear()
	_rtf.parse_bbcode(bbcode)
	var as_text: = _rtf.text
	var converted := PackedStringArray()
	var lines := as_text.split("\n")
	for line in lines:
		converted.append("<p>%s</p>" % line)
	return "\n".join(converted)

func create_record(report_dir :String) -> String:
	return GdUnitHtmlPatterns.TABLE_RECORD_TESTCASE\
		super.replace(GdUnitHtmlPatterns.REPORT_STATE, report_state())\
		super.replace(GdUnitHtmlPatterns.TESTCASE_NAME, name())\
		super.replace(GdUnitHtmlPatterns.SKIPPED_COUNT, str(skipped_count()))\
		super.replace(GdUnitHtmlPatterns.ORPHAN_COUNT, str(orphan_count()))\
		super.replace(GdUnitHtmlPatterns.DURATION, LocalTime.elapsed(_duration))\
		super.replace(GdUnitHtmlPatterns.FAILURE_REPORT, failure_report())

func update(report :GdUnitTestCaseReport) -> void:
	_error_count += report.error_count()
	_failure_count += report.failure_count()
	_orphan_count += report.orphan_count()
	_skipped_count += report.skipped_count()
	_failure_reports += report._failure_reports
	_duration += report.duration()
