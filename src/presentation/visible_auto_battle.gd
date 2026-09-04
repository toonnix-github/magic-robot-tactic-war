extends "res://src/main.gd"

# Phase 1 compatibility layer: keep the existing simulation authoritative while
# separating Auto Battle (AI decision making) from Fast Simulation (presentation skip).
# This file is intentionally small so the later architecture refactor can move the
# presentation pipeline out of the monolithic main.gd without changing behavior.

var auto_activation_highlight_seconds: float = ENEMY_ACTIVATION_HIGHLIGHT_SECONDS
var auto_move_step_seconds: float = ENEMY_MOVE_STEP_SECONDS


func _input_locked() -> bool:
	return (
		enemy_presentation_active
		or attack_presentation_active
		or (auto_battle and not _is_battle_over())
	)


func _begin_next_activation() -> void:
	if _is_battle_over():
		return

	_is_activating = true
	for _index in range(units.size() * 4):
		_rebuild_initiative_timeline()
		if initiative_timeline.is_empty():
			_is_activating = false
			return

		var next_unit = _unit_by_id(initiative_timeline[0])
		if next_unit == null:
			_is_activating = false
			return

		_begin_activation(next_unit)
		if not _is_unit_in_battle(next_unit):
			_finish_activation(next_unit)
			if _is_battle_over():
				_is_activating = false
				return
			continue

		if next_unit["team"] == "player":
			if not auto_battle:
				_is_activating = false
				return
			if fast_simulation:
				_resolve_ai_activation(next_unit)
			else:
				var player_plan := _plan_ai_activation(next_unit)
				_is_activating = false
				_present_enemy_activation.call_deferred(next_unit, player_plan)
				return
		else:
			# In Auto Battle, presentation stays visible unless Fast Simulation is ON.
			# In manual play, the legacy enemy_presentation_enabled debug flag is still honored.
			if fast_simulation or (not auto_battle and not enemy_presentation_enabled):
				_resolve_enemy_activation(next_unit)
			else:
				var enemy_plan := _plan_ai_activation(next_unit)
				_is_activating = false
				_present_enemy_activation.call_deferred(next_unit, enemy_plan)
				return
		if _is_battle_over():
			_is_activating = false
			return

	_is_activating = false


func _present_enemy_activation(unit, plan: Dictionary) -> void:
	if unit == null or not _is_unit_in_battle(unit):
		return
	if fast_simulation:
		_resolve_planned_ai_activation_fast(unit, plan)
		return

	enemy_presentation_active = true
	_is_activating = true
	selected_unit = unit
	active_unit = unit
	last_action_message = "%s activates" % unit["name"]
	enemy_presentation_log.append("%s:activate" % unit["id"])
	queue_redraw()
	await get_tree().create_timer(auto_activation_highlight_seconds).timeout

	var path: Array = plan.get("path", [])
	for step in path:
		unit["grid"] = step
		last_action_message = "%s moves" % unit["name"]
		enemy_presentation_log.append("%s:presentation_move:(%d,%d)" % [unit["id"], step.x, step.y])
		queue_redraw()
		await get_tree().create_timer(auto_move_step_seconds).timeout

	if not path.is_empty():
		unit["has_moved"] = true
		var final_grid: Vector2i = path[path.size() - 1]
		turn_log.append("%s:move:(%d,%d)" % [unit["id"], final_grid.x, final_grid.y])
		reachable_tiles.clear()
		targetable_tiles.clear()
		target_preview.clear()
		turn_state = TurnState.MOVE_COMPLETE

	var attacked := false
	if str(plan.get("action", "")) == "Attack" and plan.get("target") != null and _can_attack(unit):
		var sim_seed := _next_simulation_seed()
		var preview := _attack_preview(unit, plan["target"])
		if bool(preview["legal"]):
			var attack_res := _resolve_attack_result(unit, plan["target"], preview, "", sim_seed)
			if attack_presentation_enabled:
				await _present_attack_feedback(unit, plan["target"], attack_res)
			_finish_activation(unit)
			attacked = true

	if not attacked and _is_unit_in_battle(unit):
		unit["activation_complete"] = true
		if str(unit.get("team", "")) == "enemy":
			turn_log.append("%s:enemy_wait" % unit["id"])
		else:
			turn_log.append("%s:wait" % unit["id"])
		last_action_message = "%s holds position" % unit["name"]
		_finish_activation(unit)

	enemy_presentation_active = false
	_is_activating = false
	queue_redraw()
	if not _is_battle_over():
		_begin_next_activation()


func _resolve_attack(attacker, target, preview: Dictionary, part_name := "", seed := 0) -> Dictionary:
	var attack_res := _resolve_attack_result(attacker, target, preview, part_name, seed)
	if (
		attack_presentation_enabled
		and not fast_simulation
		and not _is_activating
		and str(attacker.get("team", "")) == "player"
	):
		_is_activating = true
		attack_presentation_active = true
		attack_feedback_attacker_id = str(attacker["id"])
		attack_feedback_target_id = str(target["id"])
		_present_attack_then_finish.call_deferred(attacker, target, attack_res)
	else:
		_finish_activation(attacker)
	return attack_res


func _present_attack_feedback(attacker, target, result: Dictionary) -> void:
	if not attack_presentation_enabled or fast_simulation:
		return

	attack_presentation_active = true
	attack_feedback_attacker_id = str(attacker["id"]) if attacker != null else ""
	attack_feedback_target_id = str(target["id"]) if target != null else ""
	attack_feedback_queue = _build_attack_feedback_sequence(attacker, target, result)
	for line in attack_feedback_queue:
		last_action_message = line
		attack_feedback_log.append(line)
		queue_redraw()
		await get_tree().create_timer(attack_feedback_step_seconds).timeout
	attack_feedback_queue.clear()
	attack_feedback_attacker_id = ""
	attack_feedback_target_id = ""
	attack_presentation_active = false
	queue_redraw()


func _set_auto_battle(enabled: bool) -> void:
	var can_start_now := (
		not _is_battle_over()
		and not enemy_presentation_active
		and not attack_presentation_active
	)
	auto_battle = enabled
	last_action_message = "Auto Battle: ON" if auto_battle else "Auto Battle: OFF"
	if auto_battle and can_start_now:
		if active_unit == null:
			_begin_next_activation()
		elif str(active_unit.get("team", "")) == "player":
			if fast_simulation:
				_resolve_ai_activation(active_unit)
				if not _is_battle_over():
					_begin_next_activation()
			else:
				var plan := _plan_ai_activation(active_unit)
				_clear_move_preview()
				reachable_tiles.clear()
				targetable_tiles.clear()
				attack_overlay_tiles.clear()
				target_preview.clear()
				_is_activating = false
				_present_enemy_activation.call_deferred(active_unit, plan)
	queue_redraw()
