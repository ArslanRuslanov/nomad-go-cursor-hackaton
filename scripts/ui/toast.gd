extends PanelContainer
## Toast notifications for proximity and game events.

@onready var message_label: Label = $Margin/Label

var _hide_timer: SceneTreeTimer


func _ready() -> void:
	visible = false
	UiTheme.style_panel(self, true)


func show_message(text: String) -> void:
	message_label.text = text
	visible = true
	modulate.a = 1.0
	if _hide_timer:
		_hide_timer.timeout.disconnect(_fade_out)
	_hide_timer = get_tree().create_timer(3.0)
	_hide_timer.timeout.connect(_fade_out)


func _fade_out() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func(): visible = false)
