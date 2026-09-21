extends ShiftMicrogame

const ADMIT = Rect2(719, 474, 161, 54)
const REJECT = Rect2(899, 474, 181, 54)
var customers: Array[Dictionary] = []
var customer_index: int = 0
var correct: int = 0
var inspect_time: float = 0.0
var verdict_wait: float = 0.0
var profile: Dictionary = {}

func _setup() -> void:
	duration = 35.0
	customer_index = 0
	correct = 0
	inspect_time = 0.0
	verdict_wait = 0.0
	if difficulty == 0:
		customers = [
			{"name": "MARA", "card": "218", "ledger": "218", "anomaly": "none", "valid": true, "line": "Just milk, please."},
			{"name": "ELI", "card": "306", "ledger": "306", "anomaly": "reflection", "valid": false, "line": "I do not like mirrors."},
			{"name": "NOEL", "card": "419", "ledger": "491", "anomaly": "id", "valid": false, "line": "You already know my number."}]
	else:
		customers = [
			{"name": "JUNE", "card": "582", "ledger": "582", "anomaly": "shadow", "valid": false, "line": "The thing behind me is a coat."},
			{"name": "REMY", "card": "137", "ledger": "137", "anomaly": "none", "valid": true, "line": "My uniform is old. My ID still works."},
			{"name": "MARA", "card": "281", "ledger": "218", "anomaly": "id", "valid": false, "line": "Your manager said to admit everyone."}]
	profile = customers[0]
	feedback = "Match ID to the roster. Reflection and shadow must match the customer."

func _tick(delta: float) -> void:
	inspect_time += delta
	if verdict_wait > 0:
		verdict_wait -= delta
		if verdict_wait <= 0 and customer_index < customers.size():
			profile = customers[customer_index]
			inspect_time = 0.0
			feedback = "Inspect first. Clothes and what they say are not reliable evidence."

func _handle(event: InputEvent) -> void:
	if finished or verdict_wait > 0: return
	var admit = clicked(event, ADMIT)
	var reject = clicked(event, REJECT)
	if event is InputEventKey and event.pressed and not event.echo:
		var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		admit = admit or code == KEY_A
		reject = reject or code == KEY_R
	if not admit and not reject: return
	if inspect_time < 1.0:
		feedback = "Let them stand in the light for a moment."
		sound_requested.emit("paper")
		return
	if admit != profile.valid:
		var reason = "The matching ID and reflection belonged to a real customer."
		if profile.anomaly == "reflection": reason = "The customer raised one hand. The reflection raised the other."
		elif profile.anomaly == "shadow": reason = "The shadow had antlers. The customer did not."
		elif profile.anomaly == "id": reason = "The ID number did not match the name in the roster."
		finish(false, reason)
		return
	correct += 1
	customer_index += 1
	sound_requested.emit("scanner")
	if profile.anomaly != "none": evidence_found.emit("customer_anomaly")
	if customer_index >= customers.size():
		finish(true, "Customers checked. Trust what agrees, not who gives the order.")
	else:
		verdict_wait = 0.8
		feedback = "Correct. The door clicks. The next customer approaches."

func _draw() -> void:
	panel(Rect2(140, 150, 1000, 440), Color("182629"))
	label_at("FRONT DOOR / CHECK THE CUSTOMER", Vector2(175, 191), 23, YELLOW)
	label_at("%d / 3 checked  •  Match the ID, reflection and shadow" % correct, Vector2(175, 227), 21)
	panel(Rect2(180, 249, 265, 281), Color("2a3b40"), BLUE)
	panel(Rect2(462, 249, 224, 281), Color("314047"), BLUE)
	label_at("CUSTOMER", Vector2(198, 276), 17, CREAM)
	label_at("MIRROR", Vector2(479, 276), 17, BLUE)
	var shadow_color = Color("121a20")
	var head = Vector2(366, 350)
	draw_circle(head, 22, shadow_color)
	draw_colored_polygon(PackedVector2Array([head + Vector2(-17, 25), head + Vector2(25, 24), head + Vector2(44, 159), head + Vector2(-18, 154)]), shadow_color)
	if profile.get("anomaly", "") == "shadow":
		for sign_value in [-1, 1]:
			draw_line(head + Vector2(sign_value * 13, -11), head + Vector2(sign_value * 33, -37), shadow_color, 7)
			draw_line(head + Vector2(sign_value * 22, -23), head + Vector2(sign_value * 16, -44), shadow_color, 5)
	_draw_person(Vector2(286, 351), false, false)
	_draw_person(Vector2(571, 351), true, profile.get("anomaly", "") == "reflection")
	label_at("Hand at the mirror", Vector2(480, 509), 15, CREAM)
	panel(Rect2(711, 249, 382, 91), Color("d1c8a7"), YELLOW)
	label_at("VISITOR ID", Vector2(729, 275), 18, INK)
	label_at("%s     # %s" % [profile.get("name", ""), profile.get("card", "")], Vector2(729, 316), 29, INK)
	panel(Rect2(711, 352, 382, 67), Color("263638"), BLUE)
	label_at("ROSTER:  %s / %s" % [profile.get("name", ""), profile.get("ledger", "")], Vector2(729, 393), 23, CREAM)
	label_at('"%s"' % profile.get("line", ""), Vector2(715, 448), 17, PURPLE)
	button(ADMIT, "A  ADMIT", GREEN)
	button(REJECT, "R  REJECT", RED)
	label_at(feedback, Vector2(175, 566), 18, CREAM)

func _draw_person(p: Vector2, mirror: bool, wrong: bool) -> void:
	var skin = Color("bbb393") if mirror else CREAM
	var coat = BLUE if mirror else Color("526d73")
	draw_colored_polygon(PackedVector2Array([p + Vector2(-34, 48), p + Vector2(28, 46), p + Vector2(44, 132), p + Vector2(-45, 133)]), coat)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-25, -21), p + Vector2(22, -26), p + Vector2(27, 17), p + Vector2(12, 41), p + Vector2(-22, 30)]), skin)
	draw_line(p + Vector2(-28, -24), p + Vector2(24, -27), INK, 9)
	draw_line(p + Vector2(-27, -24), p + Vector2(-29, -5), INK, 7)
	draw_circle(p + Vector2(-11, 0), 3, INK)
	draw_circle(p + Vector2(10, -1), 3, INK)
	draw_line(p + Vector2(-5, 22), p + Vector2(9, 20), INK, 2)
	var raised_side = -1 if mirror and not wrong else 1
	draw_line(p + Vector2(raised_side * 29, 58), p + Vector2(raised_side * 53, 42), coat, 18)
	draw_line(p + Vector2(raised_side * 53, 42), p + Vector2(raised_side * 59, 10), coat, 15)
	draw_circle(p + Vector2(raised_side * 60, 0), 12, skin)
	for i in range(4):
		draw_line(p + Vector2(raised_side * (52 + i * 5), -2), p + Vector2(raised_side * (50 + i * 6), -17 - (i % 2) * 3), skin, 4)
	draw_line(p + Vector2(-raised_side * 28, 60), p + Vector2(-raised_side * 43, 112), coat, 18)
	if mirror:
		draw_line(p + Vector2(-83, -50), p + Vector2(-45, -90), Color("6f8284"), 3)
		draw_line(p + Vector2(31, 98), p + Vector2(69, 58), Color("6f8284"), 3)
