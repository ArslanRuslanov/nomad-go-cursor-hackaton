class_name QuestData
extends RefCounted
## Quest definitions, ranks, badges, and type metadata for QuestCity.

enum QuestType { SCAN, TRIVIA, PHOTO, PUZZLE, SOCIAL, BOSS, CHAOS }

const TYPE_NAMES := {
	QuestType.SCAN: "scan",
	QuestType.TRIVIA: "trivia",
	QuestType.PHOTO: "photo",
	QuestType.PUZZLE: "puzzle",
	QuestType.SOCIAL: "social",
	QuestType.BOSS: "boss",
	QuestType.CHAOS: "chaos",
}

const TYPE_ICONS := {
	"scan": "QR",
	"trivia": "?",
	"photo": "Cam",
	"puzzle": "Gear",
	"social": "People",
	"boss": "Skull",
	"chaos": "Chaos",
}

const TYPE_COLORS := {
	"scan": Color(0.2, 0.75, 0.45),
	"trivia": Color(0.25, 0.45, 0.95),
	"photo": Color(0.95, 0.55, 0.15),
	"puzzle": Color(0.9, 0.25, 0.25),
	"social": Color(0.85, 0.35, 0.75),
	"boss": Color(0.55, 0.25, 0.85),
	"chaos": Color(0.95, 0.85, 0.15),
}

const DIFFICULTY_LABELS := {
	"easy": "Easy",
	"medium": "Medium",
	"hard": "Hard",
	"legendary": "Legendary",
}

const RANKS := [
	{"level": 1, "title": "Street Rookie", "xp": 0},
	{"level": 5, "title": "Urban Scout", "xp": 500},
	{"level": 10, "title": "City Hunter", "xp": 1500},
	{"level": 20, "title": "District Legend", "xp": 5000},
	{"level": 50, "title": "QuestCity Master", "xp": 25000},
]

const BADGE_DEFS := {
	"first_quest": {"name": "First Steps", "desc": "Complete your first quest"},
	"streak_3": {"name": "On Fire", "desc": "3-day streak"},
	"streak_7": {"name": "Week Warrior", "desc": "7-day streak"},
	"chaos_master": {"name": "Chaos Master", "desc": "Complete 3 chaos quests"},
	"boss_slayer": {"name": "Boss Slayer", "desc": "Defeat a Boss Quest"},
	"explorer": {"name": "Urban Explorer", "desc": "Complete 10 quests"},
	"daily_done": {"name": "Daily Grinder", "desc": "Complete a Daily Challenge"},
	"mystery_found": {"name": "Mystery Solver", "desc": "Complete the Mystery Quest"},
	"ai_photographer": {"name": "AI Photographer", "desc": "Pass 3 AI photo verifications"},
}

const REWARDS := [
	{"id": "coffee", "name": "Free Coffee", "cost": 200, "desc": "Redeem at campus café"},
	{"id": "merch", "name": "QuestCity Sticker", "cost": 500, "desc": "Collectible sticker pack"},
	{"id": "vip", "name": "VIP Badge Frame", "cost": 1200, "desc": "Gold profile frame"},
]

const CITIES := {
	"bishkek": {"name": "Bishkek", "lat": 42.8746, "lon": 74.5698},
	"campus": {"name": "University Campus", "lat": 42.8758, "lon": 74.6033},
	"downtown": {"name": "Downtown", "lat": 42.8700, "lon": 74.5900},
}


static func get_rank_for_xp(total_xp: int) -> Dictionary:
	var current := RANKS[0]
	for rank in RANKS:
		if total_xp >= rank["xp"]:
			current = rank
	return current


static func xp_for_next_rank(total_xp: int) -> int:
	for rank in RANKS:
		if rank["xp"] > total_xp:
			return rank["xp"]
	return RANKS[-1]["xp"]


static func streak_multiplier(streak: int) -> float:
	if streak >= 14:
		return 3.0
	if streak >= 7:
		return 2.0
	if streak >= 3:
		return 1.5
	return 1.0


static func color_for_type(quest_type: String) -> Color:
	return TYPE_COLORS.get(quest_type, Color(0.5, 0.5, 0.5))


static func icon_for_type(quest_type: String) -> String:
	return TYPE_ICONS.get(quest_type, "?")


static func get_default_quests(city_key: String = "campus") -> Array[Dictionary]:
	var city: Dictionary = CITIES.get(city_key, CITIES["campus"])
	var base_lat: float = city["lat"]
	var base_lon: float = city["lon"]
	return [
		_make_quest("scan_library", "Library Entrance Scan", "Find the hidden QR code at the main library entrance.", "scan", base_lat + 0.001, base_lon + 0.001, 50, "easy", false),
		_make_quest("trivia_fountain", "Fountain History", "What year was the campus fountain built? (Hint: check the plaque)", "trivia", base_lat - 0.0008, base_lon + 0.0015, 100, "medium", false, "1987"),
		_make_quest("photo_mural", "Mural Hunter", "Photograph the street art mural on the east wall.", "photo", base_lat + 0.0012, base_lon - 0.001, 150, "medium", false),
		_make_quest("puzzle_statue", "Statue Riddle", "I stand tall but never walk. Count my steps and multiply by 3.", "puzzle", base_lat - 0.001, base_lon - 0.0005, 200, "hard", false, "36"),
		_make_quest("social_coffee", "Coffee Chat", "Ask someone at the campus café: 'What's the best hidden spot here?'", "social", base_lat + 0.0005, base_lon + 0.002, 250, "hard", false),
		_make_quest("scan_gym", "Gym Check-In", "Scan the QR at the outdoor fitness area.", "scan", base_lat - 0.0015, base_lon + 0.0008, 50, "easy", false),
		_make_quest("trivia_park", "Oak Park Trivia", "How many benches are in the central grove?", "trivia", base_lat + 0.002, base_lon + 0.0003, 100, "medium", false, "12"),
		_make_quest("photo_sunset", "Golden Hour", "Capture the sunset view from the hill overlook.", "photo", base_lat + 0.0018, base_lon + 0.0018, 150, "medium", false),
		_make_quest("scan_cafe", "Café Corner", "Scan the QR hidden near the campus café menu board.", "scan", base_lat - 0.0003, base_lon + 0.0022, 50, "easy", false),
		_make_quest("trivia_bridge", "Bridge Builder", "Who designed the pedestrian bridge? (Check the dedication plate)", "trivia", base_lat + 0.0007, base_lon - 0.0015, 100, "medium", false, "A. Kim"),
		_make_quest("puzzle_clock", "Clock Tower", "The clock shows 3:15. What is the angle between the hands?", "puzzle", base_lat - 0.0006, base_lon - 0.0012, 200, "hard", false, "7.5"),
		_make_quest("photo_arch", "Archway Frame", "Frame the historic archway in your photo.", "photo", base_lat + 0.0009, base_lon + 0.0006, 150, "medium", false),
		_make_quest("social_study", "Study Buddy", "Find someone studying alone and ask what they're working on.", "social", base_lat - 0.0012, base_lon + 0.0018, 250, "hard", false),
		_make_quest("scan_plaza", "Plaza Marker", "Scan the QR at the central plaza statue base.", "scan", base_lat + 0.0002, base_lon - 0.0008, 50, "easy", false),
		_make_quest("trivia_museum", "Campus Museum", "What artifact is displayed in room 2?", "trivia", base_lat - 0.0018, base_lon - 0.0003, 100, "medium", false, "Bronze compass"),
		# Chaos quests
		_make_quest("chaos_mime", "The Mime Quest", "Stand completely still at the fountain for 60 seconds. Passersby will be confused.", "chaos", base_lat + 0.0004, base_lon + 0.0009, 100, "medium", true),
		_make_quest("chaos_slow", "The Invisible Walk", "Walk as slowly as possible. Under 0.5 km/h for the full route = complete.", "chaos", base_lat - 0.0005, base_lon + 0.001, 150, "hard", true),
		_make_quest("chaos_npc", "The NPC Quest", "Say 'Have you heard of the Elder Scrolls?' to a real person. Photo proof required.", "chaos", base_lat + 0.001, base_lon - 0.0002, 200, "hard", true),
		_make_quest("chaos_calisthenics", "The Calisthenics Drop", "Find the nearest outdoor bar. Do a muscle-up. Selfie video required.", "chaos", base_lat - 0.0008, base_lon - 0.001, 500, "hard", true),
		# Boss quest (hidden until unlocked)
		_make_quest("boss_campus", "Campus Guardian", "Epic multi-step quest: visit 3 landmarks, solve the final riddle at the center.", "boss", base_lat, base_lon, 1000, "legendary", false, "", true),
	]


static func get_daily_challenge(city_key: String = "campus") -> Dictionary:
	var city: Dictionary = CITIES.get(city_key, CITIES["campus"])
	var base_lat: float = city["lat"]
	var base_lon: float = city["lon"]
	var q := _make_quest(
		"daily_%d" % Time.get_datetime_dict_from_system()["day"],
		"Daily: City Explorer",
		"Walk 500m and visit any real landmark today. AI-verified photo optional for bonus.",
		"photo", base_lat + 0.0006, base_lon + 0.0004, 200, "medium", false
	)
	q["is_daily"] = true
	q["photo_criteria"] = "outdoor landmark, urban scene, daylight"
	return q


static func get_mystery_quest(city_key: String = "campus") -> Dictionary:
	var city: Dictionary = CITIES.get(city_key, CITIES["campus"])
	var base_lat: float = city["lat"]
	var base_lon: float = city["lon"]
	var q := _make_quest(
		"mystery_quest",
		"The Hidden Door",
		"Find the unmarked alley mural behind the old bookstore. Only visible to those who walk.",
		"puzzle", base_lat - 0.0007, base_lon + 0.0011, 350, "hard", false, "7"
	)
	q["is_mystery"] = true
	q["hidden"] = true
	q["mystery_title_hidden"] = "???"
	return q


static func get_photo_ai_criteria(quest: Dictionary) -> String:
	if quest.has("photo_criteria"):
		return str(quest["photo_criteria"])
	match str(quest.get("type", "")):
		"photo":
			return "landmark visible, correct GPS, outdoor scene"
		"chaos":
			return "human subject, location match, action visible"
		_:
			return "location match, clear image"


static func get_leaderboard_seed() -> Array[Dictionary]:
	return [
		{"username": "QuestLord99", "total_xp": 8420, "city": "campus"},
		{"username": "StreetMime", "total_xp": 7100, "city": "campus"},
		{"username": "UrbanScout", "total_xp": 5800, "city": "campus"},
		{"username": "ChaosAgent", "total_xp": 4200, "city": "campus"},
		{"username": "SlowWalker", "total_xp": 3900, "city": "campus"},
		{"username": "PhotoNinja", "total_xp": 3100, "city": "campus"},
		{"username": "QR_Hunter", "total_xp": 2800, "city": "campus"},
		{"username": "PuzzleKing", "total_xp": 2100, "city": "campus"},
	]


static func _make_quest(
	id: String, title: String, description: String, quest_type: String,
	lat: float, lon: float, xp: int, difficulty: String,
	chaos_mode: bool, answer: String = "", hidden: bool = false
) -> Dictionary:
	return {
		"id": id,
		"title": title,
		"description": description,
		"type": quest_type,
		"latitude": lat,
		"longitude": lon,
		"radius_meters": 100.0,
		"xp_reward": xp,
		"difficulty": difficulty,
		"chaos_mode": chaos_mode,
		"answer": answer,
		"hidden": hidden,
		"completed": false,
		"accepted": false,
	}


static func verification_hint(quest_type: String) -> String:
	match quest_type:
		"scan":
			return "Walk to the pin and tap 'Scan QR' when within range."
		"trivia":
			return "Answer the location-specific question while nearby."
		"photo":
			return "Take a photo at the exact location."
		"puzzle":
			return "Solve the riddle — clues only make sense on-site."
		"social":
			return "Complete the social task and submit photo proof."
		"boss":
			return "Multi-step epic quest. Requires 5 nearby completions first."
		"chaos":
			return "Optional chaos quest. Screenshot-worthy."
		_:
			return "Walk to the location to complete."
