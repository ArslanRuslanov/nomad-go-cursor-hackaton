extends Node2D
class_name QuestSpawner
## Spawns and updates quest markers on the map.

const MARKER_SCENE := preload("res://scenes/map/quest_marker.tscn")

@export var map_controller_path: NodePath

var _map: MapController
var _markers: Dictionary = {}


func _ready() -> void:
	if map_controller_path:
		_map = get_node(map_controller_path) as MapController
	GameManager.onboarding_finished.connect(_spawn_all)
	GameManager.quest_completed.connect(_on_quest_completed)
	GameManager.boss_unlocked.connect(_spawn_boss)
	GameManager.quests_refresh_requested.connect(_spawn_all)


func _spawn_all() -> void:
	_clear_markers()
	for quest in GameManager.get_visible_quests():
		_spawn_marker(quest)


func _spawn_boss() -> void:
	for quest in GameManager.all_quests:
		if quest.get("type") == "boss" and not _markers.has(quest["id"]):
			_spawn_marker(quest)


func _spawn_marker(quest: Dictionary) -> void:
	if _map == null or _markers.has(quest["id"]):
		return
	var marker: QuestMarker = MARKER_SCENE.instantiate()
	marker.marker_pressed.connect(_on_marker_pressed)
	_map.add_marker(marker, quest["latitude"], quest["longitude"])
	marker.setup(quest)
	_markers[quest["id"]] = marker


func _clear_markers() -> void:
	for id in _markers:
		if is_instance_valid(_markers[id]):
			_markers[id].queue_free()
	_markers.clear()


func _on_marker_pressed(quest_info: Dictionary) -> void:
	GameManager.selected_quest = quest_info
	GameManager.quest_selected.emit(quest_info)


func _on_quest_completed(quest_id: String) -> void:
	if _markers.has(quest_id):
		_markers[quest_id].refresh_state()
