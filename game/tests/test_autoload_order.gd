extends GutTest
## The autoloads load in the order docs/ARCHITECTURE.md lists, because later ones use earlier ones.

const DocTables = preload("res://tests/helpers/doc_tables.gd")
const ORDER_HEADING: String = "### Autoload order"

var _expected: PackedStringArray = []


func before_all() -> void:
	_expected = DocTables.numbered_items(DocTables.read_doc_lines("ARCHITECTURE.md"), ORDER_HEADING)


func test_order_was_read_from_the_doc() -> void:
	assert_gt(_expected.size(), 0, "No autoloads read from ARCHITECTURE.md, '%s'." % ORDER_HEADING)


func test_every_listed_autoload_is_loaded() -> void:
	for autoload_name: String in _expected:
		assert_not_null(
			get_tree().root.get_node_or_null(autoload_name),
			"%s is listed in ARCHITECTURE.md but is not an autoload" % autoload_name
		)


func test_autoloads_load_in_the_documented_order() -> void:
	var last_index: int = -1
	var last_name: String = "(start)"
	for autoload_name: String in _expected:
		var node: Node = get_tree().root.get_node_or_null(autoload_name)
		if node == null:
			continue
		assert_gt(
			node.get_index(), last_index, "%s must load after %s" % [autoload_name, last_name]
		)
		last_index = node.get_index()
		last_name = autoload_name
