extends SceneTree

var failures: Array[String] = []
var checks: int = 0

func verify(test: bool, message: String) -> void:
	checks += 1
	if not test:
		failures.append(message)
		printerr("FAIL: " + message)

func fresh(id: String, difficulty: int):
	var game = load("res://scripts/microgames/" + id + ".gd").new()
	root.add_child(game)
	game.set_process(false)
	game.initialize(difficulty, {"mistakes": 1})
	game.start()
	return game

func mouse_button(game, p: Vector2, pressed: bool) -> void:
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = p
	event.pressed = pressed
	game._input(event)

func drag(game, from: Vector2, to: Vector2) -> void:
	mouse_button(game, from, true)
	var event = InputEventMouseMotion.new()
	event.position = to
	game._input(event)
	mouse_button(game, to, false)

func key(game, code: int, pressed: bool = true) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	game._input(event)

func watch_signal(game) -> Dictionary:
	var stats = {"count": 0, "success": false, "reason": ""}
	game.completed.connect(func(success: bool, reason: String):
		stats.count += 1
		stats.success = success
		stats.reason = reason)
	return stats

func check_final(game, stats: Dictionary, success: bool, context_text: String) -> void:
	verify(game.finished, context_text + " finished")
	verify(not game.active, context_text + " inactive")
	verify(stats.count == 1 and stats.success == success, context_text + " correct single completion")
	var stopped_at = game.time_left
	game._process(20)
	game.finish(not success, "SHOULD NOT EMIT")
	verify(stats.count == 1, context_text + " double completion guarded")
	verify(game.time_left == stopped_at, context_text + " timer stopped")
	game.free()

func _initialize() -> void:
	for difficulty in range(4):
		var paused_scan = fresh("scan_stock", difficulty)
		mouse_button(paused_scan, paused_scan.products[0].pos + Vector2(40, 40), true)
		verify(paused_scan.held == 0, "scan drag picked up before pause")
		paused_scan.suspend_input()
		verify(paused_scan.held == -1, "scan drag cleared after pause")
		paused_scan.free()
		var paused_restock = fresh("restock_aisle", difficulty)
		mouse_button(paused_restock, paused_restock.items[0].pos + Vector2(40, 40), true)
		verify(paused_restock.held == 0, "restock drag picked up before pause")
		paused_restock.suspend_input()
		verify(paused_restock.held == -1, "restock drag cleared after pause")
		paused_restock.free()
		var paused_mop = fresh("mop_spill", difficulty)
		key(paused_mop, KEY_D)
		paused_mop.suspend_input()
		var mop_at: Vector2 = paused_mop.mop
		paused_mop._process(0.1)
		verify(mop_at == paused_mop.mop, "mop held keys cleared after pause")
		paused_mop.free()
		for id in ["scan_stock", "mop_spill", "restock_aisle", "fix_breaker", "check_customer"]:
			var game = fresh(id, difficulty)
			var stats = watch_signal(game)
			game._process(40)
			check_final(game, stats, false, "%s d%d timeout" % [id, difficulty])
		var scan = fresh("scan_stock", difficulty)
		var scan_stats = watch_signal(scan)
		for product in scan.products:
			if not product.alive:
				drag(scan, product.pos + scan.ITEM_SIZE * 0.5, scan.SCANNER.get_center())
		check_final(scan, scan_stats, true, "scan successful d%d" % difficulty)
		scan = fresh("scan_stock", difficulty)
		scan_stats = watch_signal(scan)
		for product in scan.products:
			if product.alive:
				drag(scan, product.pos + scan.ITEM_SIZE * 0.5, scan.SCANNER.get_center())
		check_final(scan, scan_stats, false, "scan living fails d%d" % difficulty)
		var restock = fresh("restock_aisle", difficulty)
		var restock_stats = watch_signal(restock)
		for product in restock.items:
			drag(restock, product.pos + restock.SIZE * 0.5, restock.slots[product.slot].get_center())
		verify(restock.shifted == (difficulty >= 1), "restock variation d%d" % difficulty)
		check_final(restock, restock_stats, true, "restock successful d%d" % difficulty)
		restock = fresh("restock_aisle", difficulty)
		restock_stats = watch_signal(restock)
		for attempt in range(3):
			drag(restock, restock.items[0].pos + restock.SIZE * 0.5, restock.slots[0].get_center())
		check_final(restock, restock_stats, false, "restock wrong shelf fails d%d" % difficulty)
		var breaker = fresh("fix_breaker", difficulty)
		var breaker_stats = watch_signal(breaker)
		key(breaker, KEY_1)
		verify(breaker.entered.is_empty(), "breaker ignores demo input d%d" % difficulty)
		breaker._process(8)
		verify(breaker.stage == "repeat", "breaker demo completes d%d" % difficulty)
		key(breaker, KEY_R)
		verify(breaker.stage == "watch" and not breaker.replay_available, "breaker replay d%d" % difficulty)
		breaker._process(8)
		for number in breaker.sequence: key(breaker, KEY_1 + number)
		check_final(breaker, breaker_stats, true, "breaker successful d%d" % difficulty)
		breaker = fresh("fix_breaker", difficulty)
		breaker_stats = watch_signal(breaker)
		breaker._process(8)
		key(breaker, KEY_1 + ((breaker.sequence[0] + 1) % 6))
		check_final(breaker, breaker_stats, false, "breaker wrong input fails d%d" % difficulty)
		var customer = fresh("check_customer", difficulty)
		var customer_stats = watch_signal(customer)
		key(customer, KEY_A)
		verify(not customer.finished and customer.correct == 0, "customer inspect gate d%d" % difficulty)
		for i in range(3):
			customer._process(1.2)
			key(customer, KEY_A if customer.profile.valid else KEY_R)
			if not customer.finished: customer._process(0.9)
		check_final(customer, customer_stats, true, "customer successful d%d" % difficulty)
		customer = fresh("check_customer", difficulty)
		customer_stats = watch_signal(customer)
		customer._process(1.2)
		key(customer, KEY_R if customer.profile.valid else KEY_A)
		check_final(customer, customer_stats, false, "customer wrong decision fails d%d" % difficulty)
		var mop = fresh("mop_spill", difficulty)
		var mop_stats = watch_signal(mop)
		# Genuine key path plus clean dwell for each target, using held keys and _process.
		for spill in mop.spills:
			var destination: Vector2 = spill.pos
			for axis in range(2):
				var difference = destination[axis] - mop.mop[axis]
				var code = (KEY_D if difference > 0 else KEY_A) if axis == 0 else (KEY_S if difference > 0 else KEY_W)
				key(mop, code)
				mop._process(absf(difference) / 315.0)
				key(mop, code, false)
			# Substeps preserve collision pressure and cleaning simulation.
			for frame in range(105):
				mop._process(1.0 / 60.0)
		verify(mop.cleaned == mop.spills.size(), "mop all cleaned d%d" % difficulty)
		check_final(mop, mop_stats, true, "mop successful d%d" % difficulty)
		if difficulty > 0:
			mop = fresh("mop_spill", difficulty)
			mop_stats = watch_signal(mop)
			for frame in range(1800):
				if mop.finished: break
				var chase: Vector2 = mop.shadow - mop.mop
				key(mop, KEY_D, chase.x > 9)
				key(mop, KEY_A, chase.x < -9)
				key(mop, KEY_S, chase.y > 9)
				key(mop, KEY_W, chase.y < -9)
				mop._process(1.0 / 60.0)
			verify(mop.danger >= 1.0, "mop shadow pressure causes failure d%d" % difficulty)
			check_final(mop, mop_stats, false, "mop shadow failure d%d" % difficulty)
	print("FIRST FIVE CHECKS: %d passed, %d failed" % [checks - failures.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)
