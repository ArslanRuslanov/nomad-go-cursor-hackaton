class_name UiTheme
extends RefCounted
## Dark RPG palette and style helpers for QuestCity.

const BG_DEEP := Color(0.06, 0.07, 0.1)
const BG_PANEL := Color(0.1, 0.11, 0.15)
const BG_CARD := Color(0.14, 0.15, 0.21)
const BG_ELEVATED := Color(0.18, 0.19, 0.26)
const ACCENT := Color(0.58, 0.38, 0.98)
const ACCENT_DIM := Color(0.4, 0.28, 0.72)
const GOLD := Color(1.0, 0.82, 0.35)
const SUCCESS := Color(0.35, 0.85, 0.55)
const DANGER := Color(0.95, 0.35, 0.4)
const TEXT := Color(0.92, 0.93, 0.97)
const TEXT_MUTED := Color(0.55, 0.58, 0.66)
const BORDER := Color(0.28, 0.3, 0.38)


static func style_panel(panel: PanelContainer, elevated: bool = false) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = BG_ELEVATED if elevated else BG_PANEL
	box.border_color = BORDER
	box.set_border_width_all(1)
	box.set_corner_radius_all(14)
	box.content_margin_left = 14
	box.content_margin_top = 12
	box.content_margin_right = 14
	box.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", box)


static func style_bar(panel: PanelContainer) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.09, 0.13, 0.98)
	box.border_color = BORDER
	box.border_width_top = 1
	box.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", box)


static func style_button(btn: Button, primary: bool = false) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = ACCENT if primary else BG_CARD
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", normal)
	btn.add_theme_stylebox_override("pressed", normal)
	btn.add_theme_color_override("font_color", TEXT)
	btn.add_theme_color_override("font_hover_color", TEXT)


static func style_label(label: Label, muted: bool = false, large: bool = false) -> void:
	label.add_theme_color_override("font_color", TEXT_MUTED if muted else TEXT)
	if large:
		label.add_theme_font_size_override("font_size", 22)


static func style_progress(bar: ProgressBar) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = BG_CARD
	bg.set_corner_radius_all(6)
	var fill := StyleBoxFlat.new()
	fill.bg_color = ACCENT
	fill.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)


static func style_item_list(list: ItemList) -> void:
	list.add_theme_color_override("font_color", TEXT)
	list.add_theme_color_override("font_selected_color", TEXT)
	list.add_theme_color_override("guide_color", BORDER)


static func apply_screen_bg(node: Control) -> void:
	var bg := node.get_node_or_null("PanelBg") as ColorRect
	if bg:
		bg.color = BG_DEEP


static func apply_root(main_ui: Control) -> void:
	for child in main_ui.get_children():
		if child is Control and child.name.ends_with("Panel"):
			apply_screen_bg(child as Control)
		if child.name == "BottomBar" and child is PanelContainer:
			style_bar(child as PanelContainer)
