extends SceneTree

# Integration tests advance manager time explicitly. Input-driven microgame paths
# live in test_microgames_*.gd; this suite tests the actual Main scene controller.
var checks: int = 0
var failures: Array[String] = []
var main
var save_existed: bool = false
var saved_bytes: PackedByteArray = PackedByteArray()

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		print("FAIL: ", message)

func advance_to_task() -> void:
	if main.state == "result": main._process(5.1)
	if main.state == "note": main.show_patrol()
	if main.state == "patrol": main._process(13.1)
	if main.state == "intro": main._process(2.6)
	if is_instance_valid(main.game): main.game.set_process(false)

func key(game, code: int) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	game._input(event)

func run() -> void:
	save_existed = FileAccess.file_exists("user://last_stop.cfg")
	if save_existed: saved_bytes = FileAccess.get_file_as_bytes("user://last_stop.cfg")
	var script = load("res://scripts/main.gd")
	check(script != null, "actual main controller loads")
	main = script.new()
	root.add_child(main)
	main.set_process(false)
	check(main.state == "loading", "launch begins on loading screen")
	main._process(1.0)
	check(main.state == "loading" and main.load_progress <= 0.4, "loading progress is smoothed, gameplay remains blocked")
	for attempt in range(120):
		main._process(0.1)
		if main.state == "menu": break
		await process_frame
	check(main.state == "menu" and main.load_progress >= 1.0, "loading reaches100 and opens menu")
	check(main.textures.size() == 4, "all four loading resources were actually loaded")
	main.show_briefing()
	check(main.state == "briefing", "new shift opens manager rules")
	main.new_shift()
	check(main.safety == 3 and main.score == 0 and main.index == 0 and main.mistakes == 0, "new shift initializes resources")
	check(main.schedule.size() == 18, "full shift contains18 assignments")
	check(main.schedule[7] == 7 and main.schedule[15] == 7 and main.schedule[16] == 8 and main.schedule[17] == 9, "cameras precede phone and clockout")

	# Hold-door pause uses real SceneTree pausing, not a mocked timer.
	main.index = 5
	main.show_intro()
	advance_to_task()
	var door = main.game
	key(door, KEY_SPACE)
	check(door.holding_space, "door input enters held state")
	door.set_process(true)
	var before_pause: float = door.time_left
	main.show_pause()
	check(main.is_paused and paused, "pause pauses the SceneTree")
	check(not door.holding_space and not door.holding_mouse, "pause releases door input")
	main._process(2.0)
	await create_timer(0.06).timeout
	check(is_equal_approx(door.time_left, before_pause), "task timer does not advance during real pause")
	main.show_settings("pause")
	main.reduced_motion = true
	main.update_game_settings()
	check(door.reduced_motion, "reduced motion reaches active task")
	main.audio.set_volume(0.0)
	check(AudioServer.is_bus_mute(0), "zero volume actually mutes audio bus")
	main.audio.set_volume(0.5)
	check(not AudioServer.is_bus_mute(0), "raising volume unmutes audio bus")
	main.volume = 0.42
	main.write_save()
	main.volume = 0.1
	main.reduced_motion = false
	main.read_save()
	check(is_equal_approx(main.volume, 0.42) and main.reduced_motion, "settings roundtrip through local save")
	main.show_pause()
	main.resume_shift()
	check(main.state == "task" and not paused and not main.is_paused, "resume returns to same task")
	await create_timer(0.06).timeout
	check(door.time_left < before_pause, "task timer resumes after pause")
	door.set_process(false)
	for control in main.ui.get_children():
		if control is Button and control.text == "II": check(control.focus_mode == Control.FOCUS_NONE, "pause button cannot steal finale Tab/Enter")

	main.evidence["camera4"] = true
	main.score = 999
	main.safety = 1
	main.mistakes = 2
	main.show_pause()
	main.new_shift()
	check(not paused and not main.is_paused and main.safety == 3 and main.score == 0 and main.mistakes == 0 and main.evidence.is_empty() and main.notes_seen == 0, "restart from pause fully resets run")
	check(door.is_queued_for_deletion(), "restart cleans previous task node")
	await process_frame
	check(not is_instance_valid(door), "previous task actually freed")

	for duty in range(18):
		advance_to_task()
		check(main.state == "task" and main.index == duty, "assignment " + str(duty + 1) + " launches in order")
		check(main.game.difficulty == (1 if duty >= 8 else 0), "second pass increases difficulty " + str(duty + 1))
		var previous_score: int = main.score
		main.game.finish(true, "Integration test completion")
		check(main.state == "result" and main.score > previous_score, "success advances and scores duty " + str(duty + 1))
		var awarded: int = main.score
		main.game.finish(true, "Duplicate completion")
		check(main.score == awarded, "duplicate completion cannot award score " + str(duty + 1))
	main._process(5.1)
	check(main.state == "winner" and main.safety == 3, "full shift reaches winner")
	check(main.notes_seen == 8, "all eight notes appear")
	check(main.best_score >= main.score, "winner updates best score")
	var best: int = main.best_score
	main.best_score = 0
	main.read_save()
	check(main.best_score == best, "best score persists to disk")
	main._process(6.1)
	check(main.ending_reveal and main.ui.get_child_count() > 0, "winner receipt and replay controls appear")
	main.new_shift()
	check(main.state == "intro" and main.best_score == best, "winner replay starts fresh and keeps best")
	main.index = 17
	main.show_intro()
	advance_to_task()
	main.game.finish(false, "Failed sign-out")
	main._process(5.1)
	check(main.state == "intro" and main.index == 17 and main.safety == 2, "failed finale retries clockout while safety remains")
	advance_to_task()
	main.game.finish(true, "Corrected sign-out")
	main._process(5.1)
	check(main.state == "winner", "retried finale can reach winner")
	main.new_shift()

	for mistake in range(3):
		advance_to_task()
		main.game.finish(false, "Integration test incident")
		check(main.safety == 2 - mistake and main.mistakes == mistake + 1, "failed task costs exactly one safety and persists consequence")
		check(main.audio.ambience.volume_db >= -19.0, "failure changes persistent ambience")
		main._process(5.1)
	check(main.state == "death", "three failures reach death")
	main._process(6.1)
	check(main.ending_reveal, "death reveal exposes replay and optional scare")
	main.optional_scare()
	check(float(main.get_meta("scare_until")) > main.total_seconds, "look behind you starts optional scare")
	main.show_menu()
	check(main.state == "menu" and not is_instance_valid(main.game), "death main menu clears active game")
	main.start_practice(8)
	advance_to_task()
	main.game.finish(false, "practice failure")
	check(main.practice and main.safety == 3 and main.mistakes == 0 and main.score == 0, "practice failures do not affect shift score or safety")
	main.show_menu()

	for seed_value in range(12):
		seed(seed_value)
		main.new_shift()
		check(main.schedule[0] == 0 and main.schedule[3] == 3 and main.schedule[7] == 7 and main.schedule[15] == 7 and main.schedule[16] == 8 and main.schedule[17] == 9, "shuffle preserves narrative dependencies")
		check(main.schedule.slice(0, 8).duplicate().size() == 8 and main.schedule[1] != main.schedule[2] and main.schedule[9] != main.schedule[10], "shuffle preserves both household jobs")
	main.show_menu()
	main.audio.silence()
	main.queue_free()
	await process_frame
	if save_existed:
		var restore = FileAccess.open("user://last_stop.cfg", FileAccess.WRITE)
		restore.store_buffer(saved_bytes)
		restore.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://last_stop.cfg"))
	print("Shift integration: ", checks, " assertions; ", failures.size(), " failures.")
	quit(0 if failures.is_empty() else 1)
