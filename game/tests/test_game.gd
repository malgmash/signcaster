extends GutTest
## Game must match docs/EVENTS.md, "Public methods on Game": same methods, arguments and returns.

const DocTables = preload("res://tests/helpers/doc_tables.gd")
const METHODS_HEADING: String = "Public methods on"

## Method name to its signature as written in the doc, like "(mode: String) -> void".
var _documented: Dictionary = {}
## The same, built from the public methods Game actually has.
var _declared: Dictionary = {}
## Doc rows that did not look like "name(args) -> type".
var _unreadable_rows: PackedStringArray = []


func before_all() -> void:
	var pattern: RegEx = RegEx.create_from_string("^(\\w+)\\((.*)\\)\\s*->\\s*(\\w+)$")
	var lines: PackedStringArray = DocTables.read_doc_lines("EVENTS.md")
	for cells: PackedStringArray in DocTables.code_rows(lines, METHODS_HEADING):
		var found: RegExMatch = pattern.search(cells[0])
		if found == null:
			_unreadable_rows.append(cells[0])
			continue
		_documented[found.get_string(1)] = (
			"(%s) -> %s" % [found.get_string(2), found.get_string(3)]
		)
	var script: Script = Game.get_script()
	for info: Dictionary in script.get_script_method_list():
		var method_name: String = info["name"]
		if method_name.begins_with("_") or method_name.begins_with("@"):
			continue
		var return_type: String = type_string(info["return"]["type"])
		if return_type == "Nil":
			return_type = "void"
		_declared[method_name] = "(%s) -> %s" % [DocTables.format_args(info["args"]), return_type]


func test_methods_were_read_from_the_doc() -> void:
	assert_gt(_documented.size(), 0, "No Game methods read from docs/EVENTS.md.")
	assert_eq(_unreadable_rows, PackedStringArray(), "These EVENTS.md rows could not be read")


func test_every_documented_method_exists_with_the_same_signature() -> void:
	for method_name: String in _documented:
		if not _declared.has(method_name):
			fail_test("Game is missing the method '%s' from EVENTS.md" % method_name)
			continue
		assert_eq(
			_declared[method_name],
			_documented[method_name],
			"Signature of Game.%s differs from EVENTS.md" % method_name
		)


func test_game_has_no_undocumented_public_methods() -> void:
	for method_name: String in _declared:
		assert_true(
			_documented.has(method_name),
			"Game.%s is public but not in EVENTS.md. Document it or make it private." % method_name
		)
