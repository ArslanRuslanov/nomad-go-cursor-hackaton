extends ColorRect
## Victory screen with XP pop animation.

@onready var title_label: Label = $Center/VBox/TitleLabel
@onready var xp_label: Label = $Center/VBox/XpLabel
@onready var quest_label: Label = $Center/VBox/QuestLabel
@onready var continue_btn: Button = $Center/VBox/ContinueBtn

var _xp_tween: Tween


func _ready() -> void:
	visible = false
	modulate.a = 0.0
	continue_btn.pressed.connect(hide_victory)
	UiTheme.style_button(continue_btn, true)


func show_victory(xp: int, quest_title: String) -> void:
	title_label.text = "Quest Complete!"
	quest_label.text = quest_title
	xp_label.text = "+%d XP" % xp
	xp_label.scale = Vector2(0.5, 0.5)
	visible = true
	modulate.a = 1.0
	if _xp_tween:
		_xp_tween.kill()
	_xp_tween = create_tween()
	_xp_tween.set_parallel(true)
	_xp_tween.tween_property(xp_label, "scale", Vector2(1.2, 1.2), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_xp_tween.tween_property(xp_label, "modulate", Color(1, 0.85, 0.2), 0.2)


func hide_victory() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func(): visible = false)
