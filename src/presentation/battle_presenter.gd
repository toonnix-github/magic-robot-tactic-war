extends RefCounted
class_name BattlePresenter

func process_feedback(event_feed_messages: Array, floating_texts: Array, unit_shakes: Dictionary, delta: float) -> bool:
	var needs_redraw := false

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
