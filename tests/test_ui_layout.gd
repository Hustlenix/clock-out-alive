extends SceneTree

var checks: int = 0
var failures: Array[String] = []
var main

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		print("FAIL: ", message)

func inspect_screen(screen: String) -> void:
	await process_frame
	await process_frame
	var buttons: Array[Button] = []
	var labels: Array[Label] = []
	for child in main.ui.get_children():
		if child is Button: buttons.append(child)
		if child is Label: labels.append(child)
	for button in buttons:
		check(Rect2(0, 0, 1280, 720).encloses(button.get_rect()), screen + ": button fits viewport: " + button.text)
		for other in buttons:
			if other == button: continue
			check(not button.get_rect().intersects(other.get_rect()), screen + ": buttons overlap: " + button.text + " / " + other.text)
		for label in labels:
			check(not button.get_rect().intersects(label.get_rect()), screen + ": button overlaps text: " + button.text + " / " + label.text.left(30))
	if OS.get_cmdline_user_args().size() > 0 and screen in ["menu", "intermission", "clipboard", "winner", "death"]:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0].path_join(screen + ".png"))

func run() -> void:
	var save_existed = FileAccess.file_exists("user://last_stop.cfg")
	var saved = FileAccess.get_file_as_bytes("user://last_stop.cfg") if save_existed else PackedByteArray()
	main = load("res://scripts/main.gd").new()
	root.add_child(main)
	main.set_process(false)
	for attempt in range(120):
		main._process(0.1)
		if main.state == "menu": break
		await process_frame
	main.show_menu()
	await inspect_screen("menu")
	main.show_instructions()
	await inspect_screen("orientation")
	main.show_settings("menu")
	await inspect_screen("settings")
	main.show_credits()
	await inspect_screen("credits")
	main.show_briefing()
	await inspect_screen("briefing")
	main.new_shift()
	for task in range(10):
		main.schedule[0] = task
		main.show_intro()
		await inspect_screen("intro " + str(task))
		main.show_patrol()
		await inspect_screen("intermission" if task == 2 else "patrol " + str(task))
		main.show_pause()
		await inspect_screen("pause")
		main.resume_shift()
	main.notes_seen = 0
	for note in range(8):
		main.show_note()
		await inspect_screen("note " + str(note))
		main.show_notebook("patrol")
		await inspect_screen("clipboard" if note == 7 else "clipboard " + str(note))
	for won in [true, false]:
		main.show_ending(won)
		main.ending_ui()
		await inspect_screen("winner" if won else "death")
	main.show_menu()
	await create_timer(0.15).timeout
	main.queue_free()
	await process_frame
	if save_existed:
		var file = FileAccess.open("user://last_stop.cfg", FileAccess.WRITE)
		file.store_buffer(saved)
		file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://last_stop.cfg"))
	print("UI layout: ", checks, " assertions; ", failures.size(), " failures.")
	quit(0 if failures.is_empty() else 1)
