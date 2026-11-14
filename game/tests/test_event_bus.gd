extends GutTest
## EventBus must match docs/EVENTS.md exactly: same signals, argument names and types.

const DocTables = preload("res://tests/helpers/doc_tables.gd")
const SIGNAL_SECTIONS: PackedStringArray = [
	"Session and level", "Challenge lifecycle", "Economy and store", "Tracker and system"
]

## Signal name to its arguments as written in the doc, like "mode: String, skin_id: String".
var _documented: Dictionary = {}
## The same, built from the signals EventBus actually declares.
var _declared: Dictionary = {}


func before_all() -> void:
	var lines: PackedStringArray = DocTables.read_doc_lines("EVENTS.md")
	for section: String in SIGNAL_SECTIONS:
		for cells: PackedStringArray in DocTables.code_rows(lines, section):
			_documented[cells[0]] = cells[1]
	var script: Script = EventBus.get_script()
	for info: Dictionary in script.get_script_signal_list():
		_declared[info["name"]] = DocTables.format_args(info["args"])


func test_signals_were_read_from_the_doc() -> void:
	assert_gt(_documented.size(), 0, "No signals read from docs/EVENTS.md. Did its tables change?")


func test_every_documented_signal_exists_with_the_same_arguments() -> void:
	for signal_name: String in _documented:
		if not _declared.has(signal_name):
			fail_test("EventBus is missing the signal '%s' from EVENTS.md" % signal_name)
			continue
		assert_eq(
			_declared[signal_name],
			_documented[signal_name],
			"Arguments of '%s' differ from EVENTS.md" % signal_name
		)


func test_eventbus_has_no_undocumented_signals() -> void:
	for signal_name: String in _declared:
		assert_true(
			_documented.has(signal_name),
			"EventBus signal '%s' is not in EVENTS.md. Document it there." % signal_name
		)
