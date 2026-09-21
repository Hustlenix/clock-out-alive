extends ShiftMicrogame

var answered: bool = false
var ring_clock: float = 0.0
var pickup: Rect2 = Rect2(474, 412, 325, 70)
var choices: Array[Rect2] = [Rect2(246, 350, 787, 54), Rect2(246, 416, 787, 54), Rect2(246, 482, 787, 54)]
var replies: Array[String] = ["My shift ends at six.", "The store owns my time.", "My name is Alex. I belong here."]

func _setup() -> void:
	duration = 32.0
	answered = false
	ring_clock = 0.0
	feedback = "TASK 09: ANSWER THE PHONE."

func _tick(delta: float) -> void:
	if not answered:
		ring_clock += delta
		if ring_clock >= 2.1 - difficulty * 0.2:
			ring_clock = 0.0
			sound_requested.emit("phone")

func _handle(event: InputEvent) -> void:
	if not answered:
		if clicked(event, pickup) or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE):
			answered = true
			sound_requested.emit("breaker")
			feedback = "M. Voss: Never lend the store your name. Keep your leaving time."
		return
	for index in range(3):
		if clicked(event, choices[index]) or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_1 + index):
			if index == 0:
				evidence_found.emit("phone")
				finish(true, "The caller exhales. ‘Then keep the final minute.’")
			else:
				finish(false, "The caller repeats your answer in your own voice. ‘Agreed.’")
			return

func _draw() -> void:
	panel(Rect2(140, 150, 1000, 440), Color("171d22"), PURPLE)
	label_at("THE VOICE ON LINE 2", Vector2(170, 188), 27, YELLOW)
	label_at("MANAGER RULE: DO NOT ANSWER THE PHONE.", Vector2(170, 222), 23, RED)
	if not answered:
		sprite("phone", Rect2(464, 246, 340, 150))
		panel(Rect2(526, 283, 230, 106), Color("46554e"), CREAM)
		draw_line(Vector2(501, 285), Vector2(779, 289), CREAM, 21)
		draw_line(Vector2(501, 285), Vector2(501, 317), CREAM, 21)
		draw_line(Vector2(779, 289), Vector2(779, 320), CREAM, 21)
		for row in range(3):
			for column in range(3):
				draw_rect(Rect2(591 + column * 31, 310 + row * 22, 17, 12), INK)
		button(pickup, "PICK UP  [SPACE]", YELLOW)
		label_at("The phone has rung exactly once for every worker before you.", Vector2(229, 535), 23, CREAM)
	else:
		label_at("CALLER: ‘The doors close. The lights belong to us.’", Vector2(206, 272), 25, CREAM)
		label_at("‘Who owns the minutes you have left?’", Vector2(266, 313), 28, PURPLE)
		for index in range(3):
			button(choices[index], str(index + 1) + "   " + replies[index], CREAM)
	label_at(feedback, Vector2(170, 572), 21, YELLOW if not answered else GREEN)
