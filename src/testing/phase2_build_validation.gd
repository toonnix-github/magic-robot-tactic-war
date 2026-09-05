extends RefCounted
class_name Phase2BuildValidation

func unit_metrics(battle_log: Array, target_unit_id: String) -> Dictionary:
	var dmg_dealt := 0
	var dmg_taken := 0
	var shield_intercepts := 0
	var disables := 0
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
		elif entry.contains(":destroy:"):
			var parts: PackedStringArray = entry.split(":")
			if parts.size() >= 3 and parts[0] == target_unit_id:
				var destroyed_part := parts[2]
				if destroyed_part in ["Left Arm", "Right Arm", "Shield"]:
					disables += 1

	return {
		target_unit_id + "_damage_dealt": dmg_dealt,
		target_unit_id + "_damage_taken": dmg_taken,
		target_unit_id + "_shield_intercepts": shield_intercepts,
		target_unit_id + "_disables": disables,
	}


func run(scene, custom_seeds: Array = []) -> Dictionary:
	var seeds: Array = custom_seeds if not custom_seeds.is_empty() else scene.BENCHMARK_SEEDS
	scene.fast_simulation = true
	scene.enemy_presentation_enabled = false
	scene.attack_presentation_enabled = false
	var base: Dictionary = scene.mech_build_model.prototype_builds()

	var precision_sniper: Dictionary = base.duplicate(true)
	precision_sniper["mira"] = {
		"unit_id": "mira", "pilot": "mira", "mech": "Longview-02", "weapon": "Sniper", "off_hand": "",
		"parts": {"Head": "longview_head", "Body": "longview_body", "Left Arm": "longview_left_arm", "Right Arm": "longview_right_arm", "Legs": "longview_legs"},
		"orbs": {"Head": "lightning_r", "Right Arm": "water_r"}
	}

	var durable_shield: Dictionary = base.duplicate(true)
	durable_shield["mira"] = {
		"unit_id": "mira", "pilot": "mira", "mech": "Longview-Custom", "weapon": "Rifle", "off_hand": "Shield",
		"parts": {"Head": "aegis_head", "Body": "bulwark_body", "Left Arm": "bulwark_left_arm", "Right Arm": "aegis_right_arm", "Legs": "aegis_legs"},
		"orbs": {"Right Arm": "fire_sr"}
	}

	var agile_rifle: Dictionary = base.duplicate(true)
	agile_rifle["mira"] = {
		"unit_id": "mira", "pilot": "mira", "mech": "Longview-Volt", "weapon": "Rifle", "off_hand": "",
		"parts": {"Head": "volt_head", "Body": "volt_body", "Left Arm": "volt_left_arm", "Right Arm": "volt_right_arm", "Legs": "sprinter_legs"},
		"orbs": {"Right Arm": "fire_sr"}
	}

	var accuracy_rifle: Dictionary = base.duplicate(true)
	accuracy_rifle["mira"] = {
		"unit_id": "mira", "pilot": "mira", "mech": "Longview-Optics", "weapon": "Rifle", "off_hand": "",
		"parts": {"Head": "longview_head", "Body": "longview_body", "Left Arm": "longview_left_arm", "Right Arm": "longview_right_arm", "Legs": "longview_legs"},
		"orbs": {"Head": "lightning_r", "Right Arm": "water_r"}
	}

	var durable_sniper: Dictionary = base.duplicate(true)
	durable_sniper["mira"] = {
		"unit_id": "mira", "pilot": "mira", "mech": "Longview-Bulwark", "weapon": "Sniper", "off_hand": "",
		"parts": {"Head": "bulwark_head", "Body": "bulwark_body", "Left Arm": "bulwark_left_arm", "Right Arm": "bulwark_right_arm", "Legs": "bulwark_legs"},
		"orbs": {"Right Arm": "water_r"}
	}

	var mobile_spear: Dictionary = base.duplicate(true)
	mobile_spear["mira"] = {
		"unit_id": "mira", "pilot": "mira", "mech": "Longview-Striker", "weapon": "Spear", "off_hand": "",
		"parts": {"Head": "volt_head", "Body": "volt_body", "Left Arm": "volt_left_arm", "Right Arm": "volt_right_arm", "Legs": "sprinter_legs"},
		"orbs": {"Right Arm": "fire_n"}
	}

	var heavy_spear: Dictionary = base.duplicate(true)
	heavy_spear["mira"] = {
		"unit_id": "mira", "pilot": "mira", "mech": "Longview-Phalanx", "weapon": "Spear", "off_hand": "",
		"parts": {"Head": "aegis_head", "Body": "bulwark_body", "Left Arm": "aegis_left_arm", "Right Arm": "bulwark_right_arm", "Legs": "aegis_legs"},
		"orbs": {"Right Arm": "fire_sr"}
	}

	var sword_shield: Dictionary = base.duplicate(true)
	sword_shield["mira"] = {
		"unit_id": "mira", "pilot": "mira", "mech": "Longview-Brawler", "weapon": "Sword", "off_hand": "Shield",
		"parts": {"Head": "aegis_head", "Body": "bulwark_body", "Left Arm": "bulwark_left_arm", "Right Arm": "aegis_right_arm", "Legs": "aegis_legs"},
		"orbs": {"Left Arm": "earth_ssr"}
	}

	var configurations := {
		"mira_precision_fragile": precision_sniper,
		"mira_durable_shield": durable_shield,
		"mira_agile_rifle": agile_rifle,
		"mira_accuracy_rifle": accuracy_rifle,
		"mira_durable_sniper": durable_sniper,
		"mira_mobile_spear": mobile_spear,
		"mira_heavy_spear": heavy_spear,
		"mira_sword_shield": sword_shield,
	}

	var results := {"mission": "ancient_ruins", "max_activations": 150, "seeds": seeds.duplicate(), "scenarios": {}}
	for scenario_id in configurations:
		var scenario := {"id": scenario_id, "builds": configurations[scenario_id].duplicate(true), "runs": [], "wins": 0, "losses": 0, "unfinished": 0}
		var totals := {
			"activations": 0,
			"mira_survived": 0,
			"mira_damage_dealt": 0,
			"mira_damage_taken": 0,
			"mira_shield_intercepts": 0,
			"mira_disables": 0
		}
		for seed_value in seeds:
			scene._load_mission(results["mission"], false)
			scene.configure_player_builds(configurations[scenario_id])
			var battle: Dictionary = scene.run_auto_battle(results["max_activations"], int(seed_value))
			battle["seed"] = int(seed_value)
			battle.merge(unit_metrics(battle["turn_log"], "mira"))
			battle["mira_survived"] = scene._is_unit_in_battle(scene._unit_by_id("mira"))
			for metric in totals:
				totals[metric] += int(battle.get(metric, 0))
			var outcome: String = str(battle["winner"])
			scenario["wins" if outcome == "player" else ("losses" if outcome == "enemy" else "unfinished")] += 1
			scenario["runs"].append(battle)
		var count := float(seeds.size())
		scenario["avg_activations"] = totals["activations"] / count
		scenario["mira_survival_rate"] = totals["mira_survived"] * 100.0 / count
		scenario["avg_mira_dmg_dealt"] = totals["mira_damage_dealt"] / count
		scenario["avg_mira_dmg_taken"] = totals["mira_damage_taken"] / count
		scenario["avg_shield_intercepts"] = totals["mira_shield_intercepts"] / count
		scenario["avg_mira_disables"] = totals["mira_disables"] / count

		var act_list: Array[int] = []
		for battle in scenario["runs"]:
			act_list.append(int(battle["activations"]))
		act_list.sort()
		var n := act_list.size()
		var median := 0.0
		if n > 0:
			if n % 2 == 1:
				median = float(act_list[n / 2])
			else:
				median = float(act_list[(n / 2) - 1] + act_list[n / 2]) / 2.0
		scenario["median_activations"] = median
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
		"Damage dealt counts direct attack HP loss (including Shield); later Burn ticks cannot be attributed to their source by the existing log and are excluded. Damage taken includes all logged HP loss, counting Burn once. Intercepts count Mira's redirects, not the whole team's. Disables count arm and shield destruction events that disabled equipped arm gear.", ""
	]
	for scenario in results["scenarios"].values():
		lines.append("## %s" % scenario["id"])
		lines.append("")
		lines.append("Exact squad configuration:")
		lines.append("```json\n%s\n```" % JSON.stringify(scenario["builds"], "  "))
		lines.append("")
		lines.append("| Seed | Winner | Activations | Mira survived | Damage dealt | Damage taken | Mira intercepts | Disables |")
		lines.append("| --- | --- | --- | --- | --- | --- | --- | --- |")
		for battle in scenario["runs"]:
			var winner: String = str(battle["winner"])
			lines.append("| %d | %s | %d | %s | %d | %d | %d | %d |" % [
				battle["seed"],
				winner if not winner.is_empty() else "unfinished",
				battle["activations"],
				str(battle["mira_survived"]),
				battle["mira_damage_dealt"],
				battle["mira_damage_taken"],
				battle["mira_shield_intercepts"],
				battle.get("mira_disables", 0)
			])
		lines.append("")
		lines.append("Wins: %d; losses: %d; unfinished: %d. Average activations: %.1f; median: %.1f; Mira survival: %.1f%%; average direct damage: %.1f; average damage taken: %.1f; average Mira intercepts: %.1f; average disables: %.1f." % [
			scenario["wins"],
			scenario["losses"],
			scenario["unfinished"],
			scenario["avg_activations"],
			scenario["median_activations"],
			scenario["mira_survival_rate"],
			scenario["avg_mira_dmg_dealt"],
			scenario["avg_mira_dmg_taken"],
			scenario["avg_shield_intercepts"],
			scenario["avg_mira_disables"]
		])
		lines.append("")
	lines.append("## Interpretation and Limits")
	lines.append("")
	lines.append("The loadouts change range, durability, Orb effects and arm dependencies together. Differences in these runs cannot be attributed to any one choice. Sniper requires both arms and range planning; Rifle permits Shield in the left arm. These are rule-based tactical implications, not observed human decisions. This sample does not establish universal build superiority or prove that preparation is fun.")
	lines.append("")
	lines.append("See [review](../phase2-build-your-mech-progress-review.md) and [human playtest](phase2-human-playtest.md) for verification status and the remaining product review.")
	return "\n".join(lines) + "\n"
