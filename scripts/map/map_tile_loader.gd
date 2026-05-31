extends Node2D
class_name MapTileLoader
## Loads OpenStreetMap raster tiles around the player center.

signal tiles_ready

const OSM_TILE_URL := "https://tile.openstreetmap.org/%d/%d/%d.png"
const USER_AGENT := "QuestCity/1.0 (Godot educational project)"

@export var zoom_level: int = 14
@export var grid_radius: int = 2

var _center_tile: Vector2i
var _http: HTTPRequest
var _queue: Array[Dictionary] = []
var _loading: bool = false
var _loaded_count: int = 0


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 15
	add_child(_http)
	_http.request_completed.connect(_on_tile_downloaded)
	var use_tiles: bool = PlayerData.use_real_tiles and not OS.has_feature("web")
	if not use_tiles:
		_build_fallback_map()
	else:
		refresh_tiles(PlayerData.latitude, PlayerData.longitude)


func refresh_tiles(lat: float, lon: float) -> void:
	for child in get_children():
		if child is Sprite2D or child is ColorRect:
			child.queue_free()
	_queue.clear()
	_loading = false
	_loaded_count = 0
	_center_tile = GeoUtils.lat_lon_to_tile(lat, lon, zoom_level)
	for dx in range(-grid_radius, grid_radius + 1):
		for dy in range(-grid_radius, grid_radius + 1):
			_queue.append({
				"tile_x": _center_tile.x + dx,
				"tile_y": _center_tile.y + dy,
				"offset_x": dx,
				"offset_y": dy,
			})
	_process_queue()


func _process_queue() -> void:
	if _loading or _queue.is_empty():
		if not _loading and _queue.is_empty():
			if _loaded_count == 0:
				_build_fallback_map()
			else:
				tiles_ready.emit()
		return
	_loading = true
	var job: Dictionary = _queue.pop_front()
	var url: String = OSM_TILE_URL % [zoom_level, job["tile_x"], job["tile_y"]]
	var headers := ["User-Agent: %s" % USER_AGENT]
	_http.set_meta("job", job)
	var err: Error = _http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		_loading = false
		_process_queue()


func _on_tile_downloaded(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var job: Dictionary = _http.get_meta("job", {})
	_loading = false
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var img := Image.new()
		var err: Error = img.load_png_from_buffer(body)
		if err != OK:
			err = img.load_jpg_from_buffer(body)
		if err == OK:
			var tex := ImageTexture.create_from_image(img)
			var sprite := Sprite2D.new()
			sprite.texture = tex
			sprite.centered = false
			sprite.position = Vector2(
				job.get("offset_x", 0) * GeoUtils.TILE_SIZE,
				job.get("offset_y", 0) * GeoUtils.TILE_SIZE
			)
			add_child(sprite)
			_loaded_count += 1
	_process_queue()


func _build_fallback_map() -> void:
	for child in get_children():
		if child is Sprite2D or child is ColorRect:
			child.queue_free()
	var size: int = (grid_radius * 2 + 1) * GeoUtils.TILE_SIZE
	var bg: ColorRect = ColorRect.new()
	bg.size = Vector2(size, size)
	bg.color = Color(0.55, 0.58, 0.62)
	bg.position = Vector2(-grid_radius * GeoUtils.TILE_SIZE, -grid_radius * GeoUtils.TILE_SIZE)
	add_child(bg)
	_draw_streets(bg)
	_draw_label(bg, "QuestCity", Vector2(size * 0.38, size * 0.42))
	_draw_label(bg, "Campus", Vector2(size * 0.48, size * 0.38))
	tiles_ready.emit()


func _draw_streets(parent: ColorRect) -> void:
	var streets := [
		[Vector2(40, 200), Vector2(900, 220)],
		[Vector2(200, 80), Vector2(220, 700)],
		[Vector2(100, 400), Vector2(800, 420)],
	]
	for line in streets:
		var rect: ColorRect = ColorRect.new()
		var a: Vector2 = line[0]
		var b: Vector2 = line[1]
		var mid: Vector2 = (a + b) / 2.0
		var length: float = a.distance_to(b)
		rect.size = Vector2(length, 8)
		rect.color = Color(0.95, 0.95, 0.9)
		rect.position = mid - rect.size / 2.0
		rect.rotation = a.angle_to_point(b)
		parent.add_child(rect)


func _draw_label(parent: ColorRect, text: String, pos: Vector2) -> void:
	var label: Label = Label.new()
	label.text = text
	label.position = pos
	label.add_theme_color_override("font_color", Color(0.15, 0.2, 0.35))
	label.add_theme_font_size_override("font_size", 14)
	parent.add_child(label)
