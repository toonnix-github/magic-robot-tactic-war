extends RefCounted


static func check(view: Control, build: Dictionary) -> Array[String]:
	var failures: Array[String] = []
	var original_size := view.size
	# Coordinates measured on the actual standalone PNGs, independent of the manifest.
	var anchors := {"Right Arm": Vector2(312.0 / 336.0, 232.0 / 1254.0), "Left Arm": Vector2(24.0 / 336.0, 232.0 / 1254.0)}
	var sockets := {"Right Arm": Vector2(0.018, 0.328), "Left Arm": Vector2(0.982, 0.328)}
	for viewport_size in [Vector2(600, 650), Vector2(446, 497), Vector2(280, 300)]:
		view.size = viewport_size
		view.show_build(build, "Body")
		var left_arm: TextureButton = view.buttons["Left Arm"]
		var right_arm: TextureButton = view.buttons["Right Arm"]
		if left_arm.size.distance_to(right_arm.size) > 0.01:
			failures.append("Aegis arm placement boxes must have identical dimensions")
		if absf(right_arm.size.x / right_arm.size.y - 1.0 / 3.0) > 0.001:
			failures.append("Aegis arms must use the standard 1:3 ratio")
		for slot in anchors:
			var arm: TextureButton = view.buttons[slot]
			var body: TextureButton = view.buttons["Body"]
			var actual := visible_point(arm, anchors[slot])
			var expected := visible_point(body, sockets[slot])
			if actual.distance_to(expected) > 0.5:
				failures.append("Aegis %s shoulder gap %.2f px at %s" % [slot, actual.distance_to(expected), viewport_size])
			if arm.stretch_mode != TextureButton.STRETCH_KEEP_ASPECT_CENTERED:
				failures.append("Aegis arm must retain its image proportions")
	var aegis_body_size: Vector2 = view.buttons["Body"].size
	var body_swap := build.duplicate(true)
	body_swap["parts"]["Body"] = "bulwark_body"
	view.show_build(body_swap, "Body", true)
	if view.buttons["Body"].size.distance_to(aegis_body_size) > 0.01:
		failures.append("Changing the body part must preserve its dimensions")
	view.size = original_size
	view.show_build(build, "Body")
	return failures


static func visible_point(button: TextureButton, uv: Vector2) -> Vector2:
	var image_size := button.texture_normal.get_size()
	var scale := minf(button.size.x / image_size.x, button.size.y / image_size.y)
	var drawn_size := image_size * scale
	return button.position + (button.size - drawn_size) * 0.5 + drawn_size * uv
