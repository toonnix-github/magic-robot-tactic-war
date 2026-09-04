extends RefCounted
class_name GameData

const PROTOTYPE_VERSION := "0.1"
const GRID_COLUMNS := 10
const GRID_ROWS := 7
const MOVE_RANGE := 3
const PRIMARY_ACTIONS := ["Move", "Attack", "Wait"]
const PART_NAMES := ["Head", "Body", "Left Arm", "Right Arm", "Legs"]
const DIRECTIONS := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
