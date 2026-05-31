extends PanelContainer
## Bottom sheet when tapping a quest pin.

@onready var title_label: Label = $Margin/VBox/TitleLabel
@onready var type_label: Label = $Margin/VBox/TypeLabel
@onready var desc_label: Label = $Margin/VBox/DescLabel
@onready var dist_label: Label = $Margin/VBox/DistLabel
@onready var xp_label: Label = $Margin/VBox/XpLabel
@onready var hint_label: Label = $Margin/VBox/HintLabel
@onready var answer_edit: LineEdit = $Margin/VBox/AnswerEdit
@onready var accept_btn: Button = $Margin/VBox/AcceptBtn
@onready var complete_btn: Button = $Margin/VBox/CompleteBtn
@onready var dismiss_btn: Button = $Margin/VBox/DismissBtn

var _current: Dictionary = {}


func _ready() -> void:
	visible = false
	UiTheme.style_panel(self, true)
	UiTheme.style_button(accept_btn, true)
	UiTheme.style_button(complete_btn, true)
	UiTheme.style_button(dismiss_btn, false)
	accept_btn.pressed.connect(_on_accept)
	complete_btn.pressed.connect(_on_complete)
	dismiss_btn.pressed.connect(hide_sheet)


func show_quest(quest: Dictionary) -> void:
	_current = quest
	title_label.text = GameManager.get_quest_display_title(quest)
	var qtype: String = str(quest.get("type", "scan"))
	var tag: String = ""
	if quest.get("is_daily", false):
		tag = " • Daily 2×"
	if quest.get("is_mystery", false):
		tag = " • Mystery"
	type_label.text = "%s  •  %s%s" % [QuestData.icon_for_type(qtype), quest.get("difficulty", "medium").capitalize(), tag]
	type_label.add_theme_color_override("font_color", QuestData.color_for_type(qtype))
	desc_label.text = quest.get("description", "")
	var dist: float = GameManager.distance_to_quest(quest)
	dist_label.text = "Distance: %s" % GeoUtils.format_distance(dist)
	var xp: int = int(quest.get("xp_reward", 0))
	if quest.get("is_daily", false):
		xp *= 2
	xp_label.text = "Reward: %d XP + coins" % xp
	hint_label.text = QuestData.verification_hint(qtype)
	if qtype == "photo":
		hint_label.text = "Complete via AI Photo Verification at location."
	var needs_answer: bool = qtype in ["trivia", "puzzle"]
	answer_edit.visible = needs_answer
	answer_edit.placeholder_text = "Your answer..."
	var in_range: bool = GameManager.is_quest_in_range(quest)
	var completed: bool = bool(quest.get("completed", false))
	var accepted: bool = bool(quest.get("accepted", false))
	accept_btn.visible = not completed and not accepted
	accept_btn.disabled = not in_range
	accept_btn.text = "Accept Quest" if in_range else "Too Far — Walk Closer"
	complete_btn.visible = accepted and not completed
	complete_btn.disabled = not in_range
	complete_btn.text = "AI Verify Photo" if qtype == "photo" else "Complete Quest"
	dismiss_btn.text = "Close"
	visible = true


func hide_sheet() -> void:
	visible = false


func _on_accept() -> void:
	var id: String = _current.get("id", "")
	if GameManager.accept_quest(id):
		show_quest(GameManager.get_quest_by_id(id))


func _on_complete() -> void:
	var id: String = _current.get("id", "")
	var qtype: String = str(_current.get("type", ""))
	if qtype == "photo":
		GameManager.request_photo_verification(id)
		hide_sheet()
		return
	GameManager.complete_quest(id, answer_edit.text)
	var updated: Dictionary = GameManager.get_quest_by_id(id)
	if bool(updated.get("completed", false)):
		hide_sheet()
	else:
		show_quest(updated)
