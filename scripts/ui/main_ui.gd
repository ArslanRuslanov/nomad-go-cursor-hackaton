extends Control
## Root UI: bottom navigation, panel switching, overlays.

@onready var map_panel: Control = $MapPanel
@onready var nearby_panel: Control = $NearbyPanel
@onready var leaderboard_panel: Control = $LeaderboardPanel
@onready var profile_panel: Control = $ProfilePanel
@onready var onboarding: Control = $Onboarding
@onready var quest_detail: Control = $QuestDetailSheet
@onready var active_hud: Control = $ActiveQuestHUD
@onready var quest_complete: Control = $QuestCompleteScreen
@onready var toast: Control = $Toast
@onready var level_up_modal: Control = $LevelUpModal
@onready var ai_photo: Control = $AiPhotoPanel
@onready var btn_map: Button = $BottomBar/HBox/BtnMap
@onready var btn_nearby: Button = $BottomBar/HBox/BtnNearby
@onready var btn_rank: Button = $BottomBar/HBox/BtnRank
@onready var btn_profile: Button = $BottomBar/HBox/BtnProfile

var _panels: Dictionary = {}


func _ready() -> void:
	UiTheme.apply_root(self)
	_panels = {
		GameManager.Tab.MAP: map_panel,
		GameManager.Tab.NEARBY: nearby_panel,
		GameManager.Tab.LEADERBOARD: leaderboard_panel,
		GameManager.Tab.PROFILE: profile_panel,
	}
	btn_map.pressed.connect(func(): GameManager.change_tab(GameManager.Tab.MAP))
	btn_nearby.pressed.connect(func(): GameManager.change_tab(GameManager.Tab.NEARBY))
	btn_rank.pressed.connect(func(): GameManager.change_tab(GameManager.Tab.LEADERBOARD))
	btn_profile.pressed.connect(func(): GameManager.change_tab(GameManager.Tab.PROFILE))
	GameManager.tab_changed.connect(_on_tab_changed)
	GameManager.quest_selected.connect(_on_quest_selected)
	GameManager.onboarding_finished.connect(_on_onboarding_done)
	GameManager.quest_accepted.connect(_on_quest_accepted)
	GameManager.quest_completed.connect(_on_quest_completed)
	GameManager.photo_verification_requested.connect(_on_photo_verify)
	GameManager.toast_requested.connect(_show_toast)
	GameManager.show_quest_complete.connect(_on_show_complete)
	GameManager.show_level_up.connect(_on_level_up)
	$BottomBar.visible = false
	_on_tab_changed(GameManager.Tab.MAP)


func _on_onboarding_done() -> void:
	onboarding.visible = false
	$BottomBar.visible = true


func _on_tab_changed(tab: GameManager.Tab) -> void:
	if not GameManager.onboarding_done:
		return
	for key in _panels:
		_panels[key].visible = key == tab
	_update_nav_highlight(tab)


func _update_nav_highlight(tab: GameManager.Tab) -> void:
	var buttons: Array[Button] = [btn_map, btn_nearby, btn_rank, btn_profile]
	var active_idx: int = tab as int
	for i in buttons.size():
		var active: bool = i == active_idx
		buttons[i].modulate = UiTheme.TEXT if active else UiTheme.TEXT_MUTED


func _on_quest_selected(quest_info: Dictionary) -> void:
	if quest_detail.has_method("show_quest"):
		quest_detail.show_quest(quest_info)


func _on_quest_accepted(_quest_id: String) -> void:
	if active_hud.has_method("show_active"):
		active_hud.show_active(GameManager.active_quest)
	if quest_detail.has_method("hide_sheet"):
		quest_detail.hide_sheet()


func _on_quest_completed(_quest_id: String, _xp: int) -> void:
	if active_hud.has_method("hide_active"):
		active_hud.hide_active()


func _on_photo_verify(quest_id: String) -> void:
	if ai_photo.has_method("open_for_quest"):
		ai_photo.open_for_quest(quest_id)


func _show_toast(message: String) -> void:
	if toast.has_method("show_message"):
		toast.show_message(message)


func _on_show_complete(xp: int, title: String) -> void:
	if quest_complete.has_method("show_victory"):
		quest_complete.show_victory(xp, title)


func _on_level_up(new_level: int, rank_title: String) -> void:
	if level_up_modal.has_method("show_level_up"):
		level_up_modal.show_level_up(new_level, rank_title)
