class_name StarRow
extends Control
## Draws up to 3 stars (filled/empty). Used on level buttons and the win panel.

var count := 0:
	set(v):
		count = v
		queue_redraw()
var star_size := 18.0:
	set(v):
		star_size = v
		custom_minimum_size = Vector2(star_size * 3.0 + star_size * 0.6, star_size)
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	star_size = 18.0


func _draw() -> void:
	var gap := star_size * 0.3
	var total := star_size * 3.0 + gap * 2.0
	var x0 := (size.x - total) / 2.0 + star_size / 2.0
	var cy := size.y / 2.0
	for i in 3:
		var c := Vector2(x0 + i * (star_size + gap), cy)
		var col := UI.GOLD if i < count else Color(1, 1, 1, 0.14)
		draw_colored_polygon(_star_points(c, star_size / 2.0), col)


func _star_points(center: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI / 2.0 + i * PI / 5.0
		var rad := r if i % 2 == 0 else r * 0.45
		pts.append(center + Vector2(cos(ang), sin(ang)) * rad)
	return pts
