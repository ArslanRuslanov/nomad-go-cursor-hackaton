extends PanelContainer
## HUD overlay while a quest is active.

@onready var title_label: Label = $Margin/VBox/TitleLabel
@onready var objective_label: Label = $Margin/VBox/ObjectiveLabel
@onready var dist_label: Label = $Margin/VBox/DistLabel
@onready var timer_label: Label = $Margin/VBox/TimerLabel
@onready var abandon_btn: Button = $Margin/VBox/AbandonBtn

var _expires_at: int = 0


func _ready() -> void:
	visible = false
	abandon_btn.pressed.connect(_on_abandon)


func _process(_delta: float) -> void:
	if not visible or _expires_at == 0:
		return
	var remaining: int = int(_expires_at - Time.get_unix_time_from_system())
	if remaining <= 0:
		timer_label.text = "EXPIRED"
		timer_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	else:
		var mins: int = remaining / 60
		var secs: int = remaining % 60
		timer_label.text = "Time left: %02d:%02d" % [mins, secs]
	if not GameManager.active_quest.is_empty():
		_update_dist(GameManager.active_quest)


func show_active(quest: Dictionary) -> void:
	title_label.text = "Active: %s" % quest.get("title", "")
	objective_label.text = quest.get("description", "")
	_expires_at = int(quest.get("expires_at", 0))
	_update_dist(quest)
	visible = true


func hide_active() -> void:
	visible = false
	_expires_at = 0


func _update_dist(quest: Dictionary) -> void:
	var dist := GameManager.distance_to_quest(quest)
	dist_label.text = "Distance: %s" % GeoUtils.format_distance(dist)
	if GameManager.is_quest_in_range(quest):
		dist_label.add_theme_color_override("font_color", Color(0.2, 0.7, 0.35))
	else:
		dist_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.2))


func _on_abandon() -> void:
	GameManager.dismiss_active_quest()
	hide_active()
