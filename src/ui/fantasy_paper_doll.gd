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
	"helm": Rect2(148, 25, 58, 83),
	"circlet": Rect2(148, 44, 58, 29),
	"hat": Rect2(125, 0, 104, 83),
	"red_cape": Rect2(74, 92, 208, 285),
	"green_cape": Rect2(74, 92, 208, 285),
	"steel_boots": Rect2(98, 310, 155, 109),
	"leather_boots": Rect2(98, 310, 155, 109),
}
var layers: Dictionary = {}
var fairy: Dictionary = {}
const HAND_RIGHT := Vector2(116.29, 233.21)
const HAND_LEFT := Vector2(244.80, 233.21)
const NECK := Vector2(177.71, 99.13)
const WAIST := Vector2(177.71, 193.42)
# Source grip coordinates are measured on the atlas, not the cropped rectangle.
const GRIPS := {"sword": Vector2(1024,678), "bow": Vector2(66,1093), "staff": Vector2(409,1080), "axe": Vector2(1039,1094), "shield": Vector2(848,1060)}
# Uniform image scale and rotation in degrees; the grip is the rotation pivot.
const WEAPON_STYLE := {"sword": Vector2(0.78, 10), "bow": Vector2(0.86, -18), "staff": Vector2(0.88, -10), "axe": Vector2(0.78, -6), "shield": Vector2(0.55, 0)}
const ARMOR_FIT := {
	"plate": {"collar": Vector2(470,68), "waist": Vector2(470,185), "width_scale": 0.69},
	"leather": {"collar": Vector2(785,73), "waist": Vector2(785,190), "width_scale": 0.62},
	"robe": {"collar": Vector2(1098,56), "waist": Vector2(1098,175), "width_scale": 0.73},
}
var canvas_transform := Transform2D.IDENTITY

func art_transform(art: String) -> Transform2D:
	if GRIPS.has(art):
		var style: Vector2 = WEAPON_STYLE[art]
		var transform := Transform2D(deg_to_rad(style.y), Vector2.ONE * style.x, 0, Vector2.ZERO)
		var target: Vector2 = HAND_LEFT if art == "shield" else HAND_RIGHT
		transform.origin = target - transform * (GRIPS[art] - REGIONS[art].position)
		return transform
	if ARMOR_FIT.has(art):
		var fit: Dictionary = ARMOR_FIT[art]
		var scale_y: float = (WAIST.y - NECK.y) / (fit.waist.y - fit.collar.y)
		var transform := Transform2D(0, Vector2(fit.width_scale, scale_y), 0, Vector2.ZERO)
		transform.origin = NECK - transform * (fit.collar - REGIONS[art].position)
		return transform
	return Transform2D(0, PLACEMENTS[art].size / REGIONS[art].size, 0, PLACEMENTS[art].position)

func show_build(equipment: Dictionary, catalog: Dictionary) -> void:
	layers.clear()
	for slot in equipment:
		layers[slot] = catalog.items.get(equipment[slot], {}).get("art", "")
	fairy = catalog.fairies.get(equipment.get("fairy", ""), {})
	queue_redraw()

func _draw() -> void:
	var factor := minf(size.x / 350.0, size.y / 435.0)
	var offset := (size - Vector2(350, 435) * factor) * 0.5
	canvas_transform = Transform2D(0, Vector2.ONE * factor, 0, offset)
	draw_set_transform_matrix(canvas_transform)
	draw_circle(Vector2(175, 210), 149, Color("253533"))
	draw_arc(Vector2(175, 210), 151, 0, TAU, 80, Color("71684c"), 1.0, true)
	draw_arc(Vector2(175, 210), 159, 0.2, 2.7, 40, Color("434b40"), 1.0, true)
	draw_style_box(shadow_style(), Rect2(87, 400, 183, 20))
	draw_layer(layers.get("cape", ""))
	draw_layer("base")
	for slot in ["armor", "shoes", "headgear", "right_hand", "left_hand"]:
		draw_layer(layers.get(slot, ""))
	if not layers.get("right_hand", "").is_empty():
		draw_gripping_hand()
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
		var source: Rect2 = REGIONS[art]
		var transform := art_transform(art)
		draw_set_transform_matrix(canvas_transform * transform)
		if art == "robe":
			# Fit the upper garment to the torso; extend only the skirt below its belt.
			var split: float = ARMOR_FIT.robe.waist.y - source.position.y
			draw_texture_rect_region(ATLAS, Rect2(Vector2.ZERO, Vector2(source.size.x, split)), Rect2(source.position, Vector2(source.size.x, split)))
			var skirt_scale := (400.0 - WAIST.y) / (source.size.y - split)
			var skirt_transform := Transform2D(0, Vector2(transform.x.length(), skirt_scale), 0, Vector2(transform.origin.x, WAIST.y))
			draw_set_transform_matrix(canvas_transform * skirt_transform)
			draw_texture_rect_region(ATLAS, Rect2(Vector2.ZERO, Vector2(source.size.x, source.size.y - split)), Rect2(source.position + Vector2(0, split), Vector2(source.size.x, source.size.y - split)))
		else:
			draw_texture_rect_region(ATLAS, Rect2(Vector2.ZERO, source.size), source)
		draw_set_transform_matrix(canvas_transform)

func draw_gripping_hand() -> void:
	# Foreground fingers/wrist conceal the grip, so the weapon reads as held.
	var source := Rect2(92, 170, 21, 31)
	var transform := art_transform("base")
	var destination := Rect2(transform * (source.position - REGIONS.base.position), source.size * transform.get_scale())
	draw_texture_rect_region(ATLAS, destination, source)

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
