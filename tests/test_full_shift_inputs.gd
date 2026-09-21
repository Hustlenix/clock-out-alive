extends SceneTree

# End-to-end controller test. Every task is solved by actual keyboard/mouse events
# passed to the same _input handlers used by the running game. No completion
# signal is injected and no gameplay state is set to manufacture a victory.
# Timers are advanced in <=1/60s steps. Reported simulated time is not wall time.
var main
var checks: int = 0
var failures: Array[String] = []
var pace: float = 1.0
var note_read_seconds: float = 8.0
var save_existed: bool = false
var saved_bytes: PackedByteArray = PackedByteArray()
var simulated_task_seconds: Dictionary = {}
var wall_started: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)

func advance(seconds: float) -> void:
	var remaining: float = seconds
	while remaining > 0.00001:
		var delta: float = minf(1.0 / 60.0, remaining)
		main._process(delta)
		if main.state == "task" and is_instance_valid(main.game):
			main.game.set_process(false)
			main.game._process(delta)
		remaining -= delta

func press_button(prefix: String) -> bool:
	for child in main.ui.get_children():
		if child is Button and child.text.begins_with(prefix):
			child.pressed.emit()
			return true
	check(false, "Missing main UI control: " + prefix)
	return false

func key(game, code: int, pressed: bool = true, unicode: int = 0) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.unicode = unicode
	game._input(event)

func mouse_button(game, position: Vector2, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.pressed = pressed
	game._input(event)

func click(game, position: Vector2) -> void:
	mouse_button(game, position, true)
	mouse_button(game, position, false)

func drag(game, from: Vector2, destination: Vector2) -> void:
	mouse_button(game, from, true)
	for step in range(1, 13):
		var event: InputEventMouseMotion = InputEventMouseMotion.new()
		event.position = from.lerp(destination, float(step) / 12.0)
		game._input(event)
		advance(0.035 * pace)
	mouse_button(game, destination, false)
	advance(0.30 * pace)

func play_task(task_id: int) -> void:
	var game = main.game
	var start_time: float = main.shift_seconds
	if task_id != 5: advance(0.65 * pace)
	match task_id:
		0:
			# Alive packages visibly breathe and show a face in this station.
			for product in game.products:
				if not product.alive:
					drag(game, product.pos + game.ITEM_SIZE * 0.5, game.SCANNER.get_center())
		1:
			for spill in game.spills:
				var destination: Vector2 = spill.pos
				for axis in range(2):
					var difference: float = destination[axis] - game.mop[axis]
					var code: int = (KEY_D if difference > 0 else KEY_A) if axis == 0 else (KEY_S if difference > 0 else KEY_W)
					key(game, code)
					advance(absf(difference) / 315.0)
					key(game, code, false)
				# Dwell until this visible puddle has actually disappeared.
				for frame in range(105):
					if spill.clean >= 1.0 or game.finished: break
					advance(1.0 / 60.0)
		2:
			for item in game.items:
				drag(game, item.pos + game.SIZE * 0.5, game.slots[item.slot].get_center())
		3:
			# Read only the switch currently shown as lit during the demonstration.
			var observed: Array[int] = []
			var previous_lit: int = -1
			while game.stage == "watch" and not game.finished:
				if game.lit >= 0 and game.lit != previous_lit:
					observed.append(game.lit)
				previous_lit = game.lit
				advance(1.0 / 60.0)
			check(observed.size() >= 4, "breaker demonstration visibly supplies sequence")
			for number in observed:
				key(game, KEY_1 + number)
				key(game, KEY_1 + number, false)
				advance(0.24 * pace)
		4:
			for visitor in range(3):
				while (game.verdict_wait > 0 or game.inspect_time < 1.02) and not game.finished:
					advance(1.0 / 60.0)
				# Decide from presented ID/roster and visible reflection/shadow evidence.
				var matching: bool = game.profile.card == game.profile.ledger and game.profile.anomaly == "none"
				key(game, KEY_A if matching else KEY_R)
				key(game, KEY_A if matching else KEY_R, false)
		5:
			key(game, KEY_SPACE)
			for step in range(1800):
				if game.finished: break
				key(game, KEY_1 + game.required_lane)
				advance(1.0 / 60.0)
			key(game, KEY_SPACE, false)
		6:
			for capture in range(3):
				advance(0.7 * pace)
				click(game, game.rat)
		7:
			for camera in range(4):
				click(game, Vector2(940, 256 + camera * 55))
				advance(0.2 * pace)
				drag(game, Vector2(236 + game.frequencies[camera] / 100.0 * 586, 496), Vector2(236 + game.targets[camera] / 100.0 * 586, 496))
				advance(0.74)
			if main.index >= 8: check(main.evidence.get("camera4", false), "late Camera4 clue reaches manager")
			else: check(not main.evidence.get("camera4", false), "early Camera4 withholds late clue")
			click(game, Vector2(980, 510))
		8:
			click(game, Vector2(600, 450))
			advance(4.0 * pace)
			click(game, Vector2(500, 377))
		9:
			for character in "ALEX":
				key(game, character.unicode_at(0), true, character.unicode_at(0))
				key(game, character.unicode_at(0), false)
				advance(0.20 * pace)
			key(game, KEY_TAB)
			key(game, KEY_TAB, false)
			for character in "0417":
				key(game, character.unicode_at(0), true, character.unicode_at(0))
				key(game, character.unicode_at(0), false)
				advance(0.20 * pace)
			click(game, Vector2(580, 410))
			advance(0.5 * pace)
			click(game, Vector2(440, 510))
	var span: float = main.shift_seconds - start_time
	simulated_task_seconds[task_id] = float(simulated_task_seconds.get(task_id, 0.0)) + span
	check(game.finished and not game.active, "input resolves duty " + str(main.index + 1))
	check(main.state == "result" and main.last_success, "input succeeds duty " + str(main.index + 1))

func run_shift(reading_seconds: float, motor_pace: float, label: String) -> float:
	note_read_seconds = reading_seconds
	pace = motor_pace
	simulated_task_seconds.clear()
	main.show_menu()
	press_button("NEW SHIFT")
	press_button("TAKE THE KEYS")
	var completed_tasks: int = 0
	var visited_notes: int = 0
	for transition_guard in range(200):
		match main.state:
			"intro": advance(maxf(0.0, main.intro_seconds - main.state_seconds) + 0.001)
			"task":
				main.game.set_process(false)
				play_task(main.schedule[main.index])
				completed_tasks += 1
				if not main.last_success: break
			"result": advance(maxf(0.0, 5.0 - main.state_seconds) + 0.001)
			"note":
				visited_notes += 1
				advance(note_read_seconds)
				press_button("FOLD & KEEP")
			"patrol": advance(maxf(0.0, 13.0 - main.state_seconds) + 0.001)
			"winner", "death": break
			_:
				check(false, "unexpected state " + main.state)
				break
	check(completed_tasks == 18, label + " solves all18 tasks with input")
	check(main.state == "winner", label + " reaches winner")
	check(main.safety == 3 and main.mistakes == 0, label + " loses no safety")
	check(main.notes_seen == 8 and visited_notes == 8, label + " shows all8 notes")
	check(main.evidence.get("camera4", false) and main.evidence.get("phone", false), label + " retains narrative evidence")
	check(main.score > 0 and main.best_score >= main.score, label + " scores and saves best")
	print(label, " simulated shift seconds: ", snappedf(main.shift_seconds, 0.01), " (", int(main.shift_seconds) / 60, ":", "%02d" % (int(main.shift_seconds) % 60), "); note-reading seconds: ", reading_seconds * 8.0)
	print(label, " simulated gameplay by task ID: ", simulated_task_seconds)
	return main.shift_seconds

func run() -> void:
	wall_started = Time.get_ticks_msec()
	save_existed = FileAccess.file_exists("user://last_stop.cfg")
	if save_existed: saved_bytes = FileAccess.get_file_as_bytes("user://last_stop.cfg")
	main = load("res://scripts/main.gd").new()
	root.add_child(main)
	main.set_process(false)
	for attempt in range(120):
		main._process(0.1)
		if main.state == "menu": break
		await process_frame
	check(main.state == "menu", "actual main passes loading before full-shift input run")
	var reading_run: float = run_shift(8.0, 1.0, "READING PACE")
	var fastest_run: float = run_shift(0.0, 0.4, "FAST REPLAY")
	check(fastest_run < reading_run, "skipping optional reading permits faster replay")
	print("Timing is frame-simulated, not a human playthrough. Reading pace uses8 seconds/note; fast replay uses shorter mouse/key intervals and skips optional reading.")
	main.audio.silence()
	main.queue_free()
	await process_frame
	if save_existed:
		var restore = FileAccess.open("user://last_stop.cfg", FileAccess.WRITE)
		restore.store_buffer(saved_bytes)
		restore.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://last_stop.cfg"))
	print("Full-shift input tests: ", checks, " assertions; ", failures.size(), " failures; actual harness wall seconds: ", float(Time.get_ticks_msec() - wall_started) / 1000.0)
	quit(0 if failures.is_empty() else 1)
