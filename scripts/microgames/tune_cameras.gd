extends ShiftMicrogame

var channel: int = 0
var frequencies: Array[float] = [50.0, 50.0, 50.0, 50.0]
var targets: Array[float] = [24.0, 61.0, 83.0, 33.0]
var locked: Array[bool] = [false, false, false]
var lock_progress: float = 0.0
var dragging: bool = false
var direction: int = 0
var found_exit: bool = false
var late_shift: bool = false
var slider: Rect2 = Rect2(236, 481, 586, 30)
var report_button: Rect2 = Rect2(898, 480, 205, 60)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		suspend_input()

func suspend_input() -> void:
	direction = 0
	dragging = false

func _setup() -> void:
	duration = 35.0
	channel = 0
	frequencies = [50.0, 50.0, 50.0, 50.0]
	locked = [false, false, false]
	lock_progress = 0.0
	dragging = false
	direction = 0
	found_exit = false
	late_shift = bool(context.get("late", false))
	feedback = "Drag the tuner to the marked service frequency. Hold it steady."

func _tick(delta: float) -> void:
	if direction != 0:
		frequencies[channel] = clampf(frequencies[channel] + direction * delta * 25.0, 0.0, 100.0)
	var tolerance: float = 5.0 - difficulty * 0.5
	if absf(frequencies[channel] - targets[channel]) <= tolerance:
		lock_progress += delta
		if lock_progress >= 0.7:
			if channel < 3 and not locked[channel]:
				locked[channel] = true
				sound_requested.emit("breaker")
				feedback = "Feed locked. Select another camera; file the report when ready."
			elif channel == 3 and late_shift and not found_exit:
				found_exit = true
				evidence_found.emit("camera4")
				sound_requested.emit("paper")
				feedback = "Camera 4: the front door unlocks at six. The writing is yours."
	else:
		lock_progress = 0.0

func select_channel(value: int) -> void:
	channel = value
	lock_progress = 0.0
	dragging = false
	if channel == 3:
		feedback = "Forbidden after 3:33. The exit sign is visible through the static." if late_shift else "Camera 4 is a front-door feed. The manager said: not after 3:33."
	else:
		feedback = "Drag the tuner to the marked service frequency. Hold it steady."

func _handle(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_LEFT or event.keycode == KEY_A:
			direction = -1 if event.pressed else 0
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			direction = 1 if event.pressed else 0
		elif event.pressed and not event.echo and event.keycode >= KEY_1 and event.keycode <= KEY_4:
			select_channel(event.keycode - KEY_1)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			dragging = false
		else:
			for index in range(4):
				if Rect2(892, 237 + index * 55, 213, 44).has_point(event.position):
					select_channel(index)
			if slider.grow(12).has_point(event.position):
				dragging = true
				frequencies[channel] = clampf((event.position.x - slider.position.x) / slider.size.x * 100.0, 0.0, 100.0)
			if report_button.has_point(event.position):
				if locked.all(func(value): return value):
					finish(true, "Three feeds filed." + (" Camera 4 showed the way out." if found_exit else " Camera 4 remains unexplained."))
				else:
					feedback = "Tune cameras 1, 2, and 3 before filing the report."
	if event is InputEventMouseMotion and dragging:
		frequencies[channel] = clampf((event.position.x - slider.position.x) / slider.size.x * 100.0, 0.0, 100.0)

func _draw() -> void:
	panel(Rect2(140, 150, 1000, 440), Color("141f23"), BLUE)
	label_at("SIGNAL HUNT 1–3, THEN FILE REPORT", Vector2(170, 187), 26, YELLOW)
	label_at("Camera 4 is optional. Manager: DO NOT LOOK AFTER 3:33.", Vector2(170, 218), 22, PURPLE)
	panel(Rect2(176, 239, 681, 225), Color("142c28"), GREEN)
	var strength: float = 1.0 - clampf(absf(frequencies[channel] - targets[channel]) / 45.0, 0.0, 1.0)
	var clear: bool = absf(frequencies[channel] - targets[channel]) <= 5.0 - difficulty * 0.5
	label_at("CAM " + str(channel + 1) + "  /  " + ["CHECKOUT", "AISLE FOUR", "STOCKROOM", "FRONT EXIT"][channel], Vector2(194, 269), 22, GREEN)
	if channel == 3:
		panel(Rect2(445, 276, 126, 143), Color("2c4840"), CREAM)
		label_at("EXIT", Vector2(478, 310), 23, GREEN)
		draw_circle(Vector2(550, 361), 4, YELLOW)
		if clear and late_shift:
			label_at("FRONT LOCK RELEASE: 06:00", Vector2(214, 346), 23, CREAM)
			label_at("MY SHIFT ENDS AT SIX.", Vector2(240, 383), 28, YELLOW)
			label_at("It is written on the inside of the glass.", Vector2(226, 430), 21, GREEN)
		elif clear:
			label_at("A normal door. A street with no passing cars.", Vector2(205, 447), 22, CREAM)
	elif channel == 0:
		draw_rect(Rect2(250, 350, 486, 63), BLUE.darkened(0.4))
		panel(Rect2(340, 300, 130, 54), INK, GREEN)
		label_at("NO SALE", Vector2(350, 335), 20, GREEN)
		if clear:
			label_at("The till opens. Nobody is standing there.", Vector2(218, 447), 22, CREAM)
	elif channel == 1:
		for row in range(3):
			draw_line(Vector2(245, 306 + row * 43), Vector2(774, 311 + row * 43), BLUE, 8)
			for item in range(9):
				draw_rect(Rect2(263 + item * 54, 282 + row * 43, 25, 23), GREEN.darkened(0.25))
		if clear:
			label_at("Every label faces the camera now.", Vector2(235, 447), 22, CREAM)
	else:
		panel(Rect2(410, 281, 185, 132), Color("35423a"), CREAM)
		label_at("CLOSED", Vector2(448, 350), 23, YELLOW)
		if clear:
			label_at("Someone has braced it from the other side.", Vector2(197, 447), 22, CREAM)
	var lines: int = int((1.0 - strength) * 34.0)
	for index in range(lines):
		var y: float = 280 + fmod(index * 43 + (0.0 if reduced_motion else elapsed * 27), 160)
		draw_line(Vector2(186 + (index % 4) * 27, y), Vector2(843, y + index % 3), Color(0.36, 0.50, 0.44, 0.75), 3)
	for index in range(4):
		var text: String = "CAM " + str(index + 1)
		if index < 3 and locked[index]:
			text += "  LOCKED"
		elif index == 3:
			text += "  ?"
		button(Rect2(892, 237 + index * 55, 213, 44), text, YELLOW if channel == index else BLUE)
	draw_line(Vector2(slider.position.x, 496), Vector2(slider.end.x, 496), BLUE, 8)
	var target_x: float = slider.position.x + targets[channel] / 100.0 * slider.size.x
	draw_line(Vector2(target_x, 476), Vector2(target_x, 516), GREEN, 3)
	var dial_x: float = slider.position.x + frequencies[channel] / 100.0 * slider.size.x
	draw_rect(Rect2(dial_x - 9, 478, 18, 36), CREAM)
	label_at(str(int(frequencies[channel])) + " MHz   /   service mark " + str(int(targets[channel])) + "   /   arrows fine-tune", Vector2(228, 540), 21, GREEN if clear else CREAM)
	button(report_button, "FILE REPORT", GREEN if locked.all(func(value): return value) else BLUE)
	label_at(feedback, Vector2(170, 576), 21, CREAM)
