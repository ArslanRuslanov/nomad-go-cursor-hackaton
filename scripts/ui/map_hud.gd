extends Control
## Map overlay: XP bar, streak, zoom controls, coordinates.

@export var map_controller_path: NodePath

@onready var xp_label: Label = $TopBar/XpLabel
@onready var streak_label: Label = $TopBar/StreakLabel
@onready var coords_label: Label = $TopBar/CoordsLabel
@onready var btn_zoom_in: Button = $MapControls/BtnZoomIn
@onready var btn_zoom_out: Button = $MapControls/BtnZoomOut
@onready var btn_recenter: Button = $MapControls/BtnRecenter

var _map: MapController


func _ready() -> void:
	_map = _resolve_map_controller()
	btn_zoom_in.pressed.connect(func() -> void:
		if _map:
			_map.zoom_in()
	)
	btn_zoom_out.pressed.connect(func() -> void:
		if _map:
			_map.zoom_out()
	)
	btn_recenter.pressed.connect(func() -> void:
		if _map:
			_map.recenter_on_player()
	)
	if _map:
		_map.position_changed.connect(_on_position_changed)
	PlayerData.profile_changed.connect(_refresh_top)
	PlayerData.streak_updated.connect(_refresh_streak)
	GameManager.tab_changed.connect(_on_tab)
	_refresh_top()
	_on_position_changed(PlayerData.latitude, PlayerData.longitude)


func _resolve_map_controller() -> MapController:
	if not map_controller_path.is_empty() and has_node(map_controller_path):
		return get_node(map_controller_path) as MapController
	var main: Node = get_tree().root.get_node_or_null("Main")
	if main:
		return main.get_node_or_null("MapController") as MapController
	return null


func _on_tab(tab: GameManager.Tab) -> void:
	visible = tab == GameManager.Tab.MAP and GameManager.onboarding_done


func _refresh_top() -> void:
	xp_label.text = "Lv.%d %s  •  %d XP" % [PlayerData.level, PlayerData.rank_title, PlayerData.total_xp]
	xp_label.add_theme_color_override("font_color", UiTheme.TEXT)
	streak_label.text = "🔥 %dd (%.1fx)" % [PlayerData.streak, PlayerData.get_streak_multiplier()]
	streak_label.add_theme_color_override("font_color", UiTheme.GOLD)
	coords_label.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)


func _refresh_streak(streak: int, mult: float) -> void:
	streak_label.text = "🔥 %dd (%.1fx)" % [streak, mult]


func _on_position_changed(lat: float, lon: float) -> void:
	coords_label.text = "%.4f, %.4f" % [lat, lon]
