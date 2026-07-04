class_name BgFx
extends Control
## Soft floating color orbs behind every screen, per the KNOTS design.

var _dots: Array = []
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var picks := [Color("#ff5c72"), Color("#37e08c"), Color("#5ec8ff"),
			Color("#ffcc33"), Color("#b775f5")]
	for i in 9:
		_dots.append({
			"base": Vector2(rng.randf() * 720.0, rng.randf() * 1280.0),
			"r": rng.randf_range(16, 34),
			"amp": rng.randf_range(8, 18),
			"speed": rng.randf_range(0.5, 1.1),
			"phase": rng.randf() * TAU,
			"col": picks[i % picks.size()],
		})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for d in _dots:
		var p: Vector2 = d["base"] + Vector2(
			sin(_t * d["speed"] * 0.6 + d["phase"]) * d["amp"] * 0.6,
			sin(_t * d["speed"] + d["phase"]) * d["amp"])
		var r: float = d["r"]
		var col: Color = d["col"]
		# Layered circles fake the blurred glow from the mockup.
		draw_circle(p, r * 1.5, Color(col, 0.04), true, -1.0, true)
		draw_circle(p, r * 1.15, Color(col, 0.06), true, -1.0, true)
		draw_circle(p, r, Color(col, 0.12), true, -1.0, true)
