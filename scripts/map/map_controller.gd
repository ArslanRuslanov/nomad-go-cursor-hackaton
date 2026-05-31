extends Node2D
class_name MapController
## Pan/zoom map centered on player GPS. Panning simulates walking.

signal zoom_changed(zoom: int)
signal position_changed(lat: float, lon: float)

@export var min_zoom: int = 12
@export var max_zoom: int = 17
@export var default_zoom: int = 14

@onready var tiles: MapTileLoader = $MapTiles
@onready var markers_layer: Node2D = $MarkersLayer
@onready var player_marker: Node2D = $PlayerMarker

var zoom_level: int = 14
var _dragging: bool = false
var _last_mouse: Vector2 = Vector2.ZERO
var _map_offset: Vector2 = Vector2.ZERO
var _screen_center: Vector2
var _center_lat: float
var _center_lon: float


func _ready() -> void:
	zoom_level = default_zoom
	_screen_center = get_viewport_rect().size / 2.0
	_center_lat = PlayerData.latitude
	_center_lon = PlayerData.longitude
	_center_on_player()
	if tiles:
		tiles.zoom_level = zoom_level
		tiles.tiles_ready.connect(_on_tiles_ready)
	GameManager.tab_changed.connect(_on_tab_changed)


func _process(_delta: float) -> void:
	_update_player_screen_position()
	GameManager.check_proximity()


func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.onboarding_done:
		return
	if GameManager.current_tab != GameManager.Tab.MAP:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
			_last_mouse = mb.position
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom_in()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom_out()
	elif event is InputEventMouseMotion and _dragging:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		var delta: Vector2 = mm.position - _last_mouse
		_last_mouse = mm.position
		_pan_map(delta)
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		_dragging = st.pressed
		_last_mouse = st.position
	elif event is InputEventScreenDrag and _dragging:
		var sd: InputEventScreenDrag = event as InputEventScreenDrag
		_pan_map(sd.relative)


func zoom_in() -> void:
	set_zoom(zoom_level + 1)


func zoom_out() -> void:
	set_zoom(zoom_level - 1)


func set_zoom(new_zoom: int) -> void:
	new_zoom = clampi(new_zoom, min_zoom, max_zoom)
	if new_zoom == zoom_level:
		return
	zoom_level = new_zoom
	if tiles:
		tiles.zoom_level = zoom_level
		tiles.refresh_tiles(PlayerData.latitude, PlayerData.longitude)
	zoom_changed.emit(zoom_level)
	_reposition_all_markers()


func _pan_map(pixel_delta: Vector2) -> void:
	_map_offset += pixel_delta
	if tiles:
		tiles.position = _map_offset
	markers_layer.position = _map_offset
	_update_simulated_gps_from_pan(pixel_delta)


func _update_simulated_gps_from_pan(delta: Vector2) -> void:
	var scale: float = 0.00002 * pow(2.0, 17 - zoom_level)
	PlayerData.longitude -= delta.x * scale
	PlayerData.latitude += delta.y * scale
	var clamped: Vector2 = GeoUtils.clamp_to_bounds(PlayerData.latitude, PlayerData.longitude)
	PlayerData.latitude = clamped.x
	PlayerData.longitude = clamped.y
	position_changed.emit(PlayerData.latitude, PlayerData.longitude)


func _center_on_player() -> void:
	_center_lat = PlayerData.latitude
	_center_lon = PlayerData.longitude
	var player_px: Vector2 = GeoUtils.lat_lon_to_pixel(PlayerData.latitude, PlayerData.longitude, zoom_level)
	var center_px: Vector2 = GeoUtils.lat_lon_to_pixel(_center_lat, _center_lon, zoom_level)
	_map_offset = _screen_center - (player_px - center_px)
	if tiles:
		tiles.position = _map_offset
	markers_layer.position = _map_offset


func lat_lon_to_map_position(lat: float, lon: float) -> Vector2:
	var px: Vector2 = GeoUtils.lat_lon_to_pixel(lat, lon, zoom_level)
	var center_px: Vector2 = GeoUtils.lat_lon_to_pixel(_center_lat, _center_lon, zoom_level)
	return _map_offset + (px - center_px)


func add_marker(marker: QuestMarker, lat: float, lon: float) -> void:
	markers_layer.add_child(marker)
	marker.position = lat_lon_to_map_position(lat, lon) - Vector2(16, 32)


func position_marker(marker: QuestMarker, lat: float, lon: float) -> void:
	marker.position = lat_lon_to_map_position(lat, lon) - Vector2(16, 32)


func _reposition_all_markers() -> void:
	for child in markers_layer.get_children():
		if child is QuestMarker:
			var q: Dictionary = child.quest_data
			position_marker(child, q["latitude"], q["longitude"])


func _update_player_screen_position() -> void:
	if player_marker:
		player_marker.position = _screen_center - Vector2(12, 24)


func recenter_on_player() -> void:
	_center_on_player()
	_reposition_all_markers()


func _on_tiles_ready() -> void:
	_reposition_all_markers()


func _on_tab_changed(tab: GameManager.Tab) -> void:
	visible = tab == GameManager.Tab.MAP and GameManager.onboarding_done
