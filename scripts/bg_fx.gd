class_name BgFx
extends Control
## Floating blurred color orbs, using the mockup's exact four circles
## (size / position / opacity / float duration) plus a few extra subtle ones.

var _dots: Array = []
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The four orbs from the menu mockup: pos is the circle center at 390x844.
	_dots = [
		{"pos": Vector2(70, 150), "r": 30.0, "col": Color("#ff5c72"), "a": 0.35,
			"dur": 5.0, "phase": 0.0},
		{"pos": Vector2(334, 282), "r": 22.0, "col": Color("#37e08c"), "a": 0.3,
			"dur": 6.5, "phase": 0.6},
		{"pos": Vector2(78, 418), "r": 18.0, "col": Color("#5ec8ff"), "a": 0.3,
			"dur": 5.8, "phase": 1.1},
		{"pos": Vector2(307, 193), "r": 13.0, "col": Color("#ffcc33"), "a": 0.3,
			"dur": 4.6, "phase": 0.3},
		# Extra dim ones lower down so the whole screen breathes.
		{"pos": Vector2(120, 640), "r": 24.0, "col": Color("#b775f5"), "a": 0.12,
			"dur": 7.0, "phase": 2.0},
		{"pos": Vector2(320, 720), "r": 18.0, "col": Color("#ff5c72"), "a": 0.1,
			"dur": 6.0, "phase": 3.1},
	]


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for d in _dots:
		# CSS knotsFloat: translateY 0 -> -16 -> 0 over the duration.
		var f := fposmod((_t - d["phase"]) / d["dur"], 1.0)
		var dy := -16.0 * (0.5 - 0.5 * cos(f * TAU))
		var p: Vector2 = d["pos"] + Vector2(0, dy)
		var col: Color = d["col"]
		var a: float = d["a"]
		var r: float = d["r"]
		# Layered edge fades in for the CSS blur(2px).
		draw_circle(p, r + 2.0, Color(col, a * 0.35), true, -1.0, true)
		draw_circle(p, r, Color(col, a), true, -1.0, true)
