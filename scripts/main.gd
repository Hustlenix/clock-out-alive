extends Node2D

const BASE = preload("res://scripts/microgame.gd")
const STORY = preload("res://scripts/story_manager.gd")
const AUDIO = preload("res://scripts/audio_manager.gd")
const TASKS = [
	["LIVING LABELS", "Drag the groceries through the scanner.\nOne package has a heartbeat. Build a clean streak without waking it.", "MOUSE / DRAG", "scan_stock"],
	["SHADOW SLALOM", "Sweep every glowing puddle while the floor-shadow darts.\nKeep moving and do not let it tag your boots.", "WASD / ARROW KEYS", "mop_spill"],
	["SHELF SHUFFLE", "Throw each product into the matching slot.\nThe aisle rearranges itself when you blink.", "MOUSE / DRAG", "restock_aisle"],
	["VOLTAGE MEMORY", "Watch the breaker lights, then replay the sequence.\nOne fake switch wants you to press it.", "1-6 / MOUSE", "fix_breaker"],
	["WHO GOES THERE?", "Admit a real customer or reject the anomaly.\nTrust the evidence, not the confident voice.", "MOUSE / ADMIT OR REJECT", "check_customer"],
	["BARRICADE BASH", "Brace the stockroom while something pounds back.\nChase the warning mark before the pressure spikes.", "SPACE + A / D / ARROWS", "hold_door"],
	["RAT RACE", "Click the real rat three times before the shadows bait you.\nWarm eyes and a long tail are your tell.", "MOUSE / CLICK", "catch_rat"],
	["SIGNAL HUNT", "Tune three feeds and decide whether to break the rule.\nCamera 4 may reveal the fastest route out.", "MOUSE / DRAG OR ARROWS", "tune_cameras"],
	["THE VOICE ON LINE 2", "Pick up the impossible call and outsmart the question.\nYour answer changes what the store owns.", "MOUSE / CHOOSE YOUR WORDS", "answer_phone"],
	["ESCAPE THE SHIFT", "Sign your name, confirm your badge, and bolt.\nThe store gets one last chance to distract you.", "TYPE ALEX / MOUSE", "clock_out"]
]
const CREAM = Color("e6ddb7")
const GREEN = Color("b8cc83")
const YELLOW = Color("e7bf5d")
const RED = Color("d77868")
const INK = Color("101820")
const MUTED = Color("819295")
const PURPLE = Color("bd8fba")

var state: String = "loading"
var overlay_return: String = "menu"
var ui: Control
var hud: Control
var font: Font = ThemeDB.fallback_font
var audio: ShiftAudio
var game: ShiftMicrogame
var schedule: Array[int] = []
var index: int = 0
var safety: int = 3
var mistakes: int = 0
var score: int = 0
var best_score: int = 0
var streak: int = 0
var best_streak: int = 0
var shift_seconds: float = 0.0
var state_seconds: float = 0.0
var total_seconds: float = 0.0
var last_success: bool = false
var last_reason: String = ""
var last_bonus: String = ""
var notes_seen: int = 0
var evidence: Dictionary = {}
var volume: float = 0.65
var reduced_motion: bool = false
var is_paused: bool = false
var practice: bool = false
var practice_id: int = 0
var load_progress: float = 0.0
var load_paths: Array[String] = ["res://assets/art/exterior.png", "res://assets/art/interior.png", "res://assets/art/ending_winner.png", "res://assets/art/ending_death.png"]
var textures: Dictionary = {}
var cursor_texture: Texture2D
var ending_reveal: bool = false
var intro_seconds: float = 2.5
var review_label: Label
var patrol_flavor: Label
var menu_button: Button
var trace: Array[String] = []
var paused_ui: Control
var paused_review: Label
var paused_flavor: Label
var patrol_return_seconds: float = 0.0
var notebook_page: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	RenderingServer.set_default_clear_color(INK)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.z_index = 20
	add_child(ui)
	audio = AUDIO.new()
	add_child(audio)
	read_save()
	configure_inputs()
	audio.set_volume(volume)
	for path in load_paths:
		if ResourceLoader.exists(path): ResourceLoader.load_threaded_request(path)
	show_loading()

func configure_inputs() -> void:
	var bindings = {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "brace": [KEY_SPACE], "pause_shift": [KEY_ESCAPE]}
	for action in bindings:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for code in bindings[action]:
			var event = InputEventKey.new()
			event.physical_keycode = code
			if not InputMap.action_has_event(action, event): InputMap.action_add_event(action, event)
	if ResourceLoader.exists("res://assets/art/cursor.png"):
		cursor_texture = load("res://assets/art/cursor.png")
		Input.set_custom_mouse_cursor(cursor_texture)

func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null)
	cursor_texture = null

func read_save() -> void:
	var save = ConfigFile.new()
	if save.load("user://last_stop.cfg") == OK:
		best_score = int(save.get_value("shift", "best", 0))
		volume = float(save.get_value("settings", "volume", 0.65))
		reduced_motion = bool(save.get_value("settings", "reduced_motion", false))

func write_save() -> void:
	var save = ConfigFile.new()
	save.set_value("shift", "best", best_score)
	save.set_value("settings", "volume", volume)
	save.set_value("settings", "reduced_motion", reduced_motion)
	save.save("user://last_stop.cfg")

func clear_ui() -> void:
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	review_label = null
	patrol_flavor = null

func switch_to(next: String) -> void:
	state = next
	state_seconds = 0.0
	trace.append(next)
	clear_ui()
	queue_redraw()

func text_ui(value: String, rect: Rect2, size: int = 24, color: Color = CREAM) -> Label:
	var label = Label.new()
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(label)
	return label

func sheet(rect: Rect2, color: Color = INK, border: Color = MUTED) -> void:
	var panel = Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	ui.add_child(panel)

func add_button(value: String, rect: Rect2, action: Callable, color: Color = GREEN) -> Button:
	var control = Button.new()
	control.text = value
	control.clip_text = true
	control.position = rect.position
	control.size = rect.size
	control.focus_mode = Control.FOCUS_ALL
	var button_size = 22
	while button_size > 14 and font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, button_size).x > rect.size.x - 40:
		button_size -= 1
	control.add_theme_font_size_override("font_size", button_size)
	control.add_theme_color_override("font_color", color)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("172429")
	style.border_color = color
	style.set_border_width_all(2)
	style.content_margin_left = 18
	style.content_margin_right = 18
	control.add_theme_stylebox_override("normal", style)
	var hover = style.duplicate()
	hover.bg_color = Color("304342")
	control.add_theme_stylebox_override("hover", hover)
	control.add_theme_stylebox_override("pressed", hover)
	control.pressed.connect(func(): audio.play("paper"); action.call())
	ui.add_child(control)
	return control

func show_loading() -> void:
	clear_ui()

func show_menu() -> void:
	discard_pause_ui()
	end_game_node()
	audio.silence()
	is_paused = false
	get_tree().paused = false
	switch_to("menu")
	sheet(Rect2(48, 45, 520, 620), Color("101820ec"), Color("405350"))
	text_ui("THE LAST STOP PRESENTS", Rect2(82, 67, 440, 35), 18, GREEN)
	var title_art = TextureRect.new()
	title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_art.texture = load("res://assets/art/logo.png")
	title_art.position = Vector2(77, 133)
	title_art.size = Vector2(472, 130)
	title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(title_art)
	text_ui("THE GRAVEYARD SHIFT", Rect2(82, 278, 445, 38), 26, YELLOW)
	text_ui("Your shift ends at 6 AM.\nThe store does not.", Rect2(84, 329, 410, 80), 24)
	add_button("NEW SHIFT", Rect2(82, 418, 440, 58), show_briefing)
	add_button("HOW TO SURVIVE", Rect2(82, 489, 440, 48), show_instructions)
	add_button("SETTINGS", Rect2(82, 550, 213, 46), func(): show_settings("menu"))
	add_button("CREDITS", Rect2(309, 550, 213, 46), show_credits)
	text_ui("BEST %05d    •    HEADPHONES SUGGESTED" % best_score, Rect2(83, 615, 446, 30), 16, MUTED)
	text_ui("OPEN 24 HOURS\nSTAFF WANTED", Rect2(900, 556, 300, 88), 24, YELLOW)

func show_instructions() -> void:
	switch_to("instructions")
	sheet(Rect2(90, 58, 1100, 601))
	text_ui("EMPLOYEE ORIENTATION", Rect2(125, 80, 1000, 55), 38, YELLOW)
	text_ui("This is an arcade shift: chase streaks, spot impossible clues, and take risky shortcuts for bonus points.\nThe clock advances between challenges. Read the old notes. Watch what changes.\nESC pauses • Mouse and keyboard • Your badge: ALEX / 0417", Rect2(125, 149, 1000, 125), 23)
	text_ui("OPTIONAL PRACTICE - choose a station, with no score or safety cost", Rect2(125, 298, 1000, 35), 19, MUTED)
	for n in range(10):
		var id = n
		add_button("%02d / %s" % [n + 1, TASKS[n][0]], Rect2(125 + (n % 2) * 512, 348 + (n / 2) * 48, 490, 40), func(): start_practice(id), GREEN)
	add_button("BACK", Rect2(125, 605, 180, 38), show_menu)

func show_credits() -> void:
	switch_to("credits")
	sheet(Rect2(175, 98, 930, 525))
	text_ui("AFTER HOURS / CREDITS", Rect2(215, 135, 820, 55), 37, YELLOW)
	text_ui("Design brief: the creator of this project\nCode, original raster drawings and original synthesized audio: Codex\n\nAll images are authored raster primitives, made with Pillow.\nNo stock assets, AI-generated finished images or borrowed music.\nArt source and sound synthesis are included in source_art/.\n\nEngine: Godot 4.7.1 • Open-source MIT engine\nBuilt with AI assistance. Thank you for staying until morning.", Rect2(215, 213, 820, 300), 23)
	add_button("MAIN MENU", Rect2(215, 549, 280, 48), show_menu)

func show_settings(return_state: String) -> void:
	overlay_return = return_state
	switch_to("settings")
	sheet(Rect2(285, 125, 710, 475))
	text_ui("A LITTLE LESS NOISE", Rect2(330, 157, 640, 57), 36, YELLOW)
	text_ui("MASTER VOLUME", Rect2(330, 248, 580, 35), 23)
	var slider = HSlider.new()
	slider.position = Vector2(330, 297)
	slider.size = Vector2(575, 40)
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.01
	slider.value = volume
	slider.value_changed.connect(func(value): volume = value; audio.set_volume(value); write_save())
	ui.add_child(slider)
	var check = CheckButton.new()
	check.text = "REDUCED MOTION / STEADY LIGHTS"
	check.position = Vector2(320, 379)
	check.size = Vector2(620, 55)
	check.button_pressed = reduced_motion
	check.add_theme_font_size_override("font_size", 22)
	check.toggled.connect(func(value): reduced_motion = value; write_save(); update_game_settings())
	ui.add_child(check)
	text_ui("Keeps all clues visible. Stops flicker, rain motion and camera shake.", Rect2(330, 450, 570, 58), 18, MUTED)
	add_button("DONE", Rect2(330, 524, 280, 48), func():
		if overlay_return == "pause": show_pause()
		else: show_menu())

func update_game_settings() -> void:
	if is_instance_valid(game): game.reduced_motion = reduced_motion

func show_briefing() -> void:
	audio.begin()
	practice = false
	switch_to("briefing")
	sheet(Rect2(290, 48, 700, 623), Color("d5cdb0"), Color("695d47"))
	text_ui("MANAGER'S INSTRUCTIONS", Rect2(333, 85, 620, 48), 34, INK)
	text_ui("FINISH EVERYTHING BEFORE 6:00 AM.\n\nDO NOT OPEN THE BACK DOOR.\n\nDO NOT ANSWER THE PHONE.\n\nDO NOT LOOK AT CAMERA 4\nAFTER 3:33 AM.", Rect2(333, 165, 600, 300), 27, INK)
	text_ui("Your badge: ALEX / 0417\nThree safety marks. Eighteen arcade challenges. One exit.\nChain quick clears for bigger streak bonuses.", Rect2(333, 496, 600, 80), 20, Color("49483e"))
	add_button("TAKE THE KEYS", Rect2(333, 594, 605, 51), new_shift)

func new_shift() -> void:
	discard_pause_ui()
	end_game_node()
	get_tree().paused = false
	is_paused = false
	practice = false
	safety = 3
	mistakes = 0
	score = 0
	streak = 0
	best_streak = 0
	index = 0
	notes_seen = 0
	evidence.clear()
	shift_seconds = 0
	ending_reveal = false
	schedule = [0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
	# Shuffle only equivalent household jobs; keep every narrative dependency.
	if randi() % 2 == 0:
		schedule[1] = 2
		schedule[2] = 1
	if randi() % 2 == 0:
		schedule[9] = 2
		schedule[10] = 1
	audio.begin()
	show_intro()

func start_practice(id: int) -> void:
	end_game_node()
	practice = true
	practice_id = id
	index = 0
	schedule = [id]
	safety = 3
	mistakes = 0
	score = 0
	streak = 0
	best_streak = 0
	evidence = {"camera4": true}
	audio.begin()
	show_intro()

func show_intro() -> void:
	switch_to("intro")
	var data = TASKS[schedule[index]]
	sheet(Rect2(255, 156, 770, 409), Color("d5cdb0"), Color("6e6049"))
	text_ui("ARCADE CHALLENGE %02d  /  %s" % [schedule[index] + 1, "HARD MODE" if index >= 8 else "NIGHT SHIFT"], Rect2(295, 185, 680, 43), 21, Color("615745"))
	text_ui(data[0], Rect2(295, 243, 680, 59), 36, INK)
	text_ui(data[1], Rect2(295, 327, 680, 113), 26, INK)
	text_ui(data[2], Rect2(295, 467, 680, 40), 23, Color("615745"))
	text_ui("QUICK CLEAR = STREAK BONUS     •     RISKY CLUE = EXTRA SCORE", Rect2(295, 514, 680, 30), 18, Color("615745"))
	audio.play("paper")

func launch_task() -> void:
	switch_to("task")
	var script = load("res://scripts/microgames/" + TASKS[schedule[index]][3] + ".gd")
	game = script.new()
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(game)
	game.z_index = 5
	game.completed.connect(on_task_completed)
	game.sound_requested.connect(audio.play)
	game.evidence_found.connect(func(key): evidence[key] = true)
	game.initialize(mini(3, (1 if index >= 8 else 0) + mistakes), {"evidence": evidence, "mistakes": mistakes, "reduced_motion": reduced_motion, "employee_name": "ALEX", "employee_id": "0417", "late": index >= 8 or practice})
	game.start()
	add_button("II", Rect2(1190, 22, 58, 46), show_pause).focus_mode = Control.FOCUS_NONE

func on_task_completed(success: bool, reason: String) -> void:
	if state != "task": return
	last_success = success
	last_reason = reason
	last_bonus = ""
	if not practice:
		if success:
			streak += 1
			best_streak = maxi(best_streak, streak)
			var quick_bonus = 500 + int(maxf(0, game.time_left) * 12)
			var risk_bonus = 300 if index >= 8 and evidence.has("camera4") else 0
			var multiplier = 1.0 + mini(streak - 1, 4) * 0.15
			var earned = int((quick_bonus + risk_bonus + (150 if index >= 8 else 0)) * multiplier)
			score += earned
			last_bonus = "ARCADE BONUS +%d     STREAK x%d" % [earned, streak]
			if risk_bonus > 0: last_bonus += "     CAMERA 4 RISK +300"
		else:
			streak = 0
			safety -= 1
			mistakes += 1
	audio.escalate(float(index) / 17.0, mistakes)
	switch_to("result")
	sheet(Rect2(247, 192, 786, 328), Color("101820f9"), GREEN if success else RED)
	text_ui("DUTY COMPLETE" if success else "INCIDENT RECORDED", Rect2(285, 217, 710, 60), 36, GREEN if success else RED)
	text_ui(reason, Rect2(285, 290, 710, 110), 23)
	var detail = last_bonus if success and not practice else "The store is checking your work."
	if not success and not practice:
		detail = ["The lights no longer reach the corners.", "Someone else is waiting outside.", "An empty portrait has your name."][mini(mistakes - 1, 2)]
	text_ui(detail, Rect2(285, 420, 710, 70), 22, YELLOW)
	if practice:
		add_button("PRACTICE AGAIN", Rect2(285, 536, 320, 48), func(): start_practice(practice_id))
		add_button("ORIENTATION", Rect2(625, 536, 370, 48), func(): end_game_node(); show_instructions())

func after_result() -> void:
	end_game_node()
	if safety <= 0:
		show_ending(false)
		return
	if index == schedule.size() - 1:
		# Clock-out is the only exit. A failed final task costs safety and is retried.
		if last_success: show_ending(true)
		else: show_intro()
		return
	index += 1
	if index % 2 == 0 and notes_seen < STORY.NOTES.size(): show_note()
	else: show_patrol()

func show_note() -> void:
	switch_to("note")
	var note = STORY.NOTES[notes_seen]
	notes_seen += 1
	sheet(Rect2(261, 112, 758, 493), Color("d5cdb0"), Color("7f6e51"))
	text_ui(note[0].to_upper(), Rect2(305, 143, 660, 43), 22, Color("695c49"))
	text_ui(note[1], Rect2(305, 216, 660, 305), 26, INK)
	add_button("FOLD & KEEP", Rect2(305, 538, 660, 44), show_patrol)
	audio.play("paper")

func show_patrol() -> void:
	switch_to("patrol")
	var next_data = TASKS[schedule[index]]
	sheet(Rect2(180, 112, 920, 525), Color("101820f5"), Color("b8cc83"))
	text_ui("BETWEEN ASSIGNMENTS  /  NEXT UP", Rect2(230, 145, 820, 38), 21, GREEN)
	text_ui(next_data[0], Rect2(230, 193, 820, 62), 42, YELLOW)
	text_ui(next_data[1], Rect2(230, 275, 805, 105), 25, CREAM)
	text_ui("CONTROLS", Rect2(230, 402, 180, 32), 17, MUTED)
	text_ui(str(next_data[2]), Rect2(230, 432, 410, 38), 24, CREAM)
	text_ui("QUICK CLEAR BONUS  /  keep your streak alive", Rect2(650, 402, 390, 70), 19, PURPLE)
	review_label = text_ui("AUTO START IN 13  /  press READY NOW to jump in", Rect2(230, 485, 810, 32), 18, GREEN)
	patrol_flavor = text_ui("The store keeps its own schedule. Your move.", Rect2(230, 519, 810, 34), 18, MUTED)
	add_button("READY NOW", Rect2(230, 572, 245, 44), launch_task, GREEN)
	add_button("READ THE CLIPBOARD", Rect2(493, 572, 285, 44), func(): show_notebook("patrol"), YELLOW)
	add_button("CHECK THE GLASS", Rect2(796, 572, 244, 44), look_at_glass, MUTED)

func look_at_glass() -> void:
	if is_instance_valid(patrol_flavor): patrol_flavor.text = "Two people. Neither is breathing on the glass." if mistakes > 0 else "Your reflection turns back a moment after you do."
	audio.play("footstep")

func show_notebook(return_to: String) -> void:
	if state != "notebook": notebook_page = maxi(0, notes_seen - 1)
	if return_to == "patrol" and state == "patrol": patrol_return_seconds = state_seconds
	overlay_return = return_to
	switch_to("notebook")
	sheet(Rect2(145, 85, 990, 555), Color("d5cdb0"), Color("695d47"))
	text_ui("THE CLIPBOARD / KEEP YOUR OWN RECORD", Rect2(185, 114, 915, 45), 29, INK)
	text_ui("MANAGER\nFinish before six.\nDo not open the back door.\nDo not answer the phone.\nNo Camera 4 after 3:33.", Rect2(185, 184, 420, 244), 24, INK)
	text_ui("EMPLOYEE 0417 / ALEX\n" + ("OBSERVED: The front door opens at six." if evidence.get("camera4", false) else "Keep the notes. Compare them to the rules."), Rect2(185, 440, 420, 90), 20, INK)
	if notes_seen == 0:
		text_ui("No previous-employee notes found yet.", Rect2(638, 184, 450, 140), 23, INK)
	else:
		notebook_page = clampi(notebook_page, 0, notes_seen - 1)
		text_ui("NOTE %d / %d  -  %s" % [notebook_page + 1, notes_seen, STORY.NOTES[notebook_page][0]], Rect2(638, 184, 450, 65), 18, INK)
		text_ui(STORY.NOTES[notebook_page][1], Rect2(638, 255, 450, 270), 20, INK)
		if notebook_page > 0:
			add_button("PREVIOUS NOTE", Rect2(638, 557, 213, 48), func(): notebook_page -= 1; show_notebook(return_to))
		if notebook_page < notes_seen - 1:
			add_button("NEXT NOTE", Rect2(867, 557, 213, 48), func(): notebook_page += 1; show_notebook(return_to))
	add_button("KEEP WORKING", Rect2(185, 557, 400, 48), func():
		if overlay_return == "pause": show_pause()
		else:
			show_patrol()
			state_seconds = patrol_return_seconds)

func show_pause() -> void:
	if not is_paused:
		if is_instance_valid(game): game.suspend_input()
		overlay_return = state
		set_meta("resume_state", state)
		set_meta("resume_seconds", state_seconds)
		paused_ui = ui
		paused_review = review_label
		paused_flavor = patrol_flavor
		paused_ui.hide()
		ui = Control.new()
		ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.z_index = 20
		add_child(ui)
		is_paused = true
		get_tree().paused = true
	switch_to("pause")
	sheet(Rect2(387, 124, 506, 470), Color("101820fa"))
	text_ui("SHIFT ON HOLD", Rect2(430, 155, 440, 55), 35, YELLOW)
	add_button("RESUME", Rect2(430, 239, 420, 50), resume_shift)
	add_button("CLIPBOARD", Rect2(430, 304, 420, 50), func(): show_notebook("pause"))
	add_button("SETTINGS", Rect2(430, 369, 420, 50), func(): show_settings("pause"))
	add_button("RESTART SHIFT", Rect2(430, 434, 420, 50), new_shift)
	add_button("MAIN MENU", Rect2(430, 499, 420, 50), show_menu, MUTED)

func resume_shift() -> void:
	if not is_paused: return
	is_paused = false
	get_tree().paused = false
	clear_ui()
	ui.queue_free()
	ui = paused_ui
	paused_ui = null
	ui.show()
	review_label = paused_review
	patrol_flavor = paused_flavor
	state = str(get_meta("resume_state", "task"))
	state_seconds = float(get_meta("resume_seconds", 0))
	queue_redraw()

func discard_pause_ui() -> void:
	if is_instance_valid(paused_ui):
		paused_ui.queue_free()
	paused_ui = null
	paused_review = null
	paused_flavor = null

func end_game_node() -> void:
	if is_instance_valid(game):
		game.cleanup()
		game = null

func show_ending(won: bool) -> void:
	end_game_node()
	audio.silence()
	ending_reveal = false
	if won:
		best_score = maxi(best_score, score)
		write_save()
	switch_to("winner" if won else "death")
	if not won: audio.play("death")

func ending_ui() -> void:
	ending_reveal = true
	var won = state == "winner"
	sheet(Rect2(70, 65, 576, 590), Color("d5cdb0") if won else Color("101820f5"), YELLOW if won else RED)
	text_ui("EMPLOYEE\nOF THE NIGHT" if won else "WELCOME TO\nTHE NOTICEBOARD", Rect2(105, 99, 511, 122), 42, INK if won else CREAM)
	if won:
		text_ui("THE LAST STOP  /  SHIFT RECEIPT\n-------------------------------------\nSCORE                   %05d\nMISTAKES                    %d\nBEST                    %05d\nTIME                 %02d:%02d\n-------------------------------------\nExcellent work. See you tonight." % [score, mistakes, best_score, int(shift_seconds) / 60, int(shift_seconds) % 60], Rect2(107, 260, 510, 264), 23, INK)
		audio.play("printer")
	else:
		text_ui("Congratulations on completing\nyour first shift.\n\nALEX / 0417\nPERMANENT STAFF\n\nThe phone rings. Then silence.", Rect2(106, 264, 502, 236), 25, CREAM)
	add_button("PLAY AGAIN" if won else "TRY AGAIN", Rect2(107, 544, 239, 49), new_shift)
	add_button("MAIN MENU", Rect2(361, 544, 243, 49), show_menu)
	if not won: add_button("LOOK BEHIND YOU", Rect2(747, 578, 371, 51), optional_scare, RED)

func optional_scare() -> void:
	set_meta("scare_until", total_seconds + 1.25)
	set_meta("scare_side", randi() % 2)
	audio.play("breath")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if state == "pause": resume_shift()
		elif is_paused and state in ["settings", "notebook"]: show_pause()
		elif state in ["task", "intro", "patrol", "note", "result"]: show_pause()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and state in ["task", "intro", "patrol", "result"] and is_inside_tree():
		show_pause()

func _process(delta: float) -> void:
	total_seconds += delta
	if is_paused:
		queue_redraw()
		return
	state_seconds += delta
	if state in ["intro", "task", "result", "note", "patrol", "notebook"] and not practice:
		shift_seconds += delta
	match state:
		"loading":
			var actual = 0.0
			for path in load_paths:
				if textures.has(path): actual += 1.0; continue
				var progress = []
				var status = ResourceLoader.load_threaded_get_status(path, progress)
				if status == ResourceLoader.THREAD_LOAD_LOADED:
					textures[path] = ResourceLoader.load_threaded_get(path)
					actual += 1.0
				elif status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE or status == ResourceLoader.THREAD_LOAD_FAILED: actual += 1.0
				elif not progress.is_empty(): actual += progress[0]
			load_progress = minf(actual / load_paths.size(), state_seconds / 2.5)
			if load_progress >= 1.0 and state_seconds >= 2.8: show_menu()
		"intro":
			if state_seconds >= intro_seconds: launch_task()
		"result":
			if state_seconds >= 5.0 and not practice: after_result()
		"patrol":
			if is_instance_valid(review_label): review_label.text = "AUTO START IN %02d  /  press READY NOW to jump in" % maxi(0, int(13 - state_seconds))
			if state_seconds >= 13.0: show_intro()
		"winner", "death":
			if state_seconds >= 6.0 and not ending_reveal: ending_ui()
			if state == "death" and state_seconds > 2.7 and state_seconds - delta <= 2.7: audio.play("phone")
			if state == "winner" and state_seconds > 1.0 and state_seconds - delta <= 1.0: audio.play("winner")
			if state == "winner" and state_seconds < 4.0 and int(state_seconds * 2) != int((state_seconds - delta) * 2): audio.play("footstep")
	queue_redraw()

func paint_text(value: String, point: Vector2, size: int = 24, color: Color = CREAM) -> void:
	draw_string(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func art(key: String, rect: Rect2, tint: Color = Color.WHITE) -> void:
	var path = "res://assets/art/" + key + ".png"
	if textures.has(path): draw_texture_rect(textures[path], rect, false, tint)
	elif ResourceLoader.exists(path):
		textures[path] = load(path)
		draw_texture_rect(textures[path], rect, false, tint)

func _draw() -> void:
	if state == "loading":
		_draw_loading_screen()
		return
	var front = state in ["menu", "instructions", "credits", "briefing"] or (state == "settings" and not is_paused)
	art("exterior" if front else "interior", Rect2(0, 0, 1280, 720))
	if not front:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.015, 0.025, 0.04, minf(0.15 + mistakes * 0.12, 0.5)))
		if state == "patrol": draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.42))
		for n in range(mistakes): art("monster", Rect2(1100 - n * 80, 244, 100, 220), Color("818096"))
		if index >= 8:
			paint_text("WE REMEMBER", Vector2(1037, 677), 15, Color("997f9c"))
		if not reduced_motion and mistakes > 0 and sin(total_seconds * 1.7) > 0.96:
			draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.12))
	if state in ["intro", "task", "result", "note", "pause", "notebook"] or is_paused:
		draw_rect(Rect2(0, 0, 1280, 99), Color("101820f5"))
		draw_line(Vector2(30, 99), Vector2(1250, 99), Color("5d6655"), 2)
		paint_text("THE LAST STOP", Vector2(32, 37), 22, YELLOW)
		paint_text("0417 / ALEX", Vector2(33, 68), 17, MUTED)
		paint_text("PRACTICE" if practice else STORY.clock_label(index, schedule.size()), Vector2(304, 57), 34, CREAM)
		paint_text("EMPLOYEE SAFETY", Vector2(589, 32), 15, MUTED)
		for n in range(3):
			draw_rect(Rect2(591 + n * 45, 46, 31, 24), GREEN if n < safety else Color("413c43"))
			paint_text("+" if n < safety else "×", Vector2(600 + n * 45, 65), 20, INK)
		paint_text("STREAK", Vector2(831, 32), 15, MUTED)
		paint_text("x%02d" % streak, Vector2(831, 65), 27, YELLOW if streak > 1 else CREAM)
		paint_text("SCORE", Vector2(929, 32), 15, MUTED)
		paint_text("%05d" % score, Vector2(929, 65), 27)
		paint_text("DUTY %02d / %02d" % [index + 1, schedule.size()], Vector2(1073, 54), 16, MUTED)
		if not schedule.is_empty() and state in ["intro", "task", "result"]:
			paint_text(TASKS[schedule[index]][0], Vector2(141, 134), 24, YELLOW)
		if state == "task" and is_instance_valid(game):
			paint_text("%02d s" % maxi(0, ceili(game.time_left)), Vector2(1065, 134), 24, RED if game.time_left < 8 else GREEN)
			draw_rect(Rect2(140, 611, 1000, 4), Color("344444"))
			draw_rect(Rect2(140, 611, 1000 * maxf(0, game.time_left / game.duration), 4), GREEN)
			paint_text(TASKS[schedule[index]][2], Vector2(141, 650), 21)
			paint_text(STORY.phase(index, schedule.size()), Vector2(768, 650), 16, MUTED)
		paint_text("ESC / PAUSE     •     THE CLIPBOARD IS IN THE PAUSE MENU", Vector2(141, 694), 15, MUTED)
	if state == "winner":
		art("ending_winner", Rect2(0, 0, 1280, 720))
		if not ending_reveal:
			art("player", Rect2(690 + minf(state_seconds, 4) * 33, 440 + minf(state_seconds, 4) * 21, 80, 140))
			paint_text("6:00 AM", Vector2(476, 207), 68, INK)
			paint_text("The front door unlocks. You step outside.", Vector2(362, 258), 25, INK)
	if state == "death":
		art("ending_death", Rect2(0, 0, 1280, 720))
		for n in range(3):
			if state_seconds > 0.6 + n * 0.7:
				draw_rect(Rect2(n * 427, 0, 427, 720), Color(0, 0, 0, 0.27))
		paint_text("3:33 AM", Vector2(830, 129), 55, RED)
		paint_text("ALEX / 0417", Vector2(845, 516), 25, CREAM)
		if total_seconds < float(get_meta("scare_until", 0)):
			art("monster", Rect2(500 + int(get_meta("scare_side", 0)) * 70, 80, 420, 640))

func _draw_loading_screen() -> void:
	# A deliberate arcade briefing replaces the old generic exterior backdrop.
	draw_rect(Rect2(0, 0, 1280, 720), INK)
	draw_rect(Rect2(42, 36, 1196, 648), Color("13252c"), false)
	draw_rect(Rect2(42, 36, 1196, 648), Color("4c685f"), false, 3.0)
	for n in range(12):
		var x = 78.0 + n * 101.0
		var drift = 0.0 if reduced_motion else sin(total_seconds * 1.8 + n) * 7.0
		draw_line(Vector2(x, 63 + drift), Vector2(x + 38, 63 + drift), Color("b8cc8350"), 3.0)
	paint_text("CLOCK OUT ALIVE", Vector2(88, 133), 52, CREAM)
	paint_text("LOADING YOUR NIGHT-SHIFT ARCADE", Vector2(91, 169), 22, YELLOW)
	var preview_id = 0
	var preview = TASKS[preview_id]
	draw_rect(Rect2(88, 218, 1104, 270), Color("0d171e"))
	draw_rect(Rect2(88, 218, 1104, 270), Color("b8cc83"), false, 3.0)
	paint_text("NEXT CHALLENGE PREVIEW", Vector2(122, 260), 19, GREEN)
	paint_text("%02d  /  %s" % [preview_id + 1, preview[0]], Vector2(122, 320), 40, CREAM)
	var preview_lines = str(preview[1]).split("\n")
	for line_index in range(preview_lines.size()):
		paint_text(str(preview_lines[line_index]), Vector2(124, 371 + line_index * 32), 23, CREAM)
	paint_text("YOU WILL USE: " + str(preview[2]), Vector2(124, 456), 18, YELLOW)
	draw_rect(Rect2(88, 528, 1104, 74), Color("d5cdb0"))
	draw_rect(Rect2(106, 548, 1068, 22), Color("273a3d"))
	draw_rect(Rect2(106, 548, 1068 * load_progress, 22), GREEN)
	paint_text("%03d%%  /  %s" % [int(load_progress * 100), ["WARMING UP THE SCANNER...", "COUNTING THE EXITS...", "FINDING THE WEIRD PART..."][mini(2, int(state_seconds))]], Vector2(106, 590), 18, INK)
	paint_text("FUN RULE: CHAIN QUICK CLEARS FOR STREAK BONUSES. TAKE RISKS FOR CLUES.", Vector2(91, 649), 18, PURPLE)
