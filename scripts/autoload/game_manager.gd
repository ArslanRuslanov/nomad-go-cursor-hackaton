extends Node
## Global game state, navigation, and quest lifecycle.

enum Tab { MAP, NEARBY, LEADERBOARD, PROFILE }

signal tab_changed(tab: Tab)
signal quest_selected(quest_info)
signal quest_accepted(quest_id: String)
signal quest_completed(quest_id: String, xp_earned: int)
signal quest_failed(quest_id: String)
signal photo_verification_requested(quest_id: String)
signal boss_unlocked()
signal toast_requested(message: String)
signal show_quest_complete(xp: int, quest_title: String)
signal show_level_up(new_level: int, rank_title: String)
signal onboarding_finished()
signal quests_refresh_requested()

const ACCEPT_RADIUS_M := 100.0
const PULSE_RADIUS_M := 100.0
const TOAST_RADIUS_M := 50.0
const BOSS_UNLOCK_COUNT := 5
const MYSTERY_UNLOCK_COUNT := 5
const MYSTERY_REVEAL_M := 200.0
const QUEST_EXPIRE_HOURS := 2

var current_tab: Tab = Tab.MAP
var all_quests: Array[Dictionary] = []
var selected_quest: Dictionary = {}
var active_quest: Dictionary = {}
var boss_unlocked_flag: bool = false
var onboarding_done: bool = false
var _toast_sent: Dictionary = {}  # quest_id -> last toast distance bucket


func _ready() -> void:
	pass


func finish_onboarding(username: String, city_key: String) -> void:
	PlayerData.setup_player(username, city_key)
	all_quests = QuestData.get_default_quests(city_key)
	all_quests.append(QuestData.get_daily_challenge(city_key))
	all_quests.append(QuestData.get_mystery_quest(city_key))
	_hide_boss_until_unlocked()
	_hide_mystery_until_unlocked()
	onboarding_done = true
	onboarding_finished.emit()
	change_tab(Tab.MAP)


func change_tab(tab: Tab) -> void:
	current_tab = tab
	tab_changed.emit(tab)


func get_quest_by_id(quest_id: String) -> Dictionary:
	for q in all_quests:
		if q.get("id", "") == quest_id:
			return q
	return {}


func get_visible_quests() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for q in all_quests:
		if q.get("hidden", false) and not boss_unlocked_flag:
			continue
		if q.get("chaos_mode", false) and not PlayerData.chaos_mode_enabled:
			continue
		if q.get("is_mystery", false) and not PlayerData.mystery_unlocked:
			continue
		result.append(q)
	return result


func get_daily_challenge() -> Dictionary:
	for q in all_quests:
		if q.get("is_daily", false):
			return q
	return {}


func get_mystery_quest() -> Dictionary:
	for q in all_quests:
		if q.get("is_mystery", false):
			return q
	return {}


func is_mystery_revealed(quest: Dictionary) -> bool:
	if not quest.get("is_mystery", false):
		return true
	return distance_to_quest(quest) <= MYSTERY_REVEAL_M


func get_quest_display_title(quest: Dictionary) -> String:
	if quest.get("is_mystery", false) and not is_mystery_revealed(quest):
		return str(quest.get("mystery_title_hidden", "???"))
	return str(quest.get("title", "Quest"))


func request_photo_verification(quest_id: String) -> void:
	var quest: Dictionary = get_quest_by_id(quest_id)
	if quest.is_empty():
		return
	if not is_quest_in_range(quest):
		toast_requested.emit("Get to the quest location first!")
		return
	photo_verification_requested.emit(quest_id)


func accept_quest(quest_id: String) -> bool:
	var quest: Dictionary = get_quest_by_id(quest_id)
	if quest.is_empty() or quest.get("completed", false):
		return false
	if not active_quest.is_empty():
		toast_requested.emit("Finish your active quest first!")
		return false
	var dist: float = GeoUtils.distance_meters(
		PlayerData.latitude, PlayerData.longitude,
		quest["latitude"], quest["longitude"]
	)
	if dist > ACCEPT_RADIUS_M:
		toast_requested.emit("Get closer! %.0fm away." % dist)
		return false
	quest["accepted"] = true
	active_quest = quest.duplicate(true)
	active_quest["expires_at"] = int(Time.get_unix_time_from_system()) + QUEST_EXPIRE_HOURS * 3600
	quest_accepted.emit(quest_id)
	return true


func complete_quest(quest_id: String, proof_answer: String = "", photo_verified: bool = false) -> void:
	var quest: Dictionary = get_quest_by_id(quest_id)
	if quest.is_empty() or quest.get("completed", false):
		return
	if quest.get("type") == "photo" and not photo_verified:
		request_photo_verification(quest_id)
		return
	if quest.get("type") == "trivia" or quest.get("type") == "puzzle":
		var expected: String = str(quest.get("answer", "")).to_lower()
		if not expected.is_empty() and proof_answer.strip_edges().to_lower() != expected:
			toast_requested.emit("Wrong answer! Look around for clues.")
			quest_failed.emit(quest_id)
			return
	var dist: float = GeoUtils.distance_meters(
		PlayerData.latitude, PlayerData.longitude,
		quest["latitude"], quest["longitude"]
	)
	if dist > ACCEPT_RADIUS_M:
		toast_requested.emit("You must be at the quest location!")
		return
	var base_xp: int = int(quest.get("xp_reward", 50))
	if quest.get("is_daily", false):
		base_xp *= 2
	var multiplier: float = PlayerData.get_streak_multiplier()
	var xp_earned: int = int(base_xp * multiplier)
	if quest.get("is_daily", false):
		PlayerData.daily_challenge_completed = true
	if photo_verified:
		PlayerData.ai_photos_verified += 1
	quest["completed"] = true
	quest["accepted"] = false
	active_quest = {}
	var leveled: bool = PlayerData.award_quest_completion(quest, xp_earned)
	_check_boss_unlock()
	_check_mystery_unlock()
	quest_completed.emit(quest_id, xp_earned)
	show_quest_complete.emit(xp_earned, quest.get("title", "Quest"))
	if leveled:
		var rank: Dictionary = QuestData.get_rank_for_xp(PlayerData.total_xp)
		show_level_up.emit(rank["level"], rank["title"])


func dismiss_active_quest() -> void:
	if active_quest.is_empty():
		return
	var q: Dictionary = get_quest_by_id(active_quest.get("id", ""))
	if not q.is_empty():
		q["accepted"] = false
	active_quest = {}


func check_proximity() -> void:
	for quest in get_visible_quests():
		if quest.get("completed", false):
			continue
		var dist: float = GeoUtils.distance_meters(
			PlayerData.latitude, PlayerData.longitude,
			quest["latitude"], quest["longitude"]
		)
		var qid: String = quest.get("id", "")
		if dist <= PULSE_RADIUS_M:
			if dist <= TOAST_RADIUS_M:
				var bucket: int = int(dist / 10.0)
				if not _toast_sent.get(qid, -1) == bucket:
					_toast_sent[qid] = bucket
					toast_requested.emit("Quest nearby — keep walking! (%s)" % quest.get("title", ""))


func distance_to_quest(quest: Dictionary) -> float:
	return GeoUtils.distance_meters(
		PlayerData.latitude, PlayerData.longitude,
		quest.get("latitude", 0.0), quest.get("longitude", 0.0)
	)


func is_quest_in_range(quest: Dictionary) -> bool:
	return distance_to_quest(quest) <= ACCEPT_RADIUS_M


func is_quest_pulsing(quest: Dictionary) -> bool:
	return distance_to_quest(quest) <= PULSE_RADIUS_M and not quest.get("completed", false)


func add_custom_quest(title: String, quest_type: String, xp: int) -> bool:
	if PlayerData.level < 10:
		toast_requested.emit("Reach Level 10 (City Hunter) to create quests!")
		return false
	var quest: Dictionary = {
		"id": "custom_%d" % Time.get_unix_time_from_system(),
		"title": title,
		"description": "Player-created quest at this location.",
		"type": quest_type,
		"latitude": PlayerData.latitude,
		"longitude": PlayerData.longitude,
		"radius_meters": 100.0,
		"xp_reward": xp,
		"difficulty": "medium",
		"chaos_mode": false,
		"answer": "",
		"hidden": false,
		"completed": false,
		"accepted": false,
	}
	all_quests.append(quest)
	toast_requested.emit("Quest created! It now appears on the map.")
	quests_refresh_requested.emit()
	return true


func get_sorted_quests_by_distance() -> Array[Dictionary]:
	var quests: Array[Dictionary] = get_visible_quests()
	quests.sort_custom(func(a, b):
		return distance_to_quest(a) < distance_to_quest(b)
	)
	return quests


func get_nearby_completed_count() -> int:
	var count: int = 0
	for q in all_quests:
		if q.get("completed", false) and distance_to_quest(q) <= 500.0:
			count += 1
	return count


func _hide_boss_until_unlocked() -> void:
	for q in all_quests:
		if q.get("type") == "boss":
			q["hidden"] = true


func _hide_mystery_until_unlocked() -> void:
	for q in all_quests:
		if q.get("is_mystery", false):
			q["hidden"] = true


func _check_mystery_unlock() -> void:
	if PlayerData.mystery_unlocked:
		return
	if PlayerData.quests_completed >= MYSTERY_UNLOCK_COUNT:
		PlayerData.mystery_unlocked = true
		for q in all_quests:
			if q.get("is_mystery", false):
				q["hidden"] = false
		quests_refresh_requested.emit()
		toast_requested.emit("MYSTERY QUEST unlocked! Check the map.")
		PlayerData.profile_changed.emit()


func _check_boss_unlock() -> void:
	if boss_unlocked_flag:
		return
	if get_nearby_completed_count() >= BOSS_UNLOCK_COUNT:
		boss_unlocked_flag = true
		for q in all_quests:
			if q.get("type") == "boss":
				q["hidden"] = false
		boss_unlocked.emit()
		toast_requested.emit("BOSS QUEST UNLOCKED! Check the map!")
