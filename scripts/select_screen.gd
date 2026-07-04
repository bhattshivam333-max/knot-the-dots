class_name SelectScreen
extends Control
## Level select per the KNOTS design: back + coins header, pack chips,
## then a scrollable zig-zag path of circular level nodes
## (green = done with stars, gold pulsing = current, gray padlock = locked).

const NODE_STEP := 96.0
const NODE_SIZE := 68.0

var main: Node
var pack_idx := 0

var _path_holder: Control
var _scroll: ScrollContainer
var _info: Label
var _chips: Array[Button] = []
var _pulse_node: Button


func _ready() -> void:
	pack_idx = int(Progress.get_setting("last_pack", 0))
	pack_idx = clampi(pack_idx, 0, Levels.PACKS.size() - 1)
	if not Progress.pack_unlocked(pack_idx):
		pack_idx = 0

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var top := HBoxContainer.new()
	box.add_child(top)
	var back := UI.icon_button("<")
	back.pressed.connect(func() -> void:
		Sfx.play("click")
		main.show_menu())
	top.add_child(back)
	var title := UI.heading("SELECT LEVEL", 20, UI.TEXT_SOFT, 2)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(title)
	top.add_child(UI.CoinChip.new(Progress.coins(), true))

	var chip_grid := GridContainer.new()
	chip_grid.columns = 3
	chip_grid.add_theme_constant_override("h_separation", 10)
	chip_grid.add_theme_constant_override("v_separation", 10)
	box.add_child(chip_grid)
	for i in Levels.PACKS.size():
		var p: Dictionary = Levels.PACKS[i]
		var chip := UI.chunky_button("%s %dx%d" % [p["name"], p["size"], p["size"]], 13,
				"gold" if i == pack_idx else "purple")
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var idx := i
		chip.pressed.connect(func() -> void:
			Sfx.play("click")
			pack_idx = idx
			Progress.set_setting("last_pack", idx)
			_refresh())
		chip_grid.add_child(chip)
		_chips.append(chip)

	_info = UI.label("", 15, UI.TEXT_DIM, UI.nunito(700))
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
		var fresh := UI.chunky_button(_chips[i].text, 13, "gold" if i == pack_idx else "purple")
		for st in ["normal", "hover", "pressed"]:
			_chips[i].add_theme_stylebox_override(st, fresh.get_theme_stylebox(st))
		for cst in ["font_color", "font_hover_color", "font_pressed_color"]:
			_chips[i].add_theme_color_override(cst, fresh.get_theme_color(cst))
		_chips[i].modulate.a = 1.0 if Progress.pack_unlocked(i) else 0.55

	for child in _path_holder.get_children():
		child.queue_free()
	_pulse_node = null

	var pack: Dictionary = Levels.PACKS[pack_idx]
	if not Progress.pack_unlocked(pack_idx):
		var prev: Dictionary = Levels.PACKS[pack_idx - 1]
		_info.text = "Locked - finish 5 %s levels to open (%d/5)" % [
			prev["name"], Progress.completed_count(pack_idx - 1)]
		_path_holder.custom_minimum_size = Vector2.ZERO
		return

	var count := int(pack["count"])
	_info.text = "%s  -  %d/%d solved" % [pack["name"], Progress.completed_count(pack_idx), count]

	var total_h := count * NODE_STEP + 40.0
	_path_holder.custom_minimum_size = Vector2(0, total_h)

	var current := -1
	for i in count:
		if not Progress.is_completed(Levels.level_id(pack_idx, i)):
			current = i
			break

	var current_y := 0.0
	for i in count:
		var node := _level_node(i, current)
		var y := total_h - 80.0 - i * NODE_STEP
		node.set_meta("xoff", -62.0 if i % 2 == 0 else 62.0)
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
				cx + float(child.get_meta("xoff")) - NODE_SIZE / 2.0,
				float(child.get_meta("ypos")))


func _level_node(i: int, current: int) -> Control:
	var id := Levels.level_id(pack_idx, i)
	var stars: int = Progress.stars(id)
	var done := stars > 0
	var is_current := i == current
	var unlocked := done or is_current or i == 0

	var b := Button.new()
	b.custom_minimum_size = Vector2(NODE_SIZE, NODE_SIZE)
	b.add_theme_font_override("font", UI.fredoka(700))
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.text = str(i + 1) if unlocked else ""

	var bg: Color
	var edge: Color
	var fg: Color
	if done:
		bg = UI.GREEN; edge = Color("#146b45"); fg = UI.GREEN_TEXT
	elif is_current:
		bg = UI.GOLD; edge = UI.GOLD_DARK; fg = UI.GOLD_TEXT
	else:
		bg = UI.LOCKED_BG; edge = UI.LOCKED_DARK; fg = Color(1, 1, 1, 0.6)

	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(int(NODE_SIZE / 2.0))
	sb.border_width_bottom = 6
	sb.border_color = edge
	b.add_theme_stylebox_override("normal", sb)
	var sbh: StyleBoxFlat = sb.duplicate()
	sbh.bg_color = bg.lightened(0.06)
	b.add_theme_stylebox_override("hover", sbh)
	var sbp: StyleBoxFlat = sb.duplicate()
	sbp.border_width_bottom = 1
	b.add_theme_stylebox_override("pressed", sbp)
	b.add_theme_stylebox_override("disabled", sb)
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(st, fg)
	b.add_theme_color_override("font_disabled_color", fg)

	if not unlocked:
		b.disabled = true
		var lock := UI.LockIcon.new()
		lock.position = Vector2(NODE_SIZE / 2.0 - 12, NODE_SIZE / 2.0 - 15)
		b.add_child(lock)
	else:
		var idx := i
		b.pressed.connect(func() -> void:
			Sfx.play("click")
			main.show_game(pack_idx, idx))

	if done:
		var sr := StarRow.new()
		sr.star_size = 13.0
		sr.count = stars
		sr.position = Vector2((NODE_SIZE - sr.custom_minimum_size.x) / 2.0, -20)
		sr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(sr)

	if is_current:
		_pulse_node = b
		b.pivot_offset = Vector2(NODE_SIZE / 2.0, NODE_SIZE / 2.0)
		var tw := create_tween().set_loops()
		tw.tween_property(b, "scale", Vector2(1.06, 1.06), 0.7) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(b, "scale", Vector2.ONE, 0.7) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	return b
