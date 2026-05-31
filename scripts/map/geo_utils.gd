class_name GeoUtils
extends RefCounted
## Web Mercator helpers for map tiles, markers, and GPS distance.

const TILE_SIZE: int = 256
const EARTH_RADIUS_M: float = 6371000.0

const DEFAULT_CENTER_LAT: float = 42.8758
const DEFAULT_CENTER_LON: float = 74.6033
const DEFAULT_MIN_LAT: float = 42.82
const DEFAULT_MAX_LAT: float = 42.92
const DEFAULT_MIN_LON: float = 74.48
const DEFAULT_MAX_LON: float = 74.65


static func lat_lon_to_tile(lat: float, lon: float, zoom: int) -> Vector2i:
	var n: float = pow(2.0, zoom)
	var x: int = int(floor((lon + 180.0) / 360.0 * n))
	var lat_rad: float = deg_to_rad(lat)
	var y: int = int(floor((1.0 - log(tan(lat_rad) + 1.0 / cos(lat_rad)) / PI) / 2.0 * n))
	return Vector2i(x, y)


static func tile_to_pixel(tile_x: int, tile_y: int) -> Vector2:
	return Vector2(tile_x * TILE_SIZE, tile_y * TILE_SIZE)


static func lat_lon_to_pixel(lat: float, lon: float, zoom: int) -> Vector2:
	var tile: Vector2i = lat_lon_to_tile(lat, lon, zoom)
	var n: float = pow(2.0, zoom)
	var x_frac: float = (lon + 180.0) / 360.0 * n - tile.x
	var lat_rad: float = deg_to_rad(lat)
	var y_frac: float = (1.0 - log(tan(lat_rad) + 1.0 / cos(lat_rad)) / PI) / 2.0 * n - tile.y
	return tile_to_pixel(tile.x, tile.y) + Vector2(x_frac * TILE_SIZE, y_frac * TILE_SIZE)


static func distance_meters(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
	var phi1: float = deg_to_rad(lat1)
	var phi2: float = deg_to_rad(lat2)
	var d_phi: float = deg_to_rad(lat2 - lat1)
	var d_lambda: float = deg_to_rad(lon2 - lon1)
	var a: float = sin(d_phi / 2.0) ** 2 + cos(phi1) * cos(phi2) * sin(d_lambda / 2.0) ** 2
	return EARTH_RADIUS_M * 2.0 * atan2(sqrt(a), sqrt(1.0 - a))


static func clamp_to_bounds(lat: float, lon: float) -> Vector2:
	return Vector2(
		clampf(lat, DEFAULT_MIN_LAT, DEFAULT_MAX_LAT),
		clampf(lon, DEFAULT_MIN_LON, DEFAULT_MAX_LON)
	)


static func format_distance(meters: float) -> String:
	if meters < 1000.0:
		return "%.0f m" % meters
	return "%.1f km" % (meters / 1000.0)
