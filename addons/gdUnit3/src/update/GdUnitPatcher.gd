class_name GdUnitPatcher
extends RefCounted


const _base_dir := "res://addons/gdUnit3/src/update/patches/"

var _patches := Dictionary()

func scan(current :GdUnit3Version) -> void:
	_scan(_base_dir, current)

func _scan(scan_path :String, current :GdUnit3Version) -> void:
	_patches = Dictionary()
	var patch_paths := _collect_patch_versions(scan_path, current)
	for path in patch_paths:
		prints("scan for patches on '%s'" % path)
		_patches[path] = _scan_patches(path)

func patch_count() -> int:
	var count := 0
	for key in _patches.keys():
		count += _patches[key].size()
	return count

func execute() -> void:
	for key in _patches.keys():
		var patch_root :String = key
		for path in _patches[key]:
			var patch :GdUnitPatch = load(patch_root + "/" + path).new()
			if patch:
				prints("execute patch", patch.version(), patch.get_script().resource_path)
				if not patch.execute():
					prints("error on execution patch %s" % patch_root + "/" + path)

func _collect_patch_versions(scan_path :String, current :GdUnit3Version) -> PackedStringArray:
	var patches := Array()
	var dir := DirAccess.new()
	if not dir.dir_exists(scan_path):
		return PackedStringArray()
	if dir.open(scan_path) == OK:
		dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var next := "."
		while next != "":
			next = dir.get_next()
			if next.is_empty() or next == "." or next == "..":
				continue
			var version := GdUnit3Version.parse(next)
			if version.is_greater(current):
				patches.append(scan_path + next)
	patches.sort()
	return PackedStringArray(patches)

func _scan_patches(path :String) -> PackedStringArray:
	var patches := Array()
	var dir := DirAccess.new()
	if dir.open(path) == OK:
		dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var next := "."
		while next != "":
			next = dir.get_next()
			if next.is_empty() or next == "." or next == "..":
				continue
			patches.append(next)
	# make sorted from lowest to high version
	patches.sort()
	return PackedStringArray(patches)
