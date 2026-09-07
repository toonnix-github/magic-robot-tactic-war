extends RefCounted
## Owns fantasy preparation state only. No dependency on mech simulation.

const CATALOG_PATH := "res://data/fantasy/build_catalog.json"
const SAVE_PATH := "user://fantasy_builds_v1.json"
const ORDERS := ["Follow Job", "Stay Safe"]
var catalog: Dictionary
var party: Array = []

func _init() -> void:
	catalog = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	reset()

func reset() -> void:
	party.clear()
	for job in catalog.jobs:
		party.append({"job": job, "level": 1, "order": ORDERS[0], "equipment": catalog.jobs[job].equipment.duplicate(true)})

func item(item_id: String) -> Dictionary:
	if catalog.items.has(item_id):
		return catalog.items[item_id]
	return catalog.fairies.get(item_id, {})

func fairy_owner(item_id: String) -> int:
	if item_id.is_empty():
		return -1
	for index in party.size():
		if party[index].equipment.fairy == item_id:
			return index
	return -1

func can_equip(hero: int, slot: String, item_id: String) -> bool:
	if hero < 0 or hero >= party.size() or not catalog.slots.has(slot):
		return false
	if item_id.is_empty():
		return true
	var entry := item(item_id)
	if entry.is_empty():
		return false
	var category: String = "accessory" if slot.begins_with("accessory_") else slot
	if entry.slot != category or not party[hero].job in entry.jobs:
		return false
	if slot == "left_hand" and int(item(party[hero].equipment.right_hand).get("hands", 1)) == 2:
		return false
	return true

func candidates(hero: int, slot: String) -> Array[String]:
	var result: Array[String] = []
	var source: Dictionary = catalog.fairies if slot == "fairy" else catalog.items
	for key in source:
		if can_equip(hero, slot, key):
			result.append(key)
	return result

func equip(hero: int, slot: String, item_id: String, transfer := false) -> bool:
	if not can_equip(hero, slot, item_id):
		return false
	if slot == "fairy":
		var owner := fairy_owner(item_id)
		if owner >= 0 and owner != hero:
			if not transfer:
				return false
			party[owner].equipment.fairy = ""
	party[hero].equipment[slot] = item_id
	if slot == "right_hand" and int(item(item_id).get("hands", 1)) == 2:
		party[hero].equipment.left_hand = ""
	return true

func stats(hero: int, equipment: Dictionary = {}) -> Dictionary:
	var total: Dictionary = catalog.jobs[party[hero].job].stats.duplicate(true)
	var equipped: Dictionary = party[hero].equipment if equipment.is_empty() else equipment
	for slot in equipped:
		for stat in item(equipped[slot]).get("stats", {}):
			total[stat] = int(total.get(stat, 0)) + int(item(equipped[slot]).stats[stat])
	return total

func preview_stats(hero: int, slot: String, item_id: String) -> Dictionary:
	var equipped: Dictionary = party[hero].equipment.duplicate(true)
	if can_equip(hero, slot, item_id):
		equipped[slot] = item_id
		if slot == "right_hand" and int(item(item_id).get("hands", 1)) == 2:
			equipped.left_hand = ""
	return stats(hero, equipped)

func abilities(hero: int) -> Array[String]:
	var result: Array[String] = []
	for ability in catalog.jobs[party[hero].job].abilities:
		result.append(ability)
	for slot in party[hero].equipment:
		for ability in item(party[hero].equipment[slot]).get("abilities", []):
			if not ability in result:
				result.append(ability)
	return result

func set_order(hero: int, order: String) -> bool:
	if hero < 0 or hero >= party.size() or not order in ORDERS:
		return false
	party[hero].order = order
	return true

func save_to(path := SAVE_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": 1, "party": party}))
	return true

func load_from(path := SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var saved = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not saved is Dictionary or saved.get("version") != 1 or not saved.get("party") is Array or saved.party.size() != 5:
		return false
	reset()
	# Clear before assigning so defaults cannot falsely reserve a saved fairy.
	for hero in party:
		for slot in catalog.slots:
			hero.equipment[slot] = ""
	for index in party.size():
		var source = saved.party[index]
		if not source is Dictionary or not source.get("equipment") is Dictionary:
			continue
		for slot in catalog.slots:
			var value = source.equipment.get(slot, "")
			if value is String:
				equip(index, slot, value)
		var order = source.get("order", ORDERS[0])
		if order is String:
			set_order(index, order)
	return true
