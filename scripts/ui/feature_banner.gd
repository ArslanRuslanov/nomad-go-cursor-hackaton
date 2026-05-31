extends PanelContainer
## Daily Challenge + Mystery Quest banners (map & nearby screens).

@onready var daily_title: Label = $Margin/VBox/DailyRow/DailyVBox/DailyTitle
@onready var daily_desc: Label = $Margin/VBox/DailyRow/DailyVBox/DailyDesc
@onready var daily_btn: Button = $Margin/VBox/DailyRow/DailyBtn
@onready var mystery_title: Label = $Margin/VBox/MysteryRow/MysteryVBox/MysteryTitle
@onready var mystery_desc: Label = $Margin/VBox/MysteryRow/MysteryVBox/MysteryDesc
@onready var mystery_btn: Button = $Margin/VBox/MysteryRow/MysteryBtn


func _ready() -> void:
	UiTheme.style_panel(self, true)
	UiTheme.style_button(daily_btn, true)
	UiTheme.style_button(mystery_btn, false)
	UiTheme.style_label(daily_title, false, false)
	UiTheme.style_label(mystery_title, false, false)
	UiTheme.style_label(daily_desc, true)
	UiTheme.style_label(mystery_desc, true)
	daily_btn.pressed.connect(_on_daily)
	mystery_btn.pressed.connect(_on_mystery)
	GameManager.onboarding_finished.connect(refresh)
	GameManager.quest_completed.connect(func(_id, _xp): refresh())
	PlayerData.profile_changed.connect(refresh)
	refresh()


func refresh() -> void:
	var daily: Dictionary = GameManager.get_daily_challenge()
	if daily.is_empty():
		daily_title.text = "Daily Challenge"
		daily_desc.text = "Loading..."
	else:
		var done: bool = bool(daily.get("completed", false))
		daily_title.text = "⚡ Daily Challenge" + (" ✓" if done else "")
		daily_desc.text = "%s — %d XP (2× bonus)" % [daily.get("title", ""), int(daily.get("xp_reward", 0) * 2)]
		daily_btn.text = "Completed" if done else "View on Map"
		daily_btn.disabled = done
	var mystery: Dictionary = GameManager.get_mystery_quest()
	if not PlayerData.mystery_unlocked:
		mystery_title.text = "🔮 Mystery Quest"
		mystery_desc.text = "Complete %d more quests to unlock" % max(0, GameManager.MYSTERY_UNLOCK_COUNT - PlayerData.quests_completed)
		mystery_btn.text = "Locked"
		mystery_btn.disabled = true
	elif mystery.is_empty():
		mystery_title.text = "🔮 Mystery Quest"
		mystery_desc.text = "Unavailable"
		mystery_btn.disabled = true
	else:
		var revealed: bool = GameManager.is_mystery_revealed(mystery)
		mystery_title.text = "🔮 Mystery Quest"
		mystery_desc.text = mystery.get("title", "???") if revealed else "??? — Walk closer to reveal"
		mystery_btn.text = "Track" if revealed else "Explore"
		mystery_btn.disabled = bool(mystery.get("completed", false))


func _on_daily() -> void:
	var daily: Dictionary = GameManager.get_daily_challenge()
	if not daily.is_empty():
		GameManager.quest_selected.emit(daily)
		GameManager.change_tab(GameManager.Tab.MAP)


func _on_mystery() -> void:
	if not PlayerData.mystery_unlocked:
		return
	var mystery: Dictionary = GameManager.get_mystery_quest()
	if not mystery.is_empty():
		GameManager.quest_selected.emit(mystery)
		GameManager.change_tab(GameManager.Tab.MAP)
