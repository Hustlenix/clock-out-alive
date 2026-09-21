extends ShiftMicrogame

const SIZE = Vector2(94, 87)
var items: Array[Dictionary] = []
var slots: Array[Rect2] = []
var held: int = -1
var hold_offset := Vector2.ZERO
var stocked: int = 0
var wrong: int = 0
var shifted: bool = false

func _setup() -> void:
	duration = 35.0
	items.clear()
	slots.clear()
	held = -1
	stocked = 0
	wrong = 0
	shifted = false
	var names = ["MINT", "OATS", "SOAP", "RICE", "SALT", "TEA"]
	var order = [3, 0, 5, 1, 4, 2]
	for i in range(6):
		var home = Vector2(196 + (i % 3) * 126, 285 + (i / 3) * 136)
		items.append({"pos": home, "home": home, "name": names[order[i]], "slot": order[i], "done": false})
		slots.append(Rect2(648 + (i % 3) * 147, 271 + (i / 3) * 139, 130, 115))
	feedback = "Match each printed product name to its shelf label. Three wrong shelves ends the task."

func suspend_input() -> void:
	if held >= 0:
		items[held].pos = items[held].home
	held = -1
	queue_redraw()

func _handle(event: InputEvent) -> void:
	if finished: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			for i in range(items.size() - 1, -1, -1):
				if not items[i].done and Rect2(items[i].pos, SIZE).has_point(event.position):
					held = i
					hold_offset = event.position - items[i].pos
					sound_requested.emit("paper")
					break
		elif held >= 0:
			var selected = held
			items[selected].pos = event.position - hold_offset
			held = -1
			var center: Vector2 = items[selected].pos + SIZE * 0.5
			var target = -1
			for j in range(slots.size()):
				if slots[j].has_point(center): target = j
			if target == items[selected].slot:
				items[selected].done = true
				stocked += 1
				sound_requested.emit("scanner")
				feedback = "%d / 6 shelved. Read the labels, even if the shelves move." % stocked
				if difficulty >= 2 and stocked == 3 and not shifted:
					_shift_empty_shelves()
				if stocked == items.size():
					finish(true, "Aisle stocked. The person behind the shelf did not buy anything.")
			else:
				items[selected].pos = items[selected].home
				if target >= 0:
					wrong += 1
					sound_requested.emit("breaker")
					feedback = "Wrong label. %d / 3 stock errors. Match the WORDS." % wrong
					if wrong >= 3: finish(false, "Three wrong shelves. The aisle learned your mistakes.")
	elif event is InputEventMouseMotion and held >= 0:
		items[held].pos = event.position - hold_offset
	queue_redraw()

func _shift_empty_shelves() -> void:
	var empty: Array[int] = []
	for i in range(items.size()):
		if not items[i].done: empty.append(items[i].slot)
	if empty.size() >= 2:
		var previous: Rect2 = slots[empty[0]]
		slots[empty[0]] = slots[empty[1]]
		slots[empty[1]] = previous
	shifted = true
	feedback = "Two empty shelf labels moved. The printed names still tell the truth."

func _draw() -> void:
	panel(Rect2(140, 150, 1000, 440), Color("1c272b"))
	label_at("SHELF SHUFFLE  /  NOTHING BEHIND YOU", Vector2(175, 191), 24, YELLOW)
	label_at("DRAG products to matching slots  •  %d / 6 landed  •  %d / 3 errors" % [stocked, wrong], Vector2(175, 227), 20)
	var figure_x = 1042 - (floor(elapsed / 5.0) * 34 if not reduced_motion else 30)
	draw_circle(Vector2(figure_x, 283), 27, Color("131b21"))
	draw_colored_polygon(PackedVector2Array([Vector2(figure_x - 31, 314), Vector2(figure_x + 23, 313),
		Vector2(figure_x + 43, 518), Vector2(figure_x - 52, 518)]), Color("131b21"))
	if elapsed > 6:
		draw_line(Vector2(figure_x - 12, 281), Vector2(figure_x - 8, 282), PURPLE, 2)
		draw_line(Vector2(figure_x + 8, 281), Vector2(figure_x + 12, 282), PURPLE, 2)
	panel(Rect2(178, 251, 394, 282), Color("253437"), BLUE)
	label_at("DELIVERY CRATE", Vector2(195, 273), 17, BLUE)
	var names = ["MINT", "OATS", "SOAP", "RICE", "SALT", "TEA"]
	for i in range(slots.size()):
		var rect = slots[i]
		panel(rect, Color("2a383b"), BLUE)
		draw_rect(Rect2(rect.position + Vector2(0, 87), Vector2(130, 28)), CREAM)
		label_at(names[i], rect.position + Vector2(24, 109), 21, INK)
		for item in items:
			if item.done and item.slot == i:
				_draw_box(rect.position + Vector2(20, 3), item.name, true)
	for i in range(items.size()):
		if not items[i].done and held != i: _draw_box(items[i].pos, items[i].name, false)
	if held >= 0: _draw_box(items[held].pos, items[held].name, false)
	label_at(feedback, Vector2(175, 566), 18, CREAM)

func _draw_box(p: Vector2, title: String, done: bool) -> void:
	draw_rect(Rect2(p + Vector2(4, 5), SIZE), INK)
	draw_colored_polygon(PackedVector2Array([p, p + Vector2(91, 3), p + SIZE, p + Vector2(2, 84)]), GREEN if done else YELLOW)
	draw_rect(Rect2(p, SIZE), INK, false, 3)
	draw_line(p + Vector2(8, 13), p + Vector2(79, 11), INK, 2)
	sprite("product_cereal", Rect2(p + Vector2(15, 4), Vector2(65, 79)), Color(1, 1, 1, 0.8))
	draw_rect(Rect2(p + Vector2(4, 28), Vector2(86, 29)), GREEN if done else YELLOW)
	label_at(title, p + Vector2(14, 51), 21, INK)
	for j in range(10):
		draw_line(p + Vector2(14 + j * 6, 61), p + Vector2(14 + j * 6, 77), INK, 1 + j % 2)
