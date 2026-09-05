extends Control

const HangarScript := preload("res://src/ui/hangar_screen.gd")
const HangarEditorScript := preload("res://src/ui/hangar_editor.gd")
var hangar
var editor
var battle
var return_button := Button.new()


func _ready() -> void:
	hangar = HangarScript.new()
	hangar.visible = false
	add_child(hangar)
	editor = HangarEditorScript.new()
	add_child(editor)
	editor.setup(hangar)
	hangar.deploy_requested.connect(_deploy)
	return_button.text = "Result - Return to Hangar"
	return_button.position = Vector2(460, 90)
	return_button.size = Vector2(350, 44)
	return_button.visible = false
	return_button.pressed.connect(_return_to_hangar)
	add_child(return_button)


func _deploy(loadouts: Dictionary) -> void:
	if battle != null:
		return
	battle = load("res://scenes/main.tscn").instantiate()
	add_child(battle)
	battle._load_mission(editor.selected_mission_id, false)
	battle.configure_player_loadouts(loadouts)
	editor.hide()
	move_child(return_button, get_child_count() - 1)


func _process(_delta: float) -> void:
	return_button.visible = battle != null and battle._is_battle_over() and not battle._is_activating
	if return_button.visible:
		return_button.text = "%s - Return to Hangar" % ("Victory" if battle._battle_winner() == "player" else "Defeat")


func _return_to_hangar() -> void:
	if battle == null or not battle._is_battle_over():
		return
	battle.queue_free()
	battle = null
	return_button.hide()
	editor.refresh()
	editor.show()
