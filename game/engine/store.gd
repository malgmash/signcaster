extends Node
## Store catalogs, purchases and equipped items. Items are cosmetic only.
##
## Stub until M8. See docs/DATA_FORMATS.md, "Store catalog".


## Every item in the catalog for [param _mode]. TODO(M8)
func get_catalog(_mode: String) -> Array[Dictionary]:
	return []


## Tries to buy [param _item_id]. Emits item_purchased or purchase_failed. TODO(M8)
func buy(_item_id: String) -> void:
	pass


## Equips an owned item in its slot. Emits item_equipped. TODO(M8)
func equip(_item_id: String) -> void:
	pass


## True if the player owns [param _item_id]. TODO(M8)
func is_owned(_item_id: String) -> bool:
	return false


## The item id equipped in [param _slot] for [param _mode], or "" if none. TODO(M8)
func get_equipped(_mode: String, _slot: String) -> String:
	return ""
