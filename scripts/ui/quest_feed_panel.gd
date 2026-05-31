extends Control
## Nearby quests tab — sorted by distance with filters.

@onready var filter_option: OptionButton = $Header/FilterOption
@onready var quest_list: ItemList = $Scroll/VBox/QuestList
@onready var detail_label: RichTextLabel = $Scroll/VBox/DetailLabel
@onready var create_btn: Button = $Header/CreateBtn
@onready var banner: PanelContainer = $Scroll/VBox/FeatureBanner

var _filtered: Array[Dictionary] = []


func _ready() -> void:
	UiTheme.apply_screen_bg(self)
	UiTheme.style_label($Header/Title, false, true)
	UiTheme.style_item_list(quest_list)
	UiTheme.style_button(create_btn, false)
	filter_option.add_item("All Types", 0)
	filter_option.add_item("Scan", 1)
	filter_option.add_item("Trivia", 2)
	filter_option.add_item("Photo / AI", 3)
	filter_option.add_item("Puzzle", 4)
	filter_option.add_item("Social", 5)
	filter_option.add_item("Chaos", 6)
	filter_option.add_item("Boss", 7)
	filter_option.item_selected.connect(func(_i: int) -> void: _populate())
	quest_list.item_selected.connect(_on_item_selected)
	create_btn.pressed.connect(_on_create)
	GameManager.tab_changed.connect(_on_tab)
	GameManager.quest_completed.connect(func(_id: String, _xp: int) -> void: _populate())
	GameManager.onboarding_finished.connect(_populate)


func _on_tab(tab: GameManager.Tab) -> void:
	if tab == GameManager.Tab.NEARBY:
		_populate()
		if banner.has_method("refresh"):
			banner.refresh()


func _populate() -> void:
	quest_list.clear()
	_filtered.clear()
	var filter_idx: int = filter_option.selected
	var type_filter: String = ""
	match filter_idx:
		1: type_filter = "scan"
		2: type_filter = "trivia"
		3: type_filter = "photo"
		4: type_filter = "puzzle"
		5: type_filter = "social"
		6: type_filter = "chaos"
		7: type_filter = "boss"
	for quest in GameManager.get_sorted_quests_by_distance():
		if quest.get("is_daily", false) or quest.get("is_mystery", false):
			continue
		if not type_filter.is_empty() and quest.get("type") != type_filter:
			continue
		_filtered.append(quest)
		var done: String = "✓ " if bool(quest.get("completed", false)) else ""
		var dist: String = GeoUtils.format_distance(GameManager.distance_to_quest(quest))
		quest_list.add_item("%s%s  [%s]  %s" % [done, GameManager.get_quest_display_title(quest), quest.get("type", ""), dist])
	create_btn.disabled = PlayerData.level < 10
	create_btn.text = "Create Quest" if PlayerData.level >= 10 else "Create (Lv.10+)"


func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _filtered.size():
		return
	var q: Dictionary = _filtered[index]
	var status: String = "Completed" if bool(q.get("completed", false)) else "Available"
	detail_label.text = (
		"[color=#cdb8ff][b]%s[/b][/color]\n\n%s\n\nType: %s  •  %s\nXP: %d  •  %s\n[color=#8f96a8]Status: %s[/color]"
		% [
			GameManager.get_quest_display_title(q), q["description"], q.get("type", ""),
			q.get("difficulty", ""), q.get("xp_reward", 0),
			GeoUtils.format_distance(GameManager.distance_to_quest(q)), status,
		]
	)


func _on_create() -> void:
	var dialog: AcceptDialog = preload("res://scenes/ui/create_quest_dialog.tscn").instantiate()
	add_child(dialog)
	dialog.popup_centered()
	dialog.tree_exited.connect(func() -> void: dialog.queue_free())
