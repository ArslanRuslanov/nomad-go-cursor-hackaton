extends PanelContainer
## Level-up celebration modal.

@onready var level_label: Label = $Margin/VBox/LevelLabel
@onready var rank_label: Label = $Margin/VBox/RankLabel
@onready var ok_btn: Button = $Margin/VBox/OkBtn


func _ready() -> void:
	visible = false
	ok_btn.pressed.connect(func() -> void: visible = false)
	UiTheme.style_panel(self, true)
	UiTheme.style_button(ok_btn, true)


func show_level_up(new_level: int, rank_title: String) -> void:
	level_label.text = "LEVEL UP!"
	rank_label.text = "Level %d — %s" % [new_level, rank_title]
	visible = true
	scale = Vector2(0.8, 0.8)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
