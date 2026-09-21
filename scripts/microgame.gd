extends Node2D
class_name ShiftMicrogame

signal completed(success: bool, reason: String)
signal sound_requested(cue: String)
signal evidence_found(key: String)

const CREAM = Color("e6ddb7")
const YELLOW = Color("e7bf5d")
const GREEN = Color("b8cc83")
const RED = Color("d77868")
const BLUE = Color("637f91")
const INK = Color("101820")
const PURPLE = Color("bd8fba")
var difficulty: int = 0
var time_left: float = 30.0
var duration: float = 30.0
var elapsed: float = 0.0
var finished: bool = false
var active: bool = false
var reduced_motion: bool = false
var context: Dictionary = {}
var feedback: String = ""
var mouse: Vector2 = Vector2.ZERO
var font: Font = ThemeDB.fallback_font
var art: Texture2D
var texture_cache: Dictionary = {}

func initialize(level: int, run_context: Dictionary = {}) -> void:
	difficulty = level
	context = run_context.duplicate(true)
	reduced_motion = context.get("reduced_motion", false)
	finished = false
	active = false
	elapsed = 0.0
	_setup()
	time_left = duration
	queue_redraw()

func start() -> void:
	if not finished:
		active = true

func _setup() -> void:
	pass

func _process(delta: float) -> void:
	if not active or finished:
		return
	elapsed += delta
	time_left -= delta
	_tick(delta)
	if time_left <= 0.0 and not finished:
		finish(false, "The task timer ran out.")
	queue_redraw()

func _tick(_delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if not active or finished:
		return
	if event is InputEventMouse:
		mouse = event.position
	_handle(event)

func _handle(_event: InputEvent) -> void:
	pass

func finish(success: bool, reason: String = "") -> void:
	if finished:
		return
	finished = true
	active = false
	feedback = reason
	sound_requested.emit("success" if success else "failure")
	completed.emit(success, reason)
	queue_redraw()

func cleanup() -> void:
	active = false
	set_process(false)
	set_process_input(false)
	queue_free()

func suspend_input() -> void:
	pass

func label_at(value: String, point: Vector2, size: int = 24, color: Color = CREAM) -> void:
	draw_string(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func panel(rect: Rect2, color: Color = INK, border: Color = BLUE) -> void:
	draw_rect(rect, color)
	draw_rect(rect, border, false, 2.0)

func button(rect: Rect2, value: String, color: Color = GREEN) -> void:
	panel(rect, Color("1b292c"), color)
	label_at(value, rect.position + Vector2(18, rect.size.y * 0.5 + 8), 23, color)

func clicked(event: InputEvent, rect: Rect2) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and rect.has_point(event.position)

func sprite(key: String, rect: Rect2, tint: Color = Color.WHITE) -> void:
	var path = "res://assets/art/" + key + ".png"
	if ResourceLoader.exists(path):
		if not texture_cache.has(key): texture_cache[key] = load(path)
		draw_texture_rect(texture_cache[key], rect, false, tint)

func _draw() -> void:
	panel(Rect2(140, 150, 1000, 440))
	label_at("SHIFT TASK", Vector2(170, 190))
