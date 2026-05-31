extends Area2D
class_name QuestMarker
## Color-coded quest pin on the map.

signal marker_pressed(quest_info)

var quest_data: Dictionary = {}
var _pulse_time: float = 0.0
var _base_scale: Vector2 = Vector2.ONE

@onready var pin_body: Polygon2D = $PinBody
@onready var pin_label: Label = $PinLabel
@onready var pulse_ring: Polygon2D = $PulseRing
@onready var lock_icon: Label = $LockIcon


func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_input)
	mouse_entered.connect(func(): scale = _base_scale * 1.12)
	mouse_exited.connect(func(): scale = _base_scale)


func _process(delta: float) -> void:
	if quest_data.is_empty():
		return
	var pulsing: bool = GameManager.is_quest_pulsing(quest_data)
	var is_boss: bool = str(quest_data.get("type", "")) == "boss"
	pulse_ring.visible = pulsing
	if pulsing:
		_pulse_time += delta * 3.0
		var s: float = 1.0 + sin(_pulse_time) * 0.15
		pulse_ring.scale = Vector2(s, s)
		pulse_ring.modulate.a = 0.3 + sin(_pulse_time) * 0.2
	if is_boss:
		_base_scale = Vector2(1.4, 1.4)
		scale = _base_scale
	var in_range: bool = GameManager.is_quest_in_range(quest_data)
	var completed: bool = bool(quest_data.get("completed", false))
	lock_icon.visible = not in_range and not completed
	modulate = Color(0.55, 0.55, 0.55, 0.7) if not in_range and not completed else Color.WHITE
	if completed:
		modulate = Color(0.5, 0.5, 0.5, 0.6)


func setup(data: Dictionary) -> void:
	quest_data = data
	_apply_visuals()


func _apply_visuals() -> void:
	if quest_data.is_empty():
		return
	var body: Polygon2D = pin_body if pin_body else get_node_or_null("PinBody") as Polygon2D
	var ring: Polygon2D = pulse_ring if pulse_ring else get_node_or_null("PulseRing") as Polygon2D
	var label: Label = pin_label if pin_label else get_node_or_null("PinLabel") as Label
	if body == null or ring == null or label == null:
		return
	var qtype: String = str(quest_data.get("type", "scan"))
	var color: Color = QuestData.color_for_type(qtype)
	if quest_data.get("is_mystery", false):
		color = Color(0.45, 0.2, 0.65)
	if quest_data.get("is_daily", false):
		color = UiTheme.GOLD
	body.color = color
	ring.color = Color(color.r, color.g, color.b, 0.35)
	if quest_data.get("is_mystery", false) and not GameManager.is_mystery_revealed(quest_data):
		label.text = "???"
	else:
		label.text = QuestData.icon_for_type(qtype)
	if qtype == "boss":
		body.scale = Vector2(1.3, 1.3)


func refresh_state() -> void:
	var q: Dictionary = GameManager.get_quest_by_id(quest_data.get("id", ""))
	if not q.is_empty():
		quest_data = q


func _on_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		refresh_state()
		marker_pressed.emit(quest_data)
