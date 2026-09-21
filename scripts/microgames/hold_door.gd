extends ShiftMicrogame

var pressure: float = 20.0
var barricade: int = 1
var required_lane: int = 1
var next_lane: int = 1
var holding_space: bool = false
var holding_mouse: bool = false
var changes: int = 0
var next_change: float = 6.0
var warning: bool = false
var bang_clock: float = 0.0
var hold_goal: float = 22.0
var heard_breath: bool = false

func _setup() -> void:
	duration = 32.0
	pressure = 20.0
	barricade = 1
	required_lane = 1
	next_lane = 1
	holding_space = false
	holding_mouse = false
	changes = 0
	next_change = 6.0
	warning = false
	bang_clock = 0.0
	hold_goal = 22.0 + difficulty
	heard_breath = false
	feedback = "Hold SPACE or left mouse. A / D move the brace."

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		suspend_input()

func suspend_input() -> void:
	holding_space = false
	holding_mouse = false

func _tick(delta: float) -> void:
	var preview: float = 1.7 - difficulty * 0.12
	if not warning and elapsed >= next_change - preview:
		warning = true
		next_lane = [0, 2, 1, 0, 2][changes % 5]
		feedback = "The chalk mark is moving. Brace the marked third."
		sound_requested.emit("bang")
	if warning and elapsed >= next_change:
		required_lane = next_lane
		warning = false
		changes += 1
		next_change += 5.4 - difficulty * 0.25
		feedback = "Keep holding. Follow the chalk mark."
		sound_requested.emit("scrape")
	if elapsed >= 16.0 and not heard_breath:
		heard_breath = true
		sound_requested.emit("breath")
	var braced: bool = (holding_space or holding_mouse) and barricade == required_lane
	pressure = clampf(pressure + (-13.0 if braced else 19.0 + difficulty * 2.0) * delta, 0.0, 100.0)
	bang_clock += delta
	if bang_clock > 3.1 and not (elapsed > 13.0 and elapsed < 16.0):
		bang_clock = 0.0
		sound_requested.emit("bang")
	if pressure >= 100.0:
		finish(false, "The brace slipped. Something learned how hard you push.")
	elif elapsed >= hold_goal:
		finish(true, "The knocking stops. The handle is still warm.")

func _handle(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_SPACE:
			holding_space = event.pressed
		if event.pressed and not event.echo:
			if event.keycode == KEY_A or event.keycode == KEY_LEFT:
				barricade = maxi(0, barricade - 1)
			elif event.keycode == KEY_D or event.keycode == KEY_RIGHT:
				barricade = mini(2, barricade + 1)
			elif event.keycode >= KEY_1 and event.keycode <= KEY_3:
				barricade = event.keycode - KEY_1
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		holding_mouse = event.pressed
		if event.pressed:
			for lane in range(3):
				if Rect2(270 + lane * 185, 460, 165, 55).has_point(event.position):
					barricade = lane

func _draw() -> void:
	panel(Rect2(140, 150, 1000, 440), Color("11191c"), BLUE)
	label_at("BARRICADE BASH", Vector2(170, 187), 26, YELLOW)
	label_at("Hold SPACE / mouse   •   Chase the warning mark with A / D", Vector2(170, 220), 22)
	panel(Rect2(270, 242, 535, 205), Color("3a4543"), CREAM)
	sprite("door", Rect2(438, 242, 137, 205), Color(1, 1, 1, 0.45))
	for line_index in range(7):
		var y: float = 262 + line_index * 25
		draw_line(Vector2(285, y), Vector2(789, y + 3), Color("283734"), 3)
	label_at("STOCKROOM", Vector2(439, 293), 26, CREAM)
	label_at("DO NOT OPEN", Vector2(437, 327), 20, RED)
	var tremble: float = sin(elapsed * 8.0) * pressure * 0.035 if not reduced_motion else 0.0
	draw_circle(Vector2(763 + tremble, 355), 9, YELLOW)
	for lane in range(3):
		var mark_color: Color = YELLOW if lane == required_lane else BLUE.darkened(0.45)
		var cx: float = 350 + lane * 185
		draw_line(Vector2(cx - 17, 366), Vector2(cx + 17, 408), mark_color, 5)
		draw_line(Vector2(cx + 17, 366), Vector2(cx - 17, 408), mark_color, 5)
		if warning and lane == next_lane:
			draw_arc(Vector2(cx, 388), 32, 0, TAU, 20, PURPLE, 3)
			label_at("NEXT", Vector2(cx - 28, 440), 18, PURPLE)
		var target: Rect2 = Rect2(270 + lane * 185, 460, 165, 55)
		button(target, str(lane + 1) + ("  BRACED" if lane == barricade else "  MOVE"), GREEN if lane == barricade else BLUE)
	var brace_x: float = 312 + barricade * 185
	draw_line(Vector2(brace_x - 17, 427), Vector2(brace_x + 86, 356), GREEN, 13)
	label_at("DOOR GAP", Vector2(877, 270), 22, CREAM)
	panel(Rect2(910, 287, 56, 171), INK, RED)
	draw_rect(Rect2(916, 452 - pressure * 1.59, 44, pressure * 1.59), RED if pressure > 70 else YELLOW)
	label_at(str(int(pressure)) + "%", Vector2(916, 485), 22, RED if pressure > 70 else CREAM)
	label_at("Hold " + str(maxi(0, int(ceil(hold_goal - elapsed)))) + "s", Vector2(873, 520), 22, GREEN)
	label_at(feedback, Vector2(170, 565), 22, PURPLE if warning else CREAM)
