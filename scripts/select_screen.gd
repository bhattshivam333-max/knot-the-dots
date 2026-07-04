class_name SelectScreen
extends Control
## Candy-Crush-style level map: a winding dotted road through drawn terrain
## (hill bands, trees, bushes, sparkles), with level circles on the path -
## green done with stars, gold pulsing current, gray padlocked locked.

var main: Node
var pack_idx := 0

var _map: MapControl
var _scroll: ScrollContainer
var _info: Label
var _chips: Array[Button] = []


func _ready() -> void:
	pack_idx = int(Progress.get_setting("last_pack", 0))
	pack_idx = clampi(pack_idx, 0, Levels.PACKS.size() - 1)
	if not Progress.pack_unlocked(pack_idx):
		pack_idx = 0

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	margin.add_theme_constant_override("margin_top", 56)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var top := HBoxContainer.new()
	box.add_child(top)
	var back := UI.icon_button("‹")
	back.pressed.connect(func() -> void:
		Sfx.play("click")
		main.show_menu())
	top.add_child(back)
	var title := UI.label("SELECT LEVEL", 17, UI.TEXT_SOFT, UI.fredoka(600, 2))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(title)
	top.add_child(UI.CoinChip.new(Progress.coins(), true))

	var chip_grid := GridContainer.new()
	chip_grid.columns = 3
	chip_grid.add_theme_constant_override("h_separation", 8)
	chip_grid.add_theme_constant_override("v_separation", 8)
	box.add_child(chip_grid)
	for i in Levels.PACKS.size():
		var p: Dictionary = Levels.PACKS[i]
		var chip := UI.chunky_button("%s %dx%d" % [p["name"], p["size"], p["size"]], 11,
				"gold" if i == pack_idx else "purple")
		(chip as UI.ChunkyButton).edge = 4.0
		(chip as UI.ChunkyButton).radius = 14.0
		chip.custom_minimum_size = Vector2(0, 36)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var idx := i
		chip.pressed.connect(func() -> void:
			Sfx.play("click")
			pack_idx = idx
			Progress.set_setting("last_pack", idx)
			_refresh())
		chip_grid.add_child(chip)
		_chips.append(chip)

	_info = UI.label("", 13, UI.TEXT_DIM, UI.nunito(700))
	box.add_child(_info)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_scroll)

	_map = MapControl.new()
	_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_map)

	_refresh()


func _refresh() -> void:
	for i in _chips.size():
		var cb := _chips[i] as UI.ChunkyButton
		if i == pack_idx:
			cb.stops = UI.GRAD_GOLD
			cb.edge_color = UI.GOLD_DARK
			for st in ["font_color", "font_hover_color", "font_pressed_color"]:
				cb.add_theme_color_override(st, UI.GOLD_TEXT)
		else:
			cb.stops = UI.GRAD_PURPLE
			cb.edge_color = Color("#170f2b")
			for st in ["font_color", "font_hover_color", "font_pressed_color"]:
				cb.add_theme_color_override(st, UI.TEXT_SOFT)
		cb.modulate.a = 1.0 if Progress.pack_unlocked(i) else 0.55
		cb.queue_redraw()

	for child in _map.get_children():
		child.queue_free()

	var pack: Dictionary = Levels.PACKS[pack_idx]
	if not Progress.pack_unlocked(pack_idx):
		var prev: Dictionary = Levels.PACKS[pack_idx - 1]
		_info.text = "Locked - finish 5 %s levels to open (%d/5)" % [
			prev["name"], Progress.completed_count(pack_idx - 1)]
		_map.count = 0
		_map.custom_minimum_size = Vector2.ZERO
		_map.queue_redraw()
		return

	var count := int(pack["count"])
	_info.text = "%s  -  %d/%d solved" % [pack["name"], Progress.completed_count(pack_idx), count]

	var current := -1
	for i in count:
		if not Progress.is_completed(Levels.level_id(pack_idx, i)):
			current = i
			break

	_map.count = count
	_map.current = current
	_map.pack_idx = pack_idx
	_map.custom_minimum_size = Vector2(0, count * MapControl.STEP + 170.0)
	_map.queue_redraw()

	for i in count:
		var node := _level_node(i, current)
		node.set_meta("idx", i)
		_map.add_child(node)
	if not _map.resized.is_connected(_layout_nodes):
		_map.resized.connect(_layout_nodes)
	_layout_nodes()

	# Scroll so the current level is roughly centered.
	if current >= 0:
		await get_tree().process_frame
		if is_instance_valid(_scroll):
			_scroll.scroll_vertical = int(clampf(
				_map.pos_of(current).y - _scroll.size.y * 0.5, 0.0, _map.size.y))


func _layout_nodes() -> void:
	for child in _map.get_children():
		if child.has_meta("idx"):
			var p: Vector2 = _map.pos_of(int(child.get_meta("idx")))
			child.position = p - Vector2(child.size.x / 2.0, child.size.x / 2.0)


func _level_node(i: int, current: int) -> Control:
	var id := Levels.level_id(pack_idx, i)
	var stars: int = Progress.stars(id)
	var done := stars > 0
	var is_current := i == current
	var unlocked := done or is_current or i == 0

	var b := UI.ChunkyButton.new()
	var d: float
	if done:
		d = 64.0
		b.configure(UI.GRAD_GREEN, Color("#146b45"), 5.0, 32.0,
				Color("#0c3a24"), UI.fredoka(700), 22, 0.0)
	elif is_current:
		d = 68.0
		b.configure(UI.GRAD_GOLD, UI.GOLD_DARK, 6.0, 34.0,
				UI.GOLD_TEXT, UI.fredoka(700), 24, 0.0)
	else:
		d = 60.0
		b.configure(UI.GRAD_LOCKED, Color("#221c33"), 5.0, 30.0,
				Color(1, 1, 1, 0.6), UI.fredoka(700), 20, 0.0)
	b.custom_minimum_size = Vector2(d, d + b.edge)
	b.size = b.custom_minimum_size
	b.text = str(i + 1) if unlocked else ""

	if not unlocked:
		b.disabled = true
		b.add_child(UI.center_icon(UI.LockIcon.new(), 13.0))
	else:
		var idx := i
		b.pressed.connect(func() -> void:
			Sfx.play("click")
			main.show_game(pack_idx, idx))

	if done:
		var sr := StarRow.new()
		sr.star_size = 12.0
		sr.count = stars
		sr.position = Vector2((d - sr.custom_minimum_size.x) / 2.0, -18.0)
		sr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(sr)

	if is_current:
		var ring := UI.PulseRing.new()
		ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ring.offset_bottom = -b.edge
		b.add_child(ring)

	return b


## The scrolling world map: terrain bands, decorations and the winding road.
class MapControl:
	extends Control

	const STEP := 104.0

	# Muted night-terrain bands; the start index rotates per pack so each
	# pack journeys through different scenery.
	const BANDS := [
		Color("#203520"), # meadow
		Color("#16304a"), # lake
		Color("#2e2347"), # violet hills
		Color("#38301a"), # desert
		Color("#1a3231"), # teal forest
		Color("#331f2c"), # rose canyon
	]

	var count := 0
	var current := -1
	var pack_idx := 0

	func _ready() -> void:
		resized.connect(queue_redraw)

	## Center of level node i on the serpentine road.
	func pos_of(i: int) -> Vector2:
		var amp := minf(112.0, size.x / 2.0 - 68.0)
		return Vector2(
			size.x / 2.0 + sin(i * 0.85 + 0.6) * amp,
			size.y - 100.0 - i * STEP)

	func _draw() -> void:
		if size.y < 10.0:
			return
		var rng := RandomNumberGenerator.new()
		rng.seed = 4242 + pack_idx * 77

		# Terrain bands with wavy tops, painted top to bottom.
		var y := -60.0
		var bi := pack_idx
		while y < size.y:
			var col: Color = BANDS[bi % BANDS.size()]
			var pts := PackedVector2Array()
			var steps := 26
			for k in steps + 1:
				var x := k * size.x / steps
				pts.append(Vector2(x, y + sin(x * 0.028 + bi * 1.7) * 16.0))
			pts.append(Vector2(size.x, size.y))
			pts.append(Vector2(0, size.y))
			draw_colored_polygon(pts, Color(col, 0.88))
			y += 340.0 + rng.randf() * 160.0
			bi += 1

		# Decorations, kept off the road corridor.
		for i in int(size.y / 42.0):
			var p := Vector2(rng.randf() * (size.x - 24.0) + 12.0,
					rng.randf() * (size.y - 80.0) + 20.0)
			var kind := rng.randi_range(0, 3)
			if count > 0:
				var fi := (size.y - 100.0 - p.y) / STEP
				var near := clampi(roundi(fi), 0, count - 1)
				var too_close := false
				for j in [near - 1, near, near + 1]:
					if j >= 0 and j < count and pos_of(j).distance_to(p) < 70.0:
						too_close = true
						break
				if too_close:
					continue
			match kind:
				0:
					_tree(p, rng)
				1:
					_bush(p, rng)
				2:
					_sparkle(p, rng)
				3:
					_rock(p, rng)

		# The road: dark groove, soft fill, then dotted trail
		# (bright up to the current level, faint beyond it).
		if count < 2:
			return
		var curve := Curve2D.new()
		curve.bake_interval = 9.0
		for i in count:
			var p := pos_of(i)
			var tangent := (pos_of(mini(i + 1, count - 1)) - pos_of(maxi(i - 1, 0))) * 0.21
			curve.add_point(p, -tangent, tangent)
		var baked := curve.get_baked_points()
		if baked.size() >= 2:
			draw_polyline(baked, Color(0, 0, 0, 0.3), 26.0, true)
			draw_polyline(baked, Color(1, 1, 1, 0.06), 17.0, true)
		var cur_y := pos_of(current).y if current >= 0 else -1e9
		var k := 0
		while k < baked.size():
			var q := baked[k]
			var reached := q.y >= cur_y - 20.0
			draw_circle(q, 2.6, Color(1, 1, 1, 0.5 if reached else 0.16), true, -1.0, true)
			k += 2

	func _tree(p: Vector2, rng: RandomNumberGenerator) -> void:
		var s := rng.randf_range(16.0, 26.0)
		var trunk := StyleBoxFlat.new()
		trunk.bg_color = Color("#3a2b20")
		trunk.set_corner_radius_all(1)
		draw_style_box(trunk, Rect2(p.x - 2.0, p.y - 2.0, 4.0, 8.0))
		var dark := Color("#173d28")
		var lite := Color("#1f5236")
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(-s * 0.5, -2.0), p + Vector2(s * 0.5, -2.0), p + Vector2(0, -s * 0.85)]), dark)
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(-s * 0.38, -s * 0.45), p + Vector2(s * 0.38, -s * 0.45),
			p + Vector2(0, -s * 1.25)]), lite)

	func _bush(p: Vector2, rng: RandomNumberGenerator) -> void:
		var r := rng.randf_range(5.0, 9.0)
		var col := Color("#245238")
		draw_circle(p + Vector2(-r * 0.8, 0), r * 0.85, col, true, -1.0, true)
		draw_circle(p + Vector2(r * 0.8, 0), r * 0.85, col, true, -1.0, true)
		draw_circle(p + Vector2(0, -r * 0.5), r, col.lightened(0.08), true, -1.0, true)

	func _sparkle(p: Vector2, rng: RandomNumberGenerator) -> void:
		var s := rng.randf_range(3.0, 5.5)
		var col := Color(1, 1, 1, 0.28)
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(0, -s), p + Vector2(s * 0.32, 0),
			p + Vector2(0, s), p + Vector2(-s * 0.32, 0)]), col)
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(-s, 0), p + Vector2(0, s * 0.32),
			p + Vector2(s, 0), p + Vector2(0, -s * 0.32)]), col)

	func _rock(p: Vector2, rng: RandomNumberGenerator) -> void:
		var s := rng.randf_range(5.0, 9.0)
		var col := Color(1, 1, 1, 0.09)
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(-s, 0), p + Vector2(-s * 0.4, -s * 0.7),
			p + Vector2(s * 0.5, -s * 0.55), p + Vector2(s, 0)]), col)
