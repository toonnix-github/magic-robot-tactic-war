extends RefCounted
class_name Phase2BuildValidation

func unit_metrics(battle_log: Array, target_unit_id: String) -> Dictionary:
	var dmg_dealt := 0
	var dmg_taken := 0
	var shield_intercepts := 0
	var current_attacker := ""

	for item in battle_log:
		var entry: String = str(item)
		if entry.ends_with(":attack") and not entry.ends_with(":enemy_attack"):
			var parts: PackedStringArray = entry.split(":")
			if parts.size() >= 2:
				current_attacker = parts[0]
		elif entry.contains(":shield_intercept:"):
			var parts: PackedStringArray = entry.split(":")
			if parts.size() >= 3 and parts[0] == target_unit_id:
				shield_intercepts += 1
		elif entry.contains(":hit:") or entry.contains(":miss:") or entry.contains(":move:") or entry.contains(":status:") or entry.ends_with(":wait"):
			current_attacker = ""
		elif entry.contains(":damage:"):
			var parts: PackedStringArray = entry.split(":")
			if parts.size() >= 4:
				var t_id := parts[0]
				var amt := int(parts[3])
				if current_attacker == target_unit_id and t_id != target_unit_id:
					dmg_dealt += amt
				elif t_id == target_unit_id:
					dmg_taken += amt

	return {
		target_unit_id + "_damage_dealt": dmg_dealt,
		target_unit_id + "_damage_taken": dmg_taken,
		target_unit_id + "_shield_intercepts": shield_intercepts,
	}


func run(scene, custom_seeds: Array = []) -> Dictionary:
	var seeds: Array = custom_seeds if not custom_seeds.is_empty() else scene.BENCHMARK_SEEDS
	scene.fast_simulation = true
	scene.enemy_presentation_enabled = false
	scene.attack_presentation_enabled = false
	var base: Dictionary = scene.mech_build_model.prototype_builds()
	var precision: Dictionary = base.duplicate(true)
	precision["mira"] = {
		"unit_id": "mira", "pilot": "mira", "mech": "Longview-02", "weapon": "Sniper", "off_hand": "",
		"parts": {"Head": "longview_head", "Body": "longview_body", "Left Arm": "longview_left_arm", "Right Arm": "longview_right_arm", "Legs": "longview_legs"},
		"orbs": {"Head": "lightning_r", "Right Arm": "water_r"}
	}
	var durable: Dictionary = base.duplicate(true)
	durable["mira"] = {
		"unit_id": "mira", "pilot": "mira", "mech": "Longview-Custom", "weapon": "Rifle", "off_hand": "Shield",
		"parts": {"Head": "aegis_head", "Body": "bulwark_body", "Left Arm": "bulwark_left_arm", "Right Arm": "aegis_right_arm", "Legs": "aegis_legs"},
		"orbs": {"Right Arm": "fire_sr"}
	}
	var configurations := {"mira_precision_fragile": precision, "mira_durable_shield": durable}
	var results := {"mission": "ancient_ruins", "max_activations": 150, "seeds": seeds.duplicate(), "scenarios": {}}
	for scenario_id in configurations:
		var scenario := {"id": scenario_id, "builds": configurations[scenario_id].duplicate(true), "runs": [], "wins": 0, "losses": 0, "unfinished": 0}
		var totals := {"activations": 0, "mira_survived": 0, "mira_damage_dealt": 0, "mira_damage_taken": 0, "mira_shield_intercepts": 0}
		for seed_value in seeds:
			scene._load_mission(results["mission"], false)
			scene.configure_player_builds(configurations[scenario_id])
			var battle: Dictionary = scene.run_auto_battle(results["max_activations"], int(seed_value))
			battle["seed"] = int(seed_value)
			battle.merge(unit_metrics(battle["turn_log"], "mira"))
			battle["mira_survived"] = scene._is_unit_in_battle(scene._unit_by_id("mira"))
			for metric in totals:
				totals[metric] += int(battle[metric])
			var outcome: String = str(battle["winner"])
			scenario["wins" if outcome == "player" else ("losses" if outcome == "enemy" else "unfinished")] += 1
			scenario["runs"].append(battle)
		var count := float(seeds.size())
		scenario["avg_activations"] = totals["activations"] / count
		scenario["mira_survival_rate"] = totals["mira_survived"] * 100.0 / count
		scenario["avg_mira_dmg_dealt"] = totals["mira_damage_dealt"] / count
		scenario["avg_mira_dmg_taken"] = totals["mira_damage_taken"] / count
		scenario["avg_shield_intercepts"] = totals["mira_shield_intercepts"] / count
		results["scenarios"][scenario_id] = scenario
	return results


func report(results: Dictionary) -> String:
	var lines: Array[String] = [
		"# Phase 2 Build-Fun Validation Report", "",
		"Evidence: deterministic automated simulation; this report does not grant phase sign-off.",
		"Human playtest: pending. No human experience or visual readability judgment is claimed.", "",
		"Reproduce: `godot --headless --path . -s res://tools/run_phase2_validation.gd`.",
		"Mission: `%s`; original sides; activation limit: %d; seeds: `%s`." % [results["mission"], results["max_activations"], str(results["seeds"])],
		"Enemy configuration is the mission default. Each run starts fresh; both squads are recorded below.", "",
		"Damage dealt counts direct attack HP loss (including Shield); later Burn ticks cannot be attributed to their source by the existing log and are excluded. Damage taken includes all logged HP loss, counting Burn once. Intercepts count Mira's redirects, not the whole team's.", ""
	]
	for scenario in results["scenarios"].values():
		lines.append("## %s" % scenario["id"])
		lines.append("")
		lines.append("Exact squad configuration:")
		lines.append("```json\n%s\n```" % JSON.stringify(scenario["builds"], "  "))
		lines.append("")
		lines.append("| Seed | Winner | Activations | Mira survived | Damage dealt | Damage taken | Mira intercepts |")
		lines.append("| --- | --- | --- | --- | --- | --- | --- |")
		for battle in scenario["runs"]:
			var winner: String = str(battle["winner"])
			lines.append("| %d | %s | %d | %s | %d | %d | %d |" % [battle["seed"], winner if not winner.is_empty() else "unfinished", battle["activations"], str(battle["mira_survived"]), battle["mira_damage_dealt"], battle["mira_damage_taken"], battle["mira_shield_intercepts"]])
		lines.append("")
		lines.append("Wins: %d; losses: %d; unfinished: %d. Average activations: %.1f; Mira survival: %.1f%%; average direct damage: %.1f; average damage taken: %.1f; average Mira intercepts: %.1f." % [scenario["wins"], scenario["losses"], scenario["unfinished"], scenario["avg_activations"], scenario["mira_survival_rate"], scenario["avg_mira_dmg_dealt"], scenario["avg_mira_dmg_taken"], scenario["avg_shield_intercepts"]])
		lines.append("")
	lines.append("## Interpretation and Limits")
	lines.append("")
	lines.append("The loadouts change range, durability, Orb effects and arm dependencies together. Differences in these runs cannot be attributed to any one choice. Sniper requires both arms and range planning; Rifle permits Shield in the left arm. These are rule-based tactical implications, not observed human decisions. This sample does not establish universal build superiority or prove that preparation is fun.")
	lines.append("")
	lines.append("See [review](../phase2-build-your-mech-progress-review.md) and [human playtest](phase2-human-playtest.md) for verification status and the remaining product review.")
	return "\n".join(lines) + "\n"
