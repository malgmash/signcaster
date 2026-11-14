extends RefCounted
## Reads tables and lists from the docs/ folder so tests can check code against the docs.
##
## Tests run from a repo checkout, where docs/ sits next to game/.

const DOCS_DIR: String = "../docs"


## The lines of [param file_name] in docs/, or an empty array if it cannot be read.
static func read_doc_lines(file_name: String) -> PackedStringArray:
	var game_dir: String = ProjectSettings.globalize_path("res://")
	var path: String = game_dir.path_join(DOCS_DIR).path_join(file_name).simplify_path()
	if not FileAccess.file_exists(path):
		return PackedStringArray()
	return FileAccess.get_file_as_string(path).split("\n")


## Table rows under the "## " heading that starts with [param heading_start].
## Only rows whose first cell is in backticks are kept. Backticks are removed from every cell.
static func code_rows(lines: PackedStringArray, heading_start: String) -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	var inside: bool = false
	for line: String in lines:
		if line.begins_with("## "):
			inside = line.trim_prefix("## ").begins_with(heading_start)
			continue
		if not inside or not line.begins_with("|"):
			continue
		var cells: PackedStringArray = []
		for cell: String in line.split("|").slice(1, -1):
			cells.append(cell.strip_edges())
		if cells.is_empty() or not cells[0].begins_with("`"):
			continue
		for i: int in cells.size():
			cells[i] = cells[i].replace("`", "")
		rows.append(cells)
	return rows


## Names in backticks from the numbered list under the heading [param heading], in order.
static func numbered_items(lines: PackedStringArray, heading: String) -> PackedStringArray:
	var items: PackedStringArray = []
	var pattern: RegEx = RegEx.create_from_string("^\\d+\\.\\s+`(\\w+)`")
	var inside: bool = false
	for line: String in lines:
		if line.begins_with("#"):
			inside = line.strip_edges() == heading
			continue
		var found: RegExMatch = pattern.search(line) if inside else null
		if found != null:
			items.append(found.get_string(1))
	return items


## Formats argument info from Godot ("name" and "type") the way the docs write it.
## A leading underscore is dropped: it only marks a stub parameter that is not used yet.
static func format_args(args: Array) -> String:
	var parts: PackedStringArray = []
	for arg: Dictionary in args:
		var arg_name: String = arg["name"]
		parts.append("%s: %s" % [arg_name.trim_prefix("_"), type_string(arg["type"])])
	return ", ".join(parts)
