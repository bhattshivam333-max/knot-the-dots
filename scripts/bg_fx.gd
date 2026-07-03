class_name BgFx
extends Control
## Slow-drifting translucent dots behind every screen.

var _dots: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 18:
		_dots.append({
			"pos": Vector2(rng.randf() * 720.0, rng.randf() * 1280.0),
			"vel": Vector2(rng.randf_range(-12, 12), rng.randf_range(-12, 12)),
			"r": rng.randf_range(14, 60),
			"col": Color(Levels.PALETTE[rng.randi_range(0, Levels.PALETTE.size() - 1)], 0.05),
		})


func _process(delta: float) -> void:
	for d in _dots:
		d["pos"] += d["vel"] * delta
		var p: Vector2 = d["pos"]
		var r: float = d["r"]
		if p.x < -r:
			p.x = size.x + r
		if p.x > size.x + r:
			p.x = -r
		if p.y < -r:
			p.y = size.y + r
		if p.y > size.y + r:
			p.y = -r
		d["pos"] = p
	queue_redraw()


func _draw() -> void:
	for d in _dots:
		draw_circle(d["pos"], d["r"], d["col"], true, -1.0, true)
