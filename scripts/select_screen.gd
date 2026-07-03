class_name SelectScreen
extends Control
## Level select: pack chips on top, scrollable grid of level buttons below.

var main: Node
var pack_idx := 0

var _grid: GridContainer
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
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var top := HBoxContainer.new()
	box.add_child(top)
	var back := UI.button("Back", 22)
	back.pressed.connect(func() -> void:
		Sfx.play("click")
		main.show_menu())
	top.add_child(back)
	var title := UI.label("Levels", 34)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var ghost := Control.new()
	ghost.custom_minimum_size = back.get_combined_minimum_size()
	top.add_child(ghost)

	var chip_grid := GridContainer.new()
	chip_grid.columns = 3
	chip_grid.add_theme_constant_override("h_separation", 10)
	chip_grid.add_theme_constant_override("v_separation", 10)
	box.add_child(chip_grid)
	for i in Levels.PACKS.size():
		var p: Dictionary = Levels.PACKS[i]
		var chip := UI.button("%s %d x %d" % [p["name"], p["size"], p["size"]], 17)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var idx := i
		chip.pressed.connect(func() -> void:
			Sfx.play("click")
			pack_idx = idx
			Progress.set_setting("last_pack", idx)
			_refresh())
		chip_grid.add_child(chip)
		_chips.append(chip)

	_info = UI.label("", 18, UI.TEXT_DIM)
	box.add_child(_info)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_grid)

	_refresh()


func _refresh() -> void:
	for i in _chips.size():
		var sb: StyleBoxFlat = _chips[i].get_theme_stylebox("normal").duplicate()
		sb.bg_color = UI.ACCENT if i == pack_idx else UI.PANEL_LIGHT
		if not Progress.pack_unlocked(i):
			sb.bg_color = Color(UI.PANEL_LIGHT, 0.5)
		_chips[i].add_theme_stylebox_override("normal", sb)

	for child in _grid.get_children():
		child.queue_free()

	var pack: Dictionary = Levels.PACKS[pack_idx]
	if not Progress.pack_unlocked(pack_idx):
		var prev: Dictionary = Levels.PACKS[pack_idx - 1]
		_info.text = "Locked - complete 5 %s levels to unlock (%d/5)" % [
			prev["name"], Progress.completed_count(pack_idx - 1)]
		return
	_info.text = "%s  -  %d x %d  -  %d/%d solved" % [
		pack["name"], pack["size"], pack["size"],
		Progress.completed_count(pack_idx), int(pack["count"])]

	for i in int(pack["count"]):
		_grid.add_child(_level_button(i))


func _level_button(i: int) -> Button:
	var id := Levels.level_id(pack_idx, i)
	var s: int = Progress.stars(id)
	var unlocked := i == 0 or Progress.is_completed(Levels.level_id(pack_idx, i - 1))

	var b := UI.button("", 20)
	b.custom_minimum_size = Vector2(0, 104)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var inner := VBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(inner)

	inner.add_child(UI.label(str(i + 1), 30, UI.TEXT if unlocked else UI.TEXT_DIM))
	var stars_row := StarRow.new()
	stars_row.star_size = 13.0
	stars_row.count = s
	stars_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inner.add_child(stars_row)

	if s > 0:
		var sb: StyleBoxFlat = b.get_theme_stylebox("normal").duplicate()
		sb.bg_color = Color(UI.ACCENT, 0.35)
		b.add_theme_stylebox_override("normal", sb)
	if not unlocked:
		b.disabled = true
		b.modulate.a = 0.45

	var idx := i
	b.pressed.connect(func() -> void:
		Sfx.play("click")
		main.show_game(pack_idx, idx))
	return b
