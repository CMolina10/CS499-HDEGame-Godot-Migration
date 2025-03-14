class_name GdUnitByPathReport
extends GdUnitReportSummary

func _init(path :String, reports :Array):
	_resource_path = path
	_reports = reports

static func sort_reports_by_path(reports :Array) -> Dictionary:
	var by_path := Dictionary()
	for report in reports:
		var suite_path :String = report.path()
		var suite_report :Array = by_path.get(suite_path, Array())
		suite_report.append(report)
		by_path[suite_path] = suite_report
	return by_path

func path() -> String:
	return _resource_path.replace("res://", "")

func create_record(report_link :String) -> String:
	return GdUnitHtmlPatterns.build(GdUnitHtmlPatterns.TABLE_RECORD_PATH, self, report_link)

func write(report_dir :String) -> String:
	var template := GdUnitHtmlPatterns.load_template("res://addons/gdUnit3/src/report/template/folder_report.html")
	var path_report := GdUnitHtmlPatterns.build(template, self, "")
	path_report = apply_testsuite_reports(report_dir, path_report, _reports)
	
	var output_path := "%s/path/%s.html" % [report_dir, path().replace("/", ".")]
	var dir := output_path.get_base_dir()
	var dest_dir := DirAccess.new()
	if not dest_dir.dir_exists(dir):
		dest_dir.make_dir_recursive(dir)
	
	var file := File.new()
	file.open(output_path, File.WRITE)
	file.store_string(path_report)
	file.close()
	return output_path

static func apply_testsuite_reports(report_dir :String, template :String, reports :Array) -> String:
	var table_records := PackedStringArray()
	
	for report in reports:
		var report_link = report.output_path(report_dir).replace(report_dir, "..")
		table_records.append(report.create_record(report_link))
	return template.replace(GdUnitHtmlPatterns.TABLE_BY_TESTSUITES, "\n".join(table_records))
