extends Control
## 3-slide onboarding + sign up.

@onready var slide_label: RichTextLabel = $Center/VBox/SlideLabel
@onready var dots: HBoxContainer = $Center/VBox/Dots
@onready var next_btn: Button = $Center/VBox/NextBtn
@onready var signup_panel: VBoxContainer = $Center/VBox/SignupPanel
@onready var name_edit: LineEdit = $Center/VBox/SignupPanel/NameEdit
@onready var city_option: OptionButton = $Center/VBox/SignupPanel/CityOption
@onready var start_btn: Button = $Center/VBox/SignupPanel/StartBtn

const SLIDES := [
	"[center][b]Welcome to QuestCity[/b]\n\nWalk the city. Complete quests. Become legend.\n\nPokemon GO meets real-world tasks.[/center]",
	"[center][b]Discover & Complete[/b]\n\nQuest pins appear on the map at real GPS locations.\nWalk close, accept, and complete scan, trivia, photo, and chaos quests.[/center]",
	"[center][b]Level Up & Compete[/b]\n\nEarn XP, build streaks, unlock Boss Quests, and climb the city leaderboard.[/center]",
]

var _slide_idx: int = 0


func _ready() -> void:
	for key in QuestData.CITIES:
		var city: Dictionary = QuestData.CITIES[key]
		city_option.add_item(city["name"], city_option.item_count)
		city_option.set_item_metadata(city_option.item_count - 1, key)
	next_btn.pressed.connect(_on_next)
	start_btn.pressed.connect(_on_start)
	signup_panel.visible = false
	UiTheme.style_button(next_btn, true)
	UiTheme.style_button(start_btn, true)
	UiTheme.style_label($Center/VBox/Title, false, true)
	UiTheme.style_label($Center/VBox/Subtitle, true)
	_show_slide(0)


func _show_slide(idx: int) -> void:
	_slide_idx = idx
	slide_label.text = SLIDES[idx]
	next_btn.visible = idx < SLIDES.size() - 1
	signup_panel.visible = idx == SLIDES.size() - 1
	for i in dots.get_child_count():
		dots.get_child(i).modulate = Color.WHITE if i == idx else Color(0.4, 0.4, 0.45)


func _on_next() -> void:
	if _slide_idx < SLIDES.size() - 1:
		_show_slide(_slide_idx + 1)


func _on_start() -> void:
	var city_key: String = str(city_option.get_item_metadata(city_option.selected))
	GameManager.finish_onboarding(name_edit.text.strip_edges(), city_key)
