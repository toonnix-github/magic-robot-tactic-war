extends RefCounted

static func check() -> Array[String]:
	var failures: Array[String] = []
	var view = load("res://src/ui/fantasy_paper_doll.gd").new()
	if not view.has_method("art_transform"):
		failures.append("Equipment must register source landmarks to body sockets")
		view.free()
		return failures
	# Measured independently from the original raster atlas, in atlas pixels.
	var grips := {"sword": Vector2(1024,678), "bow": Vector2(66,1093), "staff": Vector2(409,1080), "axe": Vector2(1039,1094), "shield": Vector2(848,1060)}
	for weapon in grips:
		var transform: Transform2D = view.art_transform(weapon)
		var expected := Vector2(244.80, 233.21) if weapon == "shield" else Vector2(116.29, 233.21)
		if (transform * (grips[weapon] - view.REGIONS[weapon].position)).distance_to(expected) > 0.5:
			failures.append("%s grip must meet the hand" % weapon)
		if absf(transform.x.length() - transform.y.length()) > 0.001:
			failures.append("%s must preserve image proportions" % weapon)
	if view.art_transform("sword").get_rotation() <= 0.05:
		failures.append("Sword must point outward from the resting hand")
	if view.art_transform("staff").get_rotation() >= -0.05:
		failures.append("Staff must lean outward rather than cross the body")
	var collars := {"plate": Vector2(470,68), "leather": Vector2(785,73), "robe": Vector2(1098,56)}
	var waists := {"plate": Vector2(470,185), "leather": Vector2(785,190), "robe": Vector2(1098,175)}
	for armor in collars:
		var transform: Transform2D = view.art_transform(armor)
		if (transform * (collars[armor] - view.REGIONS[armor].position)).distance_to(Vector2(177.71,99.13)) > 0.5:
			failures.append("%s collar must meet the neck" % armor)
		if (transform * (waists[armor] - view.REGIONS[armor].position)).distance_to(Vector2(177.71,193.42)) > 0.5:
			failures.append("%s waist must meet the body waist" % armor)
	view.free()
	return failures
