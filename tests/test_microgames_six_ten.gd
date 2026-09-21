extends SceneTree

var failures: Array[String] = []
var assertions: int = 0
var current_result: Dictionary = {}
var evidence: Array[String] = []
const GAME_PATH: String = "res://scripts/microgames/"

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)
		print("FAIL: " + message)

func make_game(name: String, level: int, late: bool = true):
	var script = load(GAME_PATH + name + ".gd")
	check(script != null, name + " script loads")
	var game = script.new()
	root.add_child(game)
	game.initialize(level, {"late": late, "evidence": {}, "mistakes": level, "employee_name": "ALEX", "employee_id": "0417", "reduced_motion": true})
	game.set_process(false)
	current_result = {"count": 0, "success": false}
	evidence.clear()
	game.completed.connect(func(success, _reason): current_result["count"] += 1; current_result["success"] = success)
	game.evidence_found.connect(func(key): evidence.append(key))
	game.start()
	return game

func key(game, keycode: int, pressed: bool = true, unicode: int = 0) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	event.pressed = pressed
	event.unicode = unicode
	game._input(event)

func click(game, position: Vector2) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.pressed = true
	game._input(event)
	event.pressed = false
	game._input(event)

func retire(game, name: String, success: bool) -> void:
	check(current_result["count"] == 1, name + " resolves once")
	check(current_result["success"] == success, name + " expected outcome")
	var before: float = game.time_left
	game._process(100.0)
	click(game, Vector2(500, 500))
	key(game, KEY_SPACE)
	game.finish(not success, "deliberate duplicate")
	check(current_result["count"] == 1, name + " cannot resolve twice")
	check(game.time_left == before, name + " timer stops")
	game.free()

func run() -> void:
	for level in range(4):
		for name in ["hold_door", "catch_rat", "tune_cameras", "answer_phone", "clock_out"]:
			var idle = make_game(name, level)
			for step in range(400):
				idle._process(0.1)
			retire(idle, name + " idle failure d" + str(level), false)

		var door = make_game("hold_door", level)
		key(door, KEY_SPACE)
		for step in range(300):
			key(door, KEY_1 + door.required_lane)
			door._process(0.1)
		retire(door, "door bracing d" + str(level), true)

		var rat_game = make_game("catch_rat", level)
		for catch_index in range(3):
			click(rat_game, rat_game.rat)
		retire(rat_game, "rat catch d" + str(level), true)

		var bad_rat = make_game("catch_rat", level)
		bad_rat._process(3.0)
		for catch_index in range(3):
			click(bad_rat, bad_rat.fake_positions[0])
		retire(bad_rat, "rat shadow failure d" + str(level), false)

		var camera = make_game("tune_cameras", level)
		for channel in range(4):
			click(camera, Vector2(940, 256 + channel * 55))
			click(camera, Vector2(236 + camera.targets[channel] / 100.0 * 586, 496))
			camera._process(0.8)
		check(evidence.has("camera4"), "late camera emits clue d" + str(level))
		click(camera, Vector2(980, 510))
		retire(camera, "camera tuning d" + str(level), true)

		var phone = make_game("answer_phone", level)
		click(phone, Vector2(600, 450))
		click(phone, Vector2(500, 377))
		check(evidence.has("phone"), "phone emits evidence d" + str(level))
		retire(phone, "phone answer d" + str(level), true)

		var bad_phone = make_game("answer_phone", level)
		key(bad_phone, KEY_SPACE)
		key(bad_phone, KEY_2)
		retire(bad_phone, "phone wrong answer d" + str(level), false)

		var finale = make_game("clock_out", level)
		for character in "ALEX":
			key(finale, character.unicode_at(0), true, character.unicode_at(0))
		click(finale, Vector2(300, 410))
		for character in "0417":
			key(finale, character.unicode_at(0), true, character.unicode_at(0))
		click(finale, Vector2(580, 410))
		check(finale.id_confirmed, "ID confirmed d" + str(level))
		click(finale, Vector2(440, 510))
		retire(finale, "clock out d" + str(level), true)

	var early_cam = make_game("tune_cameras", 0, false)
	key(early_cam, KEY_4)
	click(early_cam, Vector2(236 + 33.0 / 100.0 * 586, 496))
	early_cam._process(1.0)
	check(not evidence.has("camera4"), "early camera does not reveal late clue")
	early_cam.free()

	var unsigned = make_game("clock_out", 0)
	click(unsigned, Vector2(440, 510))
	check(not unsigned.finished, "unsigned clockout is blocked without ending task")
	unsigned.free()

	var held_door = make_game("hold_door", 0)
	key(held_door, KEY_SPACE)
	held_door.suspend_input()
	check(not held_door.holding_space and not held_door.holding_mouse, "door pause clears held input")
	held_door.free()
	var moving_camera = make_game("tune_cameras", 0)
	key(moving_camera, KEY_RIGHT)
	check(moving_camera.direction == 1, "camera arrow input begins tuning")
	moving_camera.suspend_input()
	check(moving_camera.direction == 0 and not moving_camera.dragging, "camera pause clears held input")
	moving_camera.free()

	print("Microgames 06–10: ", assertions, " assertions; ", failures.size(), " failures.")
	quit(0 if failures.is_empty() else 1)
