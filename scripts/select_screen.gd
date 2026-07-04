class_name SelectScreen
extends Control
## Level select, 1:1 with the mockup: back + SELECT LEVEL + coins header,
## then a zig-zag path of circular nodes (green 64px done with stars above,
## gold 68px pulsing current, gray 60px padlocked locked).

const NODE_STEP := 90.0

var main: Node
var pack_idx := 0

var _path_holder: Control
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

	_path_holder = Control.new()
	_path_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_path_holder)

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

	for child in _path_holder.get_children():
		child.queue_free()

	var pack: Dictionary = Levels.PACKS[pack_idx]
	if not Progress.pack_unlocked(pack_idx):
		var prev: Dictionary = Levels.PACKS[pack_idx - 1]
		_info.text = "Locked - finish 5 %s levels to open (%d/5)" % [
			prev["name"], Progress.completed_count(pack_idx - 1)]
		_path_holder.custom_minimum_size = Vector2.ZERO
		return

	var count := int(pack["count"])
	_info.text = "%s  -  %d/%d solved" % [pack["name"], Progress.completed_count(pack_idx), count]

	var total_h := count * NODE_STEP + 60.0
	_path_holder.custom_minimum_size = Vector2(0, total_h)

	var current := -1
	for i in count:
		if not Progress.is_completed(Levels.level_id(pack_idx, i)):
			current = i
			break

	var current_y := 0.0
	for i in count:
		var node := _level_node(i, current)
		var y := total_h - 90.0 - i * NODE_STEP
		node.set_meta("xoff", -60.0 if i % 2 == 0 else 60.0)
		node.set_meta("ypos", y)
		_path_holder.add_child(node)
		if i == current:
			current_y = y
	if not _path_holder.resized.is_connected(_layout_nodes):
		_path_holder.resized.connect(_layout_nodes)
	_layout_nodes()

	# Scroll so the current level is roughly centered.
	if current >= 0:
		await get_tree().process_frame
		if is_instance_valid(_scroll):
			_scroll.scroll_vertical = int(clampf(current_y - _scroll.size.y * 0.5, 0.0, total_h))


func _layout_nodes() -> void:
	var cx := _path_holder.size.x / 2.0
	for child in _path_holder.get_children():
		if child.has_meta("xoff"):
			child.position = Vector2(
				cx + float(child.get_meta("xoff")) - child.size.x / 2.0,
				float(child.get_meta("ypos")))


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
