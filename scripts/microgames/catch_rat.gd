extends ShiftMicrogame

var hits: int = 0
var mistakes: int = 0
var rat: Vector2 = Vector2(450, 365)
var motion_clock: float = 0.0
var hit_flash: float = 0.0
var fake_positions: Array[Vector2] = [Vector2(300, 315), Vector2(955, 430)]

func _setup() -> void:
	duration = 30.0
	hits = 0
	mistakes = 0
	motion_clock = 0.0
	hit_flash = 0.0
	rat = Vector2(450, 365)
	feedback = "The real rat has a pink nose, round ears, and a long tail."

func _tick(delta: float) -> void:
	motion_clock += delta * (0.75 + difficulty * 0.13)
	var travel: float = motion_clock + hits * 1.7
	rat = Vector2(640 + sin(travel) * 340, 375 + sin(travel * 1.8) * 93)
	hit_flash = maxf(0.0, hit_flash - delta)

func _handle(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Rect2(rat - Vector2(83, 50), Vector2(166, 100)).has_point(event.position):
			hits += 1
			hit_flash = 0.35
			motion_clock += 1.4
			var travel: float = motion_clock + hits * 1.7
			rat = Vector2(640 + sin(travel) * 340, 375 + sin(travel * 1.8) * 93)
			sound_requested.emit("scanner")
			feedback = "Caught " + str(hits) + " / 3. It keeps slipping free."
			if hits >= 3:
				finish(true, "Three catches. You release it outside. It almost says thank you.")
		elif fakes_visible():
			for fake in fake_positions:
				if event.position.distance_to(fake) <= 54.0:
					mistakes += 1
					time_left = maxf(0.1, time_left - 3.0)
					feedback = "No tail. No pink nose. That was a shadow. (-3 seconds)"
					sound_requested.emit("failure")
					if mistakes >= 3:
						finish(false, "You caught three shadows. They stayed in your hands.")
					return

func fakes_visible() -> bool:
	return elapsed > 2.0 and fmod(elapsed, 6.0) > 1.5

func draw_rat(point: Vector2, real: bool) -> void:
	if real and ResourceLoader.exists("res://assets/art/rat.png"):
		sprite("rat", Rect2(point - Vector2(80, 50), Vector2(160, 100)))
		draw_circle(point + Vector2(-74, 15), 4, Color("e8a1a6"))
		return
	var fur: Color = Color("8d9990") if real else Color("222337")
	if real:
		draw_polyline(PackedVector2Array([point + Vector2(-30, 10), point + Vector2(-58, 24), point + Vector2(-75, 9), point + Vector2(-82, 15)]), Color("c9a594"), 6)
	draw_circle(point, 31, INK)
	draw_circle(point, 27, fur)
	draw_circle(point + Vector2(28, -2), 19, fur)
	draw_circle(point + Vector2(12, -27), 12 if real else 8, fur)
	draw_circle(point + Vector2(30, -24), 10 if real else 7, fur)
	if real:
		draw_circle(point + Vector2(12, -27), 6, Color("c9a594"))
		draw_circle(point + Vector2(30, -24), 5, Color("c9a594"))
		draw_circle(point + Vector2(47, 1), 6, Color("e8a1a6"))
		draw_line(point + Vector2(37, 8), point + Vector2(65, 16), CREAM, 2)
		draw_line(point + Vector2(37, 6), point + Vector2(65, 0), CREAM, 2)
	draw_circle(point + Vector2(30, -8), 4, INK if real else PURPLE)
	draw_line(point + Vector2(-17, 26), point + Vector2(-6, 26), fur, 7)
	draw_line(point + Vector2(20, 20), point + Vector2(31, 22), fur, 7)

func _draw() -> void:
	panel(Rect2(140, 150, 1000, 440), Color("243230"), BLUE)
	label_at("RAT RACE / THREE HITS", Vector2(170, 190), 26, YELLOW)
	label_at("Click the pink nose / long tail. Shadows are bait.", Vector2(170, 221), 22)
	for y in range(265, 531, 55):
		draw_line(Vector2(160, y), Vector2(1120, y + 8), Color("344340"), 2)
	for x in range(185, 1100, 125):
		draw_line(Vector2(x, 250), Vector2(x + 13, 523), Color("344340"), 2)
	if fakes_visible():
		for point in fake_positions:
			draw_rat(point, false)
	draw_rat(rat, true)
	if hit_flash > 0.0:
		label_at("GOT IT", rat + Vector2(-35, -57), 22, GREEN)
	panel(Rect2(852, 480, 252, 44), INK, BLUE)
	label_at("CATCHES " + str(hits) + " / 3", Vector2(870, 511), 23, GREEN)
	label_at(feedback, Vector2(170, 565), 22, CREAM)
