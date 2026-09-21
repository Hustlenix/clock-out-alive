extends ShiftMicrogame

var sequence: Array[int] = []
var entered: Array[int] = []
var stage: String = "watch"
var stage_time: float = 0.0
var lit: int = -1
var flash_left: float = 0.0
var replay_available: bool = true
var switch_rects: Array[Rect2] = []
const REPLAY = Rect2(887, 191, 212, 44)
const FAKE = Rect2(981, 475, 119, 47)

func _setup() -> void:
	duration = 32.0
	sequence.clear()
	entered.clear()
	switch_rects.clear()
	var patterns = [[1, 4, 2, 5], [2, 5, 1, 3, 0], [5, 2, 4, 1, 3, 0], [4, 0, 3, 5, 1, 2]]
	for number in patterns[clampi(difficulty, 0, 3)]: sequence.append(number)
	for i in range(6): switch_rects.append(Rect2(210 + i * 148, 316, 120, 128))
	stage = "watch"
	stage_time = 0.0
	lit = -1
	flash_left = 0.0
	replay_available = true
	feedback = "WATCH the green switches. Repeat the order after the demonstration."

func _tick(delta: float) -> void:
	stage_time += delta
	if stage == "watch":
		var unit = 0.95 if difficulty == 0 else 0.80
		var index = int((stage_time - 0.8) / unit)
		if stage_time < 0.8:
			lit = -1
		elif index < sequence.size():
			var next = sequence[index] if fmod(stage_time - 0.8, unit) < unit * 0.7 else -1
			if next >= 0 and next != lit: sound_requested.emit("breaker")
			lit = next
		else:
			stage = "repeat"
			stage_time = 0.0
			lit = -1
			feedback = "YOUR TURN. Click switches or press 1–6 in the order you saw."
	else:
		flash_left -= delta
		if flash_left <= 0: lit = -1

func _handle(event: InputEvent) -> void:
	if finished or stage != "repeat": return
	if clicked(event, REPLAY) or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R):
		if replay_available:
			replay_available = false
			entered.clear()
			stage = "watch"
			stage_time = 0.0
			feedback = "One replay. Watch closely; the task timer keeps running."
		return
	var selected = -1
	if event is InputEventKey and event.pressed and not event.echo:
		var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if code >= KEY_1 and code <= KEY_6: selected = code - KEY_1
	for i in range(switch_rects.size()):
		if clicked(event, switch_rects[i]): selected = i
	if difficulty >= 2 and clicked(event, FAKE):
		finish(false, "The extra switch was not connected to the lights.")
		return
	if selected >= 0: _press_switch(selected)
	queue_redraw()

func _press_switch(selected: int) -> void:
	if finished or stage != "repeat": return
	lit = selected
	flash_left = 0.28
	sound_requested.emit("breaker")
	if selected != sequence[entered.size()]:
		finish(false, "Wrong circuit. Somewhere, a different room lit up.")
		return
	entered.append(selected)
	feedback = "%d / %d switches restored." % [entered.size(), sequence.size()]
	if entered.size() == sequence.size():
		finish(true, "Power restored. The unlisted circuit remains off.")

func _draw() -> void:
	panel(Rect2(140, 150, 1000, 440), Color("1a2529"))
	label_at("VOLTAGE MEMORY / LIGHTS OUT", Vector2(175, 191), 23, YELLOW)
	label_at("WATCH" if stage == "watch" else "REPEAT  •  KEYS 1–6 / CLICK", Vector2(175, 230), 23, GREEN)
	if stage == "repeat" and replay_available: button(REPLAY, "R  REPLAY ONCE", YELLOW)
	panel(Rect2(188, 277, 918, 189), Color("3b4849"), BLUE)
	for i in range(6):
		var rect = switch_rects[i]
		panel(rect, Color("20292c"), GREEN if i == lit else INK)
		var lever_y = 339 if lit == i else 368
		draw_rect(Rect2(rect.position + Vector2(35, 13), Vector2(48, 70)), INK)
		draw_rect(Rect2(rect.position.x + 23, lever_y, 73, 27), GREEN if i == lit else BLUE)
		draw_line(Vector2(rect.position.x + 28, lever_y + 5), Vector2(rect.position.x + 89, lever_y + 5), CREAM, 2)
		label_at(str(i + 1), rect.position + Vector2(51, 116), 28, CREAM)
		var code = "CIRCUIT %02d" % (i + 1)
		if difficulty >= 2 and int(elapsed * 1.7) % 6 == i: code = "STAY HERE"
		label_at(code, rect.position + Vector2(5, -13), 14, BLUE)
	for i in range(sequence.size()):
		draw_circle(Vector2(221 + i * 39, 503), 9, GREEN if i < entered.size() else BLUE)
	label_at("The numbered switches are the only wired circuits.", Vector2(466, 510), 17, CREAM)
	if difficulty >= 2:
		panel(FAKE, Color("262031"), PURPLE)
		label_at("RETURN", FAKE.position + Vector2(17, 31), 19, PURPLE)
		# No connecting wire: the seventh control is visibly foreign to the panel.
	label_at(feedback, Vector2(175, 566), 19, CREAM)
