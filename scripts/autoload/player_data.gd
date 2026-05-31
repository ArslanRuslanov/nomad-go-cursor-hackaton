extends Node
## Player profile: XP, streaks, badges, settings, simulated GPS.

signal profile_changed
signal badge_earned(badge_id: String)
signal streak_updated(streak: int, multiplier: float)

var username: String = "Explorer"
var city: String = "campus"
var total_xp: int = 0
var coins: int = 0
var level: int = 1
var rank_title: String = "Street Rookie"
var streak: int = 0
var last_quest_day: int = -1
var quests_completed: int = 0
var chaos_quests_completed: int = 0
var ai_photos_verified: int = 0
var mystery_unlocked: bool = false
var daily_challenge_completed: bool = false
var rewards_claimed: Array[String] = []
var badges: Array[String] = []

var latitude: float = 42.8758
var longitude: float = 74.6033

var sound_enabled: bool = true
var notifications_enabled: bool = true
var chaos_mode_enabled: bool = true
var use_real_tiles: bool = true
var map_style: String = "standard"


func setup_player(player_name: String, city_key: String) -> void:
	username = player_name if not player_name.strip_edges().is_empty() else "Explorer"
	city = city_key
	var city_data: Dictionary = QuestData.CITIES.get(city_key, QuestData.CITIES["campus"])
	latitude = city_data["lat"]
	longitude = city_data["lon"]
	profile_changed.emit()


func get_streak_multiplier() -> float:
	return QuestData.streak_multiplier(streak)


func award_quest_completion(quest: Dictionary, xp_earned: int) -> bool:
	total_xp += xp_earned
	coins += int(xp_earned * 0.5)
	quests_completed += 1
	if quest.get("chaos_mode", false):
		chaos_quests_completed += 1
	_update_streak()
	_check_badges(quest)
	var old_level: int = level
	_recalculate_rank()
	profile_changed.emit()
	streak_updated.emit(streak, get_streak_multiplier())
	return level > old_level


func _update_streak() -> void:
	var today: int = _day_number()
	if last_quest_day == today:
		return
	if last_quest_day == today - 1 or last_quest_day == -1:
		streak += 1
	else:
		streak = 1
	last_quest_day = today


func _day_number() -> int:
	var dt: Dictionary = Time.get_datetime_dict_from_system()
	return dt["year"] * 366 + dt["month"] * 31 + dt["day"]


func _recalculate_rank() -> void:
	var rank: Dictionary = QuestData.get_rank_for_xp(total_xp)
	level = rank["level"]
	rank_title = rank["title"]


func xp_progress_in_rank() -> Dictionary:
	var current_rank: Dictionary = QuestData.get_rank_for_xp(total_xp)
	var next_xp: int = QuestData.xp_for_next_rank(total_xp)
	var prev_xp: int = current_rank["xp"]
	if next_xp == prev_xp:
		return {"current": total_xp - prev_xp, "needed": 1, "total": total_xp}
	return {
		"current": total_xp - prev_xp,
		"needed": next_xp - prev_xp,
		"total": total_xp,
	}


func has_badge(badge_id: String) -> bool:
	return badge_id in badges


func _award_badge(badge_id: String) -> void:
	if badge_id in badges:
		return
	badges.append(badge_id)
	badge_earned.emit(badge_id)


func _check_badges(quest: Dictionary) -> void:
	if quests_completed == 1:
		_award_badge("first_quest")
	if streak >= 3:
		_award_badge("streak_3")
	if streak >= 7:
		_award_badge("streak_7")
	if chaos_quests_completed >= 3:
		_award_badge("chaos_master")
	if quest.get("type") == "boss":
		_award_badge("boss_slayer")
	if quest.get("is_daily", false):
		_award_badge("daily_done")
	if quest.get("is_mystery", false):
		_award_badge("mystery_found")
	if ai_photos_verified >= 3:
		_award_badge("ai_photographer")
	if quests_completed >= 10:
		_award_badge("explorer")


func claim_reward(reward_id: String) -> bool:
	for reward in QuestData.REWARDS:
		if reward["id"] == reward_id:
			if reward_id in rewards_claimed:
				return false
			if coins < int(reward["cost"]):
				return false
			coins -= int(reward["cost"])
			rewards_claimed.append(reward_id)
			profile_changed.emit()
			return true
	return false


func set_position(lat: float, lon: float) -> void:
	latitude = lat
	longitude = lon
	profile_changed.emit()


func get_leaderboard_entry() -> Dictionary:
	return {
		"username": username,
		"total_xp": total_xp,
		"city": city,
		"is_player": true,
	}


func get_full_leaderboard() -> Array[Dictionary]:
	var board: Array[Dictionary] = QuestData.get_leaderboard_seed()
	board.append(get_leaderboard_entry())
	board.sort_custom(func(a, b): return a["total_xp"] > b["total_xp"])
	return board
