extends RefCounted

## Presentation-only atlas, silhouette and attachment data. Never owns build state.
const ROOT := "res://assets/hangar/detailed/"
var modules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "modules.json"))
var textures: Dictionary = {}
var materials: Dictionary = {}
var shader := Shader.new()


func _init() -> void:
	shader.code = FileAccess.get_file_as_string(ROOT + "silhouette.gdshader")


func has_art(slot: String, part_id: String) -> bool:
	var family := part_id.get_slice("_", 0)
	return modules.has(family) and modules[family].has(slot)


func _part_file_path(family: String, slot: String) -> String:
	var output_path := "res://output/hangar-art-sample-v1/%s_%s.png" % [family, slot.to_lower().replace(" ", "_")]
	if FileAccess.file_exists(output_path):
		return output_path
	var profile: Dictionary = modules.get(family, {}).get(slot, {})
	var file_path := str(profile.get("file", ""))
	if not file_path.is_empty() and FileAccess.file_exists(file_path):
		return file_path
	return ""


func texture_for(slot: String, part_id: String) -> Texture2D:
	var key := part_id + ":" + slot
	if not textures.has(key):
		var family := part_id.get_slice("_", 0)
		var custom_file := _part_file_path(family, slot)
		if not custom_file.is_empty():
			textures[key] = image_texture(custom_file)
		else:
			var profile: Dictionary = modules[family][slot]
			var atlas := AtlasTexture.new()
			atlas.atlas = image_texture(ROOT + family + ".png")
			var region: Array = profile["region"]
			atlas.region = Rect2(region[0], region[1], region[2], region[3])
			atlas.filter_clip = true
			textures[key] = atlas
	return textures[key]


func image_texture(path: String) -> Texture2D:
	if not textures.has(path):
		# Use imported resources in the editor/export; clean headless CI has no import cache.
		var config := ConfigFile.new()
		var imported := ""
		if config.load(path + ".import") == OK:
			imported = str(config.get_value("remap", "path", ""))
		if not imported.is_empty() and FileAccess.file_exists(imported):
			textures[path] = load(path)
		else:
			var bitmap := Image.new()
			bitmap.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
			textures[path] = ImageTexture.create_from_image(bitmap)
	return textures[path]


func material_for(slot: String, part_id: String) -> ShaderMaterial:
	var family := part_id.get_slice("_", 0)
	if not _part_file_path(family, slot).is_empty():
		return null
	var key := part_id + ":" + slot
	if not materials.has(key):
		var profile: Dictionary = modules[family][slot]
		var mask := Image.new()
		mask.load_svg_from_string(FileAccess.get_file_as_string(profile["mask"]))
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("silhouette", ImageTexture.create_from_image(mask))
		var atlas: AtlasTexture = texture_for(slot, part_id)
		material.set_shader_parameter("uv_offset", atlas.region.position / atlas.atlas.get_size())
		material.set_shader_parameter("uv_scale", atlas.region.size / atlas.atlas.get_size())
		materials[key] = material
	return materials[key]


func rect_for(slot: String, part_id: String, body_id: String = "") -> Rect2:
	var profile: Dictionary = modules[part_id.get_slice("_", 0)][slot]
	var values: Array = profile["rect"]
	var rect := Rect2(values[0], values[1], values[2], values[3])
	if slot == "Body" or not has_art("Body", body_id):
		return rect
	var body: Dictionary = modules[body_id.get_slice("_", 0)]["Body"]
	var body_rect := rect_for("Body", body_id)
	# Standalone Aegis shoulders use coordinates on the cleaned PNGs. Match the
	# TextureButton's centered aspect fit so transparent/control padding cannot
	# separate the visible joints. Other parts retain their existing registration.
	if profile.has("image_anchor") and body.get("image_sockets", {}).has(slot):
		if not _part_file_path(part_id.get_slice("_", 0), slot).is_empty() and not _part_file_path(body_id.get_slice("_", 0), "Body").is_empty():
			var arm_image := _fitted_image_rect(rect, texture_for(slot, part_id).get_size())
			var body_image := _fitted_image_rect(body_rect, texture_for("Body", body_id).get_size())
			var image_anchor: Array = profile["image_anchor"]
			var image_socket: Array = body["image_sockets"][slot]
			var arm_point := arm_image.position + arm_image.size * Vector2(image_anchor[0], image_anchor[1])
			var body_point := body_image.position + body_image.size * Vector2(image_socket[0], image_socket[1])
			rect.position += body_point - arm_point
			return rect
	var region: Array = profile["region"]
	var body_region: Array = body["region"]
	var anchor: Array = profile["anchor"]
	var socket: Array = body["sockets"][slot]
	var target := body_rect.position + (Vector2(socket[0], socket[1]) - Vector2(body_region[0], body_region[1])) * body_rect.size / Vector2(body_region[2], body_region[3])
	var offset := (Vector2(anchor[0], anchor[1]) - Vector2(region[0], region[1])) * rect.size / Vector2(region[2], region[3])
	rect.position = target - offset
	return rect


func _fitted_image_rect(rect: Rect2, image_size: Vector2) -> Rect2:
	var scale := minf(rect.size.x / image_size.x, rect.size.y / image_size.y)
	var drawn_size := image_size * scale
	return Rect2(rect.position + (rect.size - drawn_size) * 0.5, drawn_size)
