extends Control
## Static artwork composition. All build rules and bonuses belong to the model.

const ATLAS := preload("res://assets/fantasy/equipment-atlas.png")
const REGIONS := {
	"base": Rect2(77, 0, 153, 345),
	"plate": Rect2(367, 47, 205, 210),
	"leather": Rect2(686, 55, 201, 205),
	"robe": Rect2(992, 39, 224, 289),
	"helm": Rect2(98, 352, 107, 153),
	"circlet": Rect2(397, 397, 150, 76),
	"hat": Rect2(675, 333, 219, 174),
	"red_cape": Rect2(967, 342, 262, 281),
	"green_cape": Rect2(28, 636, 262, 266),
	"steel_boots": Rect2(373, 720, 198, 184),
	"leather_boots": Rect2(678, 722, 206, 178),
	"sword": Rect2(979, 628, 91, 274),
	"bow": Rect2(49, 897, 81, 347),
	"staff": Rect2(376, 896, 74, 348),
	"shield": Rect2(776, 942, 159, 255),
	"axe": Rect2(995, 912, 130, 305),
}
const PLACEMENTS := {
	"base": Rect2(89, 23, 174, 392),
	"plate": Rect2(105, 95, 144, 147),
	"leather": Rect2(105, 95, 144, 147),
	"robe": Rect2(88, 93, 178, 283),
	"helm": Rect2(148, 25, 58, 83),
	"circlet": Rect2(148, 44, 58, 29),
	"hat": Rect2(125, 0, 104, 83),
	"red_cape": Rect2(74, 92, 208, 285),
	"green_cape": Rect2(74, 92, 208, 285),
	"steel_boots": Rect2(98, 310, 155, 109),
	"leather_boots": Rect2(98, 310, 155, 109),
	"sword": Rect2(77, 193, 48, 220),
	"bow": Rect2(62, 106, 69, 300),
	"staff": Rect2(74, 49, 64, 367),
	"shield": Rect2(225, 176, 91, 146),
	"axe": Rect2(66, 156, 71, 257),
}
var layers: Dictionary = {}
var fairy: Dictionary = {}

func show_build(equipment: Dictionary, catalog: Dictionary) -> void:
	layers.clear()
	for slot in equipment:
		layers[slot] = catalog.items.get(equipment[slot], {}).get("art", "")
	fairy = catalog.fairies.get(equipment.get("fairy", ""), {})
	queue_redraw()

func _draw() -> void:
	var factor := minf(size.x / 350.0, size.y / 435.0)
	var offset := (size - Vector2(350, 435) * factor) * 0.5
	draw_set_transform(offset, 0, Vector2.ONE * factor)
	draw_circle(Vector2(175, 210), 149, Color("253533"))
	draw_arc(Vector2(175, 210), 151, 0, TAU, 80, Color("71684c"), 1.0, true)
	draw_arc(Vector2(175, 210), 159, 0.2, 2.7, 40, Color("434b40"), 1.0, true)
	draw_style_box(shadow_style(), Rect2(87, 400, 183, 20))
	draw_layer(layers.get("cape", ""))
	draw_layer("base")
	for slot in ["armor", "shoes", "headgear", "right_hand", "left_hand"]:
		draw_layer(layers.get(slot, ""))
	if not fairy.is_empty():
		draw_fairy(Vector2(285, 102), Color(fairy.color), fairy.shape)
	draw_set_transform(Vector2.ZERO)

func shadow_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.23)
	style.set_corner_radius_all(12)
	return style

func draw_layer(art: String) -> void:
	if REGIONS.has(art):
		draw_texture_rect_region(ATLAS, PLACEMENTS[art], REGIONS[art])

func draw_fairy(center: Vector2, color: Color, shape: String) -> void:
	for radius in [27, 20, 14]:
		draw_circle(center, radius, Color(color, 0.09))
	match shape:
		"diamond":
			draw_colored_polygon(PackedVector2Array([center + Vector2(0,-12), center + Vector2(8,0), center + Vector2(0,12), center + Vector2(-8,0)]), color)
		"square":
			draw_rect(Rect2(center - Vector2(8,8), Vector2(16,16)), color)
		"star":
			for angle in [0.0, PI / 3, 2 * PI / 3]:
				draw_line(center - Vector2.from_angle(angle)*12, center + Vector2.from_angle(angle)*12, color, 4, true)
		"flower":
			for i in 5:
				draw_circle(center + Vector2.from_angle(i * TAU / 5) * 7, 5, color)
		"flame", "drop":
			draw_circle(center + Vector2(0,3), 8, color)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-7,2), center + Vector2(0,-14), center + Vector2(7,2)]), color)
	draw_circle(center, 4, Color("fff8dc"))
