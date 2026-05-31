extends Control
## Full-screen city leaderboard tab.

@onready var list: ItemList = $Scroll/List
@onready var rank_label: Label = $Scroll/YourRankLabel
@onready var subtitle: Label = $Scroll/Subtitle
@onready var title_label: Label = $Scroll/Title


func _ready() -> void:
	UiTheme.apply_screen_bg(self)
	UiTheme.style_label(title_label, false, true)
	UiTheme.style_label(subtitle, true)
	UiTheme.style_label(rank_label, false)
	UiTheme.style_item_list(list)
	GameManager.tab_changed.connect(_on_tab)
	GameManager.quest_completed.connect(func(_id: String, _xp: int) -> void: _refresh())
	PlayerData.profile_changed.connect(_refresh)
	subtitle.text = "Real explorers • Real XP • %s" % QuestData.CITIES.get(PlayerData.city, {}).get("name", "Your City")


func _on_tab(tab: GameManager.Tab) -> void:
	if tab == GameManager.Tab.LEADERBOARD:
		_refresh()


func _refresh() -> void:
	list.clear()
	var board: Array[Dictionary] = PlayerData.get_full_leaderboard()
	var player_rank: int = 0
	for i in board.size():
		var entry: Dictionary = board[i]
		var marker: String = "  ★ YOU" if bool(entry.get("is_player", false)) else ""
		list.add_item("#%d   %s   —   %d XP%s" % [i + 1, entry["username"], entry["total_xp"], marker])
		if bool(entry.get("is_player", false)):
			player_rank = i + 1
	rank_label.text = "Your rank: #%d of %d" % [player_rank, board.size()] if player_rank > 0 else "Your rank: —"
