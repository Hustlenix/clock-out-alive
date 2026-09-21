extends ShiftMicrogame

const SCANNER = Rect2(925, 359, 165, 135)
const ITEM_SIZE = Vector2(90, 111)
var products: Array[Dictionary] = []
var held: int = -1
var hold_offset := Vector2.ZERO
var scanned: int = 0
var required: int = 5
var last_scan: float = -10.0

func _setup() -> void:
	duration = 32.0
	products.clear()
	held = -1
	scanned = 0
	last_scan = -10.0
	required = 5 + mini(difficulty, 2)
	var names = ["MILK", "BEANS", "OATS", "SALT", "SOAP", "TEA", "RICE"]
	for i in range(required + 1):
		var home = Vector2(200 + (i % 4) * 158, 258 + (i / 4) * 155)
		products.append({"pos": home, "home": home, "alive": i == 2,
			"name": "SOUP" if i == 2 else names[i if i < 2 else i - 1], "done": false})
	feedback = "Scan every sealed product. Leave the breathing package alone."

func suspend_input() -> void:
	if held >= 0:
		products[held].pos = products[held].home
	held = -1
	queue_redraw()

func _handle(event: InputEvent) -> void:
	if finished:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			for i in range(products.size() - 1, -1, -1):
				if not products[i].done and Rect2(products[i].pos, ITEM_SIZE).has_point(event.position):
					held = i
					hold_offset = event.position - products[i].pos
					sound_requested.emit("paper")
					break
		elif held >= 0:
			products[held].pos = event.position - hold_offset
			_try_scan()
			if held >= 0:
				products[held].pos = products[held].home
				held = -1
	elif event is InputEventMouseMotion and held >= 0:
		products[held].pos = event.position - hold_offset
		_try_scan()
	queue_redraw()

func _try_scan() -> void:
	if held < 0 or not SCANNER.has_point(products[held].pos + ITEM_SIZE * 0.5):
		return
	if products[held].alive:
		held = -1
		finish(false, "It had a heartbeat. The scanner gave it a name.")
		return
	products[held].done = true
	held = -1
	scanned += 1
	last_scan = elapsed
	sound_requested.emit("scanner")
	feedback = "%d / %d scanned. The remaining package is still breathing." % [scanned, required]
	if scanned == required:
		evidence_found.emit("living_stock")
		finish(true, "Stock checked. One product was never on the invoice.")

func _draw() -> void:
	panel(Rect2(140, 150, 1000, 440), Color("172326"))
	sprite("checkout", Rect2(150, 160, 980, 420), Color(1, 1, 1, 0.20))
	label_at("REGISTER 02  /  STOCK INTAKE", Vector2(175, 192), 23, YELLOW)
	label_at("DRAG across the scanner  •  Do not scan anything that breathes", Vector2(175, 227), 20)
	draw_line(Vector2(173, 532), Vector2(1110, 529), BLUE, 4)
	panel(SCANNER, Color("26383a"), GREEN)
	for j in range(7):
		draw_line(Vector2(944 + j * 21, 380), Vector2(944 + j * 21, 460), Color("34464a"), 2)
	draw_line(Vector2(938, 423), Vector2(1077, 423), GREEN if elapsed - last_scan < 0.35 else RED, 4)
	label_at("SCANNER", Vector2(951, 482), 22, GREEN)
	label_at("%02d / %02d" % [scanned, required], Vector2(952, 325), 28, GREEN)
	for i in range(products.size()):
		if products[i].done or i == held:
			continue
		_draw_product(i)
	if held >= 0:
		_draw_product(held)
	label_at(feedback, Vector2(175, 566), 19, CREAM)

func _draw_product(index: int) -> void:
	var item: Dictionary = products[index]
	var p: Vector2 = item.pos
	var breathing = sin(elapsed * 3.6) * (4.0 if item.alive else 0.0)
	if reduced_motion:
		breathing = 2.0 if item.alive else 0.0
	var box = Rect2(p - Vector2(breathing, 0), ITEM_SIZE + Vector2(breathing * 2, 0))
	draw_rect(Rect2(box.position + Vector2(5, 7), box.size), INK)
	draw_colored_polygon(PackedVector2Array([box.position, box.position + Vector2(box.size.x - 4, 2), box.end,
		box.position + Vector2(3, box.size.y - 1)]), YELLOW if index % 2 == 0 else BLUE)
	draw_rect(box, INK, false, 3)
	var art_key = "product_can" if index % 3 == 0 else ("product_milk" if index % 3 == 1 else "product_cereal")
	sprite(art_key, Rect2(p + Vector2(8, 7), Vector2(74, 87)), Color(1, 1, 1, 0.65))
	draw_rect(Rect2(p + Vector2(3, 39), Vector2(84, 35)), CREAM)
	var title: String = item.name
	if item.alive and (difficulty == 0 or int(elapsed * 1.3) % 3 == 0):
		title = "LET ME OUT"
	label_at(title, p + Vector2(6, 62), 13 if title.length() > 5 else 19, INK)
	if item.alive:
		draw_line(p + Vector2(16, 91), p + Vector2(30, 91), INK, 2)
		draw_line(p + Vector2(30, 91), p + Vector2(36, 83), INK, 2)
		draw_line(p + Vector2(36, 83), p + Vector2(43, 100), INK, 2)
		draw_line(p + Vector2(43, 100), p + Vector2(50, 91), INK, 2)
		draw_line(p + Vector2(50, 91), p + Vector2(75, 91), INK, 2)
	else:
		for j in range(13):
			draw_line(p + Vector2(13 + j * 5, 84), p + Vector2(13 + j * 5, 101), INK, 1 + j % 2)
