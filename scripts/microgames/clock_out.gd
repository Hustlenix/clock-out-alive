extends ShiftMicrogame

var signature: String = ""
var id_entry: String = ""
var field: int = 0
var id_confirmed: bool = false
var expected_name: String = "ALEX"
var expected_id: String = "0417"
var ring_clock: float = 0.0
var name_rect: Rect2 = Rect2(216, 283, 481, 58)
var id_rect: Rect2 = Rect2(216, 382, 271, 58)
var confirm_rect: Rect2 = Rect2(507, 382, 190, 58)
var out_rect: Rect2 = Rect2(216, 478, 481, 68)
var fake_rect: Rect2 = Rect2(808, 464, 280, 60)

func _setup() -> void:
	duration = 35.0
	signature = ""
	id_entry = ""
	field = 0
	id_confirmed = false
	expected_name = str(context.get("employee_name", "ALEX")).to_upper()
	expected_id = str(context.get("employee_id", "0417"))
	ring_clock = 0.0
	feedback = "Sign your payroll card, confirm your ID, then CLOCK OUT."

func _tick(delta: float) -> void:
	ring_clock += delta
	if ring_clock >= 5.0 - difficulty * 0.4:
		ring_clock = 0.0
		sound_requested.emit("phone" if int(elapsed) % 2 == 0 else "bang")

func verify_id() -> void:
	if id_entry == expected_id:
		id_confirmed = true
		sound_requested.emit("scanner")
		feedback = "ID confirmed. Your last task is the large CLOCK OUT button."
	else:
		id_confirmed = false
		feedback = "Check the badge on the right. ID needs all four digits."

func _handle(event: InputEvent) -> void:
	if clicked(event, name_rect):
		field = 0
	elif clicked(event, id_rect):
		field = 1
	elif clicked(event, confirm_rect):
		verify_id()
	elif clicked(event, out_rect):
		if signature.strip_edges().to_upper() != expected_name:
			field = 0
			feedback = "Sign your own name exactly as printed on your badge."
		elif not id_confirmed:
			field = 1
			feedback = "Confirm your employee ID before ending the shift."
		else:
			finish(true, "06:00 AM. Your time belongs to you.")
	elif clicked(event, fake_rect):
		feedback = "That request is not on your payroll card. Finish your own shift."
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_TAB and not event.echo:
			field = 1 - field
			return
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if field == 0:
				field = 1
			else:
				verify_id()
			return
		if event.keycode == KEY_BACKSPACE:
			if field == 0:
				signature = signature.left(maxi(0, signature.length() - 1))
			else:
				id_entry = id_entry.left(maxi(0, id_entry.length() - 1))
				id_confirmed = false
			return
		if event.ctrl_pressed or event.alt_pressed or event.meta_pressed:
			return
		if event.unicode >= 32 and event.unicode <= 126:
			var character: String = String.chr(event.unicode).to_upper()
			if field == 0 and signature.length() < 18 and (character >= "A" and character <= "Z" or character == " "):
				signature += character
			elif field == 1 and id_entry.length() < 4 and character >= "0" and character <= "9":
				id_entry += character
				id_confirmed = false

func _draw() -> void:
	panel(Rect2(140, 150, 1000, 440), Color("20272a"), BLUE)
	label_at("5:59 AM  /  EMPLOYEE SIGN-OUT", Vector2(170, 188), 28, YELLOW)
	label_at("Your signature stays on your payroll card. Do not speak it to the store.", Vector2(170, 224), 21, CREAM)
	label_at("1. TYPE YOUR NAME", Vector2(216, 273), 21, CREAM)
	panel(name_rect, INK, YELLOW if field == 0 else BLUE)
	label_at(signature + ("_" if field == 0 else ""), name_rect.position + Vector2(18, 39), 30, CREAM)
	label_at("2. EMPLOYEE ID", Vector2(216, 372), 21, CREAM)
	panel(id_rect, INK, YELLOW if field == 1 else BLUE)
	label_at(id_entry + ("_" if field == 1 else ""), id_rect.position + Vector2(18, 39), 30, CREAM)
	button(confirm_rect, "CONFIRMED" if id_confirmed else "CONFIRM", GREEN if id_confirmed else YELLOW)
	label_at("3. LEAVE ON TIME", Vector2(216, 469), 21, CREAM)
	button(out_rect, "CLOCK OUT", GREEN)
	panel(Rect2(776, 254, 312, 155), Color("ded5ad"), YELLOW)
	label_at("THE LAST STOP", Vector2(801, 284), 24, INK)
	label_at("EMPLOYEE: " + expected_name, Vector2(801, 321), 23, INK)
	label_at("ID: " + expected_id, Vector2(801, 354), 25, INK)
	label_at("SHIFT ENDS 06:00", Vector2(801, 387), 23, INK)
	if elapsed > 3.0:
		var faint: Color = PURPLE.darkened(0.32)
		label_at("MANAGER REQUEST", Vector2(808, 452), 21, faint)
		button(fake_rect, "STAY A LITTLE LONGER", faint)
	if elapsed > 7.0:
		draw_circle(Vector2(1096, 295), 19, INK)
		draw_line(Vector2(1096, 310), Vector2(1100, 414), INK, 23)
		if int(context.get("mistakes", 0)) > 0:
			draw_circle(Vector2(753, 328), 16, INK)
			draw_line(Vector2(753, 341), Vector2(759, 414), INK, 17)
	label_at(feedback, Vector2(170, 578), 21, CREAM)
