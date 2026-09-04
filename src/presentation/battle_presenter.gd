extends RefCounted
class_name BattlePresenter

func present_enemy_activation(scene, unit, plan: Dictionary) -> void:
	if unit == null or not scene._is_unit_in_battle(unit):
		return
	if scene.fast_simulation:
		scene._resolve_planned_ai_activation_fast(unit, plan)
		return

	scene.enemy_presentation_active = true
	scene._is_activating = true
	scene.selected_unit = unit
	scene.active_unit = unit
	scene.last_action_message = "%s activates" % unit["name"]
	scene.enemy_presentation_log.append("%s:activate" % unit["id"])
	scene.queue_redraw()
	await scene.get_tree().create_timer(scene.ENEMY_ACTIVATION_HIGHLIGHT_SECONDS).timeout

	var path: Array = plan.get("path", [])
	for step in path:
		unit["grid"] = step
		scene.last_action_message = "%s moves" % unit["name"]
		scene.enemy_presentation_log.append("%s:presentation_move:(%d,%d)" % [unit["id"], step.x, step.y])
		scene.queue_redraw()
		await scene.get_tree().create_timer(scene.ENEMY_MOVE_STEP_SECONDS).timeout

	if not path.is_empty():
		unit["has_moved"] = true
		var final_grid: Vector2i = path[path.size() - 1]
		scene.turn_log.append("%s:move:(%d,%d)" % [unit["id"], final_grid.x, final_grid.y])
		scene.reachable_tiles.clear()
		scene.targetable_tiles.clear()
		scene.target_preview.clear()
		scene.turn_state = scene.TurnState.MOVE_COMPLETE

	var attacked: bool = false
	if str(plan.get("action", "")) == "Attack" and plan.get("target") != null and scene._can_attack(unit):
		var sim_seed: int = scene._next_simulation_seed()
		var preview: Dictionary = scene._attack_preview(unit, plan["target"])
		if bool(preview["legal"]):
			var attack_res: Dictionary = scene._resolve_attack_result(unit, plan["target"], preview, "", sim_seed)
			if scene.attack_presentation_enabled:
				await present_attack_feedback(scene, unit, plan["target"], attack_res)
			scene._finish_activation(unit)
			attacked = true

	if not attacked and scene._is_unit_in_battle(unit):
		unit["activation_complete"] = true
		scene.turn_log.append("%s:enemy_wait" % unit["id"])
		scene.last_action_message = "%s holds position" % unit["name"]
		scene._finish_activation(unit)

	scene.enemy_presentation_active = false
	scene._is_activating = false
	scene.queue_redraw()
	if not scene._is_battle_over():
		scene._begin_next_activation()


func present_attack_feedback(scene, attacker, target, result: Dictionary) -> void:
	if not scene.attack_presentation_enabled or scene.fast_simulation:
		return

	scene.attack_presentation_active = true
	scene.attack_feedback_attacker_id = str(attacker["id"]) if attacker != null else ""
	scene.attack_feedback_target_id = str(target["id"]) if target != null else ""
	scene.attack_feedback_queue = build_attack_feedback_sequence(
		attacker,
		target,
		result,
		Callable(scene, "_unit_name_for_id"),
		Callable(scene, "_unit_by_id")
	)

	for line in scene.attack_feedback_queue:
		scene.last_action_message = line
		scene.attack_feedback_log.append(line)
		apply_attack_feedback_line(scene, target, line)
		scene.queue_redraw()
		await scene.get_tree().create_timer(scene.attack_feedback_step_seconds).timeout

	scene.attack_feedback_queue.clear()
	scene.attack_feedback_attacker_id = ""
	scene.attack_feedback_target_id = ""
	scene.attack_presentation_active = false
	scene.queue_redraw()


func apply_attack_feedback_line(scene, target, line: String) -> void:
	if line.contains(" -> "):
		var parts: PackedStringArray = line.split(" -> ")
		var attacker_info: PackedStringArray = parts[0].split(" / ")
		if attacker_info.size() == 2:
			scene._add_event_message("%s attacks %s with %s" % [attacker_info[0].strip_edges(), parts[1].strip_edges(), attacker_info[1].strip_edges()])
	elif line.contains("MISS"):
		var miss_target = target if target != null else scene._unit_by_id(scene.attack_feedback_target_id)
		if miss_target != null:
			scene._add_floating_text(miss_target["grid"], "MISS", Color.WHITE)
		scene._add_event_message("Missed!", 2.0)
	elif line.contains("HIT / ") or line.contains("SHIELD INTERCEPT / "):
		var split_idx: int = line.find("HIT / ")
		if split_idx == -1:
			split_idx = line.find("SHIELD INTERCEPT / ")
		var payload: String = line.substr(split_idx).split(" / ")[1]
		var dmg_idx: int = payload.rfind("-")
		if dmg_idx != -1:
			var dmg_str: String = payload.substr(dmg_idx)
			var hit_target = target if target != null else scene._unit_by_id(scene.attack_feedback_target_id)
			if hit_target != null:
				scene._start_unit_shake(hit_target["id"])
				scene._add_floating_text(hit_target["grid"], dmg_str, Color(0.9, 0.3, 0.3))
				var target_name: String = str(hit_target.get("name", "Target"))
				var part_name: String = payload.substr(0, dmg_idx).strip_edges()
				scene._add_event_message("%s · %s %s" % [target_name, part_name, dmg_str])
	elif line.contains("DESTROYED") or line.contains("DEFEATED") or line.contains("BROKEN"):
		scene._add_event_message(line, 4.0)
	elif line.begins_with("ORB PROC / "):
		var proc: String = line.split(" / ")[1]
		var attacker_name: String = scene._unit_name_for_id(scene.attack_feedback_attacker_id)
		scene._add_event_message("%s triggered %s" % [attacker_name, proc])


func build_attack_feedback_sequence(attacker, target, result: Dictionary, unit_name_for_id: Callable, unit_by_id: Callable) -> Array[String]:
	var sequence: Array[String] = []
	var attacker_name: String = str(unit_name_for_id.call(str(result.get("attacker_id", ""))))
	if attacker != null:
		attacker_name = str(attacker["name"])
	var target_name: String = str(unit_name_for_id.call(str(result.get("original_target_id", result.get("target_id", "")))))
	if target != null:
		target_name = str(target["name"])
	sequence.append("%s / %s -> %s" % [attacker_name, str(result.get("weapon", "Attack")), target_name])

	if result.has("shots"):
		for shot in result["shots"]:
			sequence.append(attack_feedback_line(attacker, target, shot, unit_name_for_id, "SHOT %d" % int(shot.get("shot_index", 0))))
			append_attack_feedback_consequences(sequence, shot, unit_name_for_id)
	elif result.has("results"):
		for lane_result in result["results"]:
			sequence.append(attack_feedback_line(attacker, unit_by_id.call(str(lane_result.get("target_id", ""))), lane_result, unit_name_for_id, "TILE %d" % int(lane_result.get("tile_index", 0))))
			append_attack_feedback_consequences(sequence, lane_result, unit_name_for_id)
	else:
		sequence.append(attack_feedback_line(attacker, target, result, unit_name_for_id))
		append_attack_feedback_consequences(sequence, result, unit_name_for_id)

	return sequence


func attack_feedback_line(attacker, target, result: Dictionary, unit_name_for_id: Callable, label := "") -> String:
	var prefix: String = "%s / " % label if label != "" else ""
	if not bool(result.get("hit", false)):
		return "%sMISS" % prefix

	var part_name := str(result.get("part_name", "Part"))
	var damage := int(result.get("damage_applied", 0))
	if part_name == "Shield":
		var shield_name := str(unit_name_for_id.call(str(result.get("target_id", ""))))
		if bool(result.get("intercepted", false)):
			return "%sSHIELD INTERCEPT / %s Shield -%d" % [prefix, shield_name, damage]
		return "%sHIT / %s Shield -%d" % [prefix, shield_name, damage]
	return "%sHIT / %s -%d" % [prefix, part_name, damage]


func append_attack_feedback_consequences(sequence: Array[String], result: Dictionary, unit_name_for_id: Callable) -> void:
	if not bool(result.get("hit", false)):
		return

	var part_name := str(result.get("part_name", ""))
	if bool(result.get("destroyed_now", false)):
		if part_name == "Body":
			sequence.append("BODY DESTROYED / %s DEFEATED" % str(unit_name_for_id.call(str(result.get("target_id", "")))))
		elif part_name == "Shield":
			sequence.append("SHIELD BROKEN / %s" % str(unit_name_for_id.call(str(result.get("target_id", "")))))
		else:
			sequence.append("%s DESTROYED" % part_name.to_upper())

	var orb_proc: Dictionary = result.get("orb_proc", {})
	if bool(orb_proc.get("triggered", false)):
		sequence.append("ORB PROC / %s" % str(orb_proc.get("status", "")))

func process_feedback(event_feed_messages: Array, floating_texts: Array, unit_shakes: Dictionary, delta: float) -> bool:
	var needs_redraw: bool = false

	if event_feed_messages.size() > 0:
		for i in range(event_feed_messages.size() - 1, -1, -1):
			event_feed_messages[i]["time"] -= delta
			if event_feed_messages[i]["time"] <= 0:
				event_feed_messages.remove_at(i)
		needs_redraw = true

	if floating_texts.size() > 0:
		for i in range(floating_texts.size() - 1, -1, -1):
			floating_texts[i]["time"] -= delta
			if floating_texts[i]["time"] <= 0:
				floating_texts.remove_at(i)
		needs_redraw = true

	if unit_shakes.size() > 0:
		var keys = unit_shakes.keys()
		for key in keys:
			unit_shakes[key] -= delta
			if unit_shakes[key] <= 0:
				unit_shakes.erase(key)
		needs_redraw = true

	return needs_redraw


func add_event_message(event_feed_messages: Array, fast_simulation: bool, text: String, duration: float = 3.0) -> bool:
	if fast_simulation:
		return false
	event_feed_messages.append({"text": text, "time": duration, "max_time": duration})
	if event_feed_messages.size() > 5:
		event_feed_messages.pop_front()
	return true


func add_floating_text(floating_texts: Array, fast_simulation: bool, grid: Vector2i, text: String, color: Color, duration: float = 1.0) -> bool:
	if fast_simulation:
		return false
	floating_texts.append({"grid": grid, "text": text, "color": color, "time": duration, "max_time": duration})
	return true


func start_unit_shake(unit_shakes: Dictionary, fast_simulation: bool, unit_id: String, duration: float = 0.3) -> bool:
	if fast_simulation:
		return false
	unit_shakes[unit_id] = duration
	return true
