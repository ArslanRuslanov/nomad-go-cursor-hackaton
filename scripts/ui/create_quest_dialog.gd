extends AcceptDialog
## Dialog for creating custom quests (Level 10+).

@onready var title_edit: LineEdit = $VBox/TitleEdit
@onready var type_option: OptionButton = $VBox/TypeOption
@onready var xp_spin: SpinBox = $VBox/XpSpin


func _ready() -> void:
	title = "Create Quest"
	for t in ["scan", "trivia", "photo", "puzzle", "social"]:
		type_option.add_item(t.capitalize())
	xp_spin.min_value = 25
	xp_spin.max_value = 500
	xp_spin.value = 100
	confirmed.connect(_on_confirm)


func _on_confirm() -> void:
	var title_text: String = title_edit.text.strip_edges()
	if title_text.is_empty():
		return
	var qtype: String = type_option.get_item_text(type_option.selected).to_lower()
	GameManager.add_custom_quest(title_text, qtype, int(xp_spin.value))
	title_edit.text = ""
