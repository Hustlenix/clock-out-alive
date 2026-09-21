extends ShiftMicrogame

const FLOOR = Rect2(180, 245, 920, 283)
var mop := Vector2(223, 281)
var spills: Array[Dictionary] = []
var keys: Dictionary = {}
var cleaned: int = 0
var danger: float = 0.0
var shadow := Vector2(640, 380)
var step_sound: float = 0.0

func _setup() -> void:
	duration = 35.0
	mop = Vector2(223, 281)
	spills.clear()
	keys.clear()
	cleaned = 0
	danger = 0.0
	step_sound = 0.0
	var positions = [Vector2(280, 300), Vector2(470, 445), Vector2(645, 289), Vector2(850, 449),
		Vector2(1015, 301), Vector2(675, 481), Vector2(368, 391), Vector2(966, 407), Vector2(533, 321)]
	for i in range(6 + mini(difficulty, 3)):
		spills.append({"pos": positions[i], "clean": 0.0})
	feedback = "Hold WASD or arrows. Keep the mop on BLUE puddles until they vanish."

func suspend_input() -> void:
	keys.clear()

func _handle(event: InputEvent) -> void:
	if finished:
		return
	if event is InputEventKey:
		var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		keys[code] = event.pressed

func _tick(delta: float) -> void:
	var move := Vector2.ZERO
	if keys.get(KEY_A, false) or keys.get(KEY_LEFT, false): move.x -= 1
	if keys.get(KEY_D, false) or keys.get(KEY_RIGHT, false): move.x += 1
	if keys.get(KEY_W, false) or keys.get(KEY_UP, false): move.y -= 1
	if keys.get(KEY_S, false) or keys.get(KEY_DOWN, false): move.y += 1
	mop += move.normalized() * 315.0 * delta
	mop = mop.clamp(FLOOR.position + Vector2(23, 22), FLOOR.end - Vector2(23, 19))
	shadow = Vector2(640 + sin(elapsed * (0.60 + difficulty * 0.14)) * 325, 389 + sin(elapsed * 0.9) * 44)
	if move.length_squared() > 0:
		step_sound -= delta
		if step_sound <= 0:
			step_sound = 0.3
			sound_requested.emit("footsteps")
	for spill in spills:
		if spill.clean >= 1.0:
			continue
		if mop.distance_to(spill.pos) <= 44:
			spill.clean = minf(1.0, spill.clean + delta * 0.65)
			if spill.clean >= 1.0:
				cleaned += 1
				sound_requested.emit("paper")
	if difficulty > 0 and mop.distance_to(shadow) < 64:
		danger += delta * 0.47
		feedback = "The floor is soft here. MOVE AWAY from the dark shape."
	else:
		danger = maxf(0.0, danger - delta * 0.32)
		feedback = "Blue puddles are wet. Thin purple marks are old, dry scratches."
	if danger >= 1.0:
		finish(false, "You stood above it too long. The tile remembered your weight.")
	elif cleaned == spills.size():
		finish(true, "Floor dry. Something underneath followed the mop.")

func _draw() -> void:
	panel(Rect2(140, 150, 1000, 440), Color("1a292b"))
	draw_rect(FLOOR, Color("354448"))
	for i in range(10):
		draw_line(Vector2(180 + i * 102, 245), Vector2(180 + i * 102, 528), Color("263439"), 3)
	for i in range(4):
		draw_line(Vector2(180, 245 + i * 93), Vector2(1100, 245 + i * 93), Color("263439"), 3)
	draw_colored_polygon(PackedVector2Array([shadow + Vector2(-85, 0), shadow + Vector2(-28, -22),
		shadow + Vector2(70, -16), shadow + Vector2(95, 8), shadow + Vector2(5, 33)]), Color("18232b"))
	if difficulty > 0:
		for p in [Vector2(430, 285), Vector2(810, 357), Vector2(570, 476)]:
			draw_line(p - Vector2(22, 5), p + Vector2(19, 4), PURPLE, 2)
			draw_line(p - Vector2(10, 12), p + Vector2(11, 13), PURPLE, 2)
	for spill in spills:
		if spill.clean >= 1.0: continue
		var p: Vector2 = spill.pos
		var radius: float = 32.0 * (1.0 - spill.clean * 0.7)
		draw_circle(p, radius, BLUE)
		draw_circle(p + Vector2(-14, 7), radius * 0.65, BLUE)
		draw_line(p + Vector2(-18, -6), p + Vector2(8, -8), CREAM, 2)
		draw_line(p + Vector2(-9, 8), p + Vector2(18, 7), Color("879da1"), 2)
		if spill.clean > 0:
			draw_arc(p, 39, -PI * 0.5, -PI * 0.5 + TAU * spill.clean, 20, GREEN, 3)
	draw_arc(mop, 32, 0.0, TAU, 12, CREAM, 1.0)
	sprite("mop", Rect2(mop - Vector2(48, 106), Vector2(128, 128)))
	# The long handle may leave the floor, but never obscures the control instructions.
	draw_rect(Rect2(142, 152, 996, 91), Color("1a292b"))
	label_at("SHADOW SLALOM  /  KEEP MOVING", Vector2(175, 191), 24, YELLOW)
	label_at("WASD / ARROWS to sweep  •  %d / %d puddles cleared" % [cleaned, spills.size()], Vector2(175, 228), 22)
	if danger > 0.01:
		panel(Rect2(810, 171, 284, 20), INK, RED)
		draw_rect(Rect2(813, 174, 278 * danger, 14), RED)
	label_at(feedback, Vector2(175, 566), 19, RED if danger > 0.2 else CREAM)
