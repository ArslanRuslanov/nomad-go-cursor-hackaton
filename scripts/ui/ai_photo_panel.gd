extends ColorRect
## Simulated AI photo verification for location-based photo quests.

@onready var title_label: Label = $Center/Panel/Margin/VBox/TitleLabel
@onready var quest_label: Label = $Center/Panel/Margin/VBox/QuestLabel
@onready var status_label: Label = $Center/Panel/Margin/VBox/StatusLabel
@onready var progress_bar: ProgressBar = $Center/Panel/Margin/VBox/ProgressBar
@onready var match_label: Label = $Center/Panel/Margin/VBox/MatchLabel
@onready var criteria_label: Label = $Center/Panel/Margin/VBox/CriteriaLabel
@onready var verify_btn: Button = $Center/Panel/Margin/VBox/VerifyBtn
@onready var cancel_btn: Button = $Center/Panel/Margin/VBox/CancelBtn

var _quest_id: String = ""
var _analyzing: bool = false
var _ready_to_claim: bool = false


func _ready() -> void:
	visible = false
	color = Color(0.02, 0.03, 0.06, 0.92)
	verify_btn.pressed.connect(_on_verify_pressed)
	cancel_btn.pressed.connect(_on_cancel)
	UiTheme.style_button(verify_btn, true)
	UiTheme.style_button(cancel_btn, false)
	UiTheme.style_progress(progress_bar)
	UiTheme.style_panel($Center/Panel as PanelContainer, true)


func open_for_quest(quest_id: String) -> void:
	_quest_id = quest_id
	_ready_to_claim = false
	_analyzing = false
	var quest: Dictionary = GameManager.get_quest_by_id(quest_id)
	if quest.is_empty():
		return
	title_label.text = "AI Photo Verification"
	quest_label.text = GameManager.get_quest_display_title(quest)
	criteria_label.text = "AI checks: %s" % QuestData.get_photo_ai_criteria(quest)
	status_label.text = "Simulated vision model — proves you are on-site."
	match_label.text = ""
	progress_bar.value = 0
	verify_btn.text = "Run AI Scan"
	verify_btn.disabled = false
	visible = true


func _on_verify_pressed() -> void:
	if _ready_to_claim:
		GameManager.complete_quest(_quest_id, "", true)
		visible = false
		return
	if _analyzing:
		return
	if not GameManager.is_quest_in_range(GameManager.get_quest_by_id(_quest_id)):
		GameManager.toast_requested.emit("You must be at the quest location!")
		return
	_analyzing = true
	verify_btn.disabled = true
	_run_analysis()


func _run_analysis() -> void:
	var steps: Array[String] = [
		"Reading GPS coordinates...",
		"Detecting landmarks in frame...",
		"Matching scene to quest location...",
		"Scoring composition & lighting...",
	]
	progress_bar.max_value = steps.size()
	for i in steps.size():
		status_label.text = steps[i]
		progress_bar.value = i + 1
		await get_tree().create_timer(0.55).timeout
	var match_pct: int = randi_range(82, 97)
	match_label.text = "Location match: %d%%" % match_pct
	match_label.add_theme_color_override("font_color", UiTheme.SUCCESS if match_pct >= 80 else UiTheme.DANGER)
	status_label.text = "AI approved — quest location verified!"
	_analyzing = false
	_ready_to_claim = true
	verify_btn.text = "Claim XP Reward"
	verify_btn.disabled = false


func _on_cancel() -> void:
	visible = false
	_analyzing = false
	_ready_to_claim = false
