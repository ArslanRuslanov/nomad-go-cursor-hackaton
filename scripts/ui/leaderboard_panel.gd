extends PanelContainer
## City leaderboard overlay.

@onready var list: ItemList = $Margin/VBox/List
@onready var rank_label: Label = $Margin/VBox/YourRankLabel


func _ready() -> void:
	visible = false
	GameManager.quest_completed.connect(func(_id, _xp): _refresh())
	PlayerData.profile_changed.connect(_refresh)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		_refresh()


func _refresh() -> void:
	list.clear()
	var board: Array[Dictionary] = PlayerData.get_full_leaderboard()
	var player_rank: int = 0
	for i in board.size():
		var entry: Dictionary = board[i]
		var marker: String = " ★" if bool(entry.get("is_player", false)) else ""
		list.add_item("#%d  %s  —  %d XP%s" % [i + 1, entry["username"], entry["total_xp"], marker])
		if entry.get("is_player", false):
			player_rank = i + 1
	rank_label.text = "Your rank: #%d" % player_rank if player_rank > 0 else "Your rank: —"
