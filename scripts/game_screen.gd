class_name GameScreen
extends Control
## Gameplay screen: HUD around the Board plus the win overlay.

var main: Node
var pack_idx := 0
var level_idx := 0
var is_daily := false

var board: Board
var _info: Label
var _win_layer: Control


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	box.add_child(top)

	var back := UI.button("Back", 20)
	back.pressed.connect(func() -> void:
		Sfx.play("click")
		if is_daily:
			main.show_menu()
		else:
			main.show_select())
	top.add_child(back)

	var title := UI.label(_title_text(), 26)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)

	var reset := UI.button("Reset", 20)
	reset.pressed.connect(func() -> void:
		Sfx.play("click")
		board.restart())
	top.add_child(reset)

	_info = UI.label("", 20, UI.TEXT_DIM)
	box.add_child(_info)

	board = Board.new()
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.show_letters = bool(Progress.get_setting("letters", false))
	board.state_changed.connect(_update_info)
	board.level_won.connect(_on_won)
	box.add_child(board)

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(bottom)
	var hint := UI.button("Hint", 24)
	hint.pressed.connect(func() -> void:
		Sfx.play("click")
		board.apply_hint())
	bottom.add_child(hint)

	board.setup(_load_level())


func _load_level() -> Dictionary:
	if is_daily:
		return Levels.daily_level(Time.get_datetime_dict_from_system())
	return Levels.get_level(pack_idx, level_idx)


func _title_text() -> String:
	if is_daily:
		var d := Time.get_datetime_dict_from_system()
		return "Daily  %d/%d" % [d["day"], d["month"]]
	var p: Dictionary = Levels.PACKS[pack_idx]
	return "%s - Level %d" % [p["name"], level_idx + 1]


func _level_id() -> String:
	if is_daily:
		return Levels.daily_id(Time.get_datetime_dict_from_system())
	return Levels.level_id(pack_idx, level_idx)


func _update_info() -> void:
	_info.text = "Flows %d/%d      Pipe %d%%      Moves %d" % [
		board.done_count(), board.solution.size(),
		int(round(board.coverage() * 100.0)), board.moves]


func _on_won() -> void:
	var stars := board.stars_earned()
	Progress.record(_level_id(), stars)
	await get_tree().create_timer(0.55).timeout
	_show_win(stars)


func _show_win(stars: int) -> void:
	if is_instance_valid(_win_layer):
		return
	_win_layer = Control.new()
	_win_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_win_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_win_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_win_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.panel_style())
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	var heading := "Perfect!" if stars == 3 else "Level Complete!"
	box.add_child(UI.label(heading, 40))

	var stars_row := StarRow.new()
	stars_row.star_size = 44.0
	stars_row.count = 0
	stars_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(stars_row)

	box.add_child(UI.label("Solved in %d moves (%d flows)" % [
		board.moves, board.solution.size()], 20, UI.TEXT_DIM))

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)

	var levels_btn := UI.button("Levels", 22)
	levels_btn.pressed.connect(func() -> void:
		Sfx.play("click")
		if is_daily:
			main.show_menu()
		else:
			main.show_select())
	buttons.add_child(levels_btn)

	var replay := UI.button("Replay", 22)
	replay.pressed.connect(func() -> void:
		Sfx.play("click")
		if is_daily:
			main.show_daily()
		else:
			main.show_game(pack_idx, level_idx))
	buttons.add_child(replay)

	if not is_daily and level_idx + 1 < int(Levels.PACKS[pack_idx]["count"]):
		var next := UI.button("Next", 22, true)
		next.pressed.connect(func() -> void:
			Sfx.play("click")
			main.show_game(pack_idx, level_idx + 1))
		buttons.add_child(next)
	elif is_daily:
		var menu := UI.button("Menu", 22, true)
		menu.pressed.connect(func() -> void:
			Sfx.play("click")
			main.show_menu())
		buttons.add_child(menu)

	panel.scale = Vector2(0.8, 0.8)
	panel.pivot_offset = panel.size / 2.0
	var tw := create_tween()
	tw.tween_property(panel, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Reveal stars one by one.
	for i in stars:
		tw.tween_interval(0.22)
		var n := i + 1
		tw.tween_callback(func() -> void:
			stars_row.count = n
			Sfx.play("pop"))
