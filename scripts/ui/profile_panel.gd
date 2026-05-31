extends Control
## Player profile — RPG stats, achievements, real rewards shop.

@onready var username_label: Label = $Scroll/VBox/UsernameLabel
@onready var rank_label: Label = $Scroll/VBox/RankLabel
@onready var xp_bar: ProgressBar = $Scroll/VBox/XpBar
@onready var xp_label: Label = $Scroll/VBox/XpLabel
@onready var streak_label: Label = $Scroll/VBox/StreakLabel
@onready var coins_label: Label = $Scroll/VBox/CoinsLabel
@onready var quests_label: Label = $Scroll/VBox/QuestsLabel
@onready var ai_label: Label = $Scroll/VBox/AiLabel
@onready var badges_grid: GridContainer = $Scroll/VBox/BadgesGrid
@onready var rewards_list: ItemList = $Scroll/VBox/RewardsList
@onready var claim_btn: Button = $Scroll/VBox/ClaimBtn
@onready var chaos_check: CheckBox = $Scroll/VBox/ChaosCheck
@onready var tiles_check: CheckBox = $Scroll/VBox/TilesCheck
@onready var name_edit: LineEdit = $Scroll/VBox/NameEdit
@onready var save_btn: Button = $Scroll/VBox/SaveBtn
@onready var avatar: ColorRect = $Scroll/VBox/AvatarRow/Avatar

var _selected_reward_id: String = ""


func _ready() -> void:
	UiTheme.apply_screen_bg(self)
	UiTheme.style_label($Scroll/VBox/Title, false, true)
	UiTheme.style_progress(xp_bar)
	UiTheme.style_item_list(rewards_list)
	UiTheme.style_button(claim_btn, true)
	UiTheme.style_button(save_btn, false)
	PlayerData.profile_changed.connect(_refresh)
	PlayerData.badge_earned.connect(func(_id: String) -> void: _refresh())
	GameManager.quest_completed.connect(func(_id: String, _xp: int) -> void: _refresh())
	GameManager.tab_changed.connect(_on_tab)
	rewards_list.item_selected.connect(_on_reward_selected)
	claim_btn.pressed.connect(_on_claim)
	chaos_check.toggled.connect(func(v: bool) -> void:
		PlayerData.chaos_mode_enabled = v
		GameManager.quests_refresh_requested.emit()
	)
	tiles_check.toggled.connect(func(v: bool) -> void: PlayerData.use_real_tiles = v)
	save_btn.pressed.connect(_on_save)
	_refresh()


func _on_tab(tab: GameManager.Tab) -> void:
	if tab == GameManager.Tab.PROFILE:
		_refresh()


func _refresh() -> void:
	username_label.text = PlayerData.username
	rank_label.text = "Level %d — %s" % [PlayerData.level, PlayerData.rank_title]
	var prog: Dictionary = PlayerData.xp_progress_in_rank()
	xp_bar.max_value = maxi(int(prog["needed"]), 1)
	xp_bar.value = int(prog["current"])
	xp_label.text = "%d / %d XP to next rank  •  Total %d XP" % [int(prog["current"]), int(prog["needed"]), int(prog["total"])]
	streak_label.text = "Streak: %d days  •  Multiplier: %.1fx" % [PlayerData.streak, PlayerData.get_streak_multiplier()]
	coins_label.text = "Coins: %d  (earn from quests, spend on rewards)" % PlayerData.coins
	quests_label.text = "Quests completed: %d" % PlayerData.quests_completed
	ai_label.text = "AI photo verifications: %d" % PlayerData.ai_photos_verified
	chaos_check.button_pressed = PlayerData.chaos_mode_enabled
	tiles_check.button_pressed = PlayerData.use_real_tiles
	name_edit.text = PlayerData.username
	avatar.color = _color_from_name(PlayerData.username)
	_refresh_badges()
	_refresh_rewards()


func _refresh_badges() -> void:
	for child in badges_grid.get_children():
		child.queue_free()
	for badge_id in QuestData.BADGE_DEFS:
		var def: Dictionary = QuestData.BADGE_DEFS[badge_id]
		var earned: bool = PlayerData.has_badge(badge_id)
		var badge: Label = Label.new()
		badge.text = ("🏅 " if earned else "🔒 ") + def["name"]
		badge.tooltip_text = def["desc"]
		badge.add_theme_color_override("font_color", UiTheme.GOLD if earned else UiTheme.TEXT_MUTED)
		badges_grid.add_child(badge)


func _refresh_rewards() -> void:
	rewards_list.clear()
	for reward in QuestData.REWARDS:
		var claimed: bool = reward["id"] in PlayerData.rewards_claimed
		var prefix: String = "✓ " if claimed else ""
		rewards_list.add_item("%s%s — %d coins" % [prefix, reward["name"], reward["cost"]])
	claim_btn.disabled = _selected_reward_id.is_empty()


func _on_reward_selected(index: int) -> void:
	if index < 0 or index >= QuestData.REWARDS.size():
		return
	_selected_reward_id = QuestData.REWARDS[index]["id"]
	claim_btn.disabled = _selected_reward_id in PlayerData.rewards_claimed


func _on_claim() -> void:
	if PlayerData.claim_reward(_selected_reward_id):
		GameManager.toast_requested.emit("Reward claimed! Show coins at partner location.")
		_refresh_rewards()
	else:
		GameManager.toast_requested.emit("Not enough coins or already claimed.")


func _on_save() -> void:
	PlayerData.username = name_edit.text.strip_edges()
	if PlayerData.username.is_empty():
		PlayerData.username = "Explorer"
	PlayerData.profile_changed.emit()


func _color_from_name(user_name: String) -> Color:
	var h: int = user_name.hash()
	return Color(((h & 0xFF) / 255.0) * 0.5 + 0.3, (((h >> 8) & 0xFF) / 255.0) * 0.5 + 0.3, (((h >> 16) & 0xFF) / 255.0) * 0.5 + 0.4)
