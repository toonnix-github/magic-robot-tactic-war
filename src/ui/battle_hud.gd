extends RefCounted
class_name BattleHud

func short_part_name(part_name: String) -> String:
	if part_name == "Left Arm":
		return "L Arm"
	if part_name == "Right Arm":
		return "R Arm"
	return part_name
