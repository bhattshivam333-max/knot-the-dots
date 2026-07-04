class_name MenuScreen
extends Control
## Title screen per the KNOTS design: coins + gear on top, gold KNOTS logo,
## level chip, big PLAY button, and a settings overlay.

var main: Node

var _coin_chip: UI.CoinChip
var _overlay: Control


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 56)
	add_child(margin)

	var box := VBoxContainer.new()
	margin.add_child(box)

	# Top row: coins | gear.
	var top := HBoxContainer.new()
	box.add_child(top)
	_coin_chip = UI.CoinChip.new(Progress.coins())
	top.add_child(_coin_chip)
	var stretch := Control.new()
	stretch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(stretch)
	var gear := UI.icon_button()
	gear.add_child(UI.center_icon(UI.GearIcon.new()))
	gear.pressed.connect(func() -> void:
		Sfx.play("click")
		_show_settings())
	top.add_child(gear)

	# Logo block, vertically centered.
	var logo_zone := CenterContainer.new()
	logo_zone.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(logo_zone)
	var logo := VBoxContainer.new()
	logo.alignment = BoxContainer.ALIGNMENT_CENTER
	logo.add_theme_constant_override("separation", 10)
	logo_zone.add_child(logo)

	var title := UI.label("KNOTS", 84, UI.GOLD, UI.fredoka(700, 2))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	title.add_theme_constant_override("shadow_offset_y", 6)
	title.add_theme_constant_override("shadow_offset_x", 0)
	logo.add_child(title)
	logo.add_child(UI.label("CONNECT THE DOTS", 17, UI.TEXT_DIM, UI.nunito(800, 4)))

	# Bottom block: level chip + PLAY + secondary buttons.
	var bottom := VBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 22)
	box.add_child(bottom)

	var next: Dictionary = Progress.next_unfinished()
	var level_num: int = Progress.total_completed() + 1
	var chip := UI.chip()
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var chip_box: HBoxContainer = chip.get_child(0)
	chip_box.add_child(UI.label("LEVEL %d" % level_num, 15, UI.LEVEL_CHIP_TEXT, UI.fredoka(600, 2)))
	var chip_sb: StyleBoxFlat = chip.get_theme_stylebox("panel").duplicate()
	chip_sb.bg_color = Color("#7c5cff", 0.18)
	chip_sb.border_color = Color("#7c5cff", 0.35)
	chip_sb.content_margin_left = 20.0
	chip.add_theme_stylebox_override("panel", chip_sb)
	bottom.add_child(chip)

	var play := UI.chunky_button("PLAY", 32, "gold")
	play.custom_minimum_size = Vector2(240, 80)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(func() -> void:
		Sfx.play("click")
		if next.is_empty():
			main.show_select()
		else:
			main.show_game(next["pack"], next["level"]))
	bottom.add_child(play)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	bottom.add_child(row)

	var levels_btn := UI.chunky_button("LEVELS", 16, "purple")
	levels_btn.pressed.connect(func() -> void:
		Sfx.play("click")
		main.show_select())
	row.add_child(levels_btn)

	var today := Time.get_datetime_dict_from_system()
	var daily_done: bool = Progress.is_completed(Levels.daily_id(today))
	var daily := UI.chunky_button("DAILY" + (" *" if daily_done else ""), 16, "purple")
	daily.pressed.connect(func() -> void:
		Sfx.play("click")
		main.show_daily())
	row.add_child(daily)


func _show_settings() -> void:
	if is_instance_valid(_overlay):
		return
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	var dim := ColorRect.new()
	dim.color = Color("#06040e", 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)

	var panel := UI.overlay_panel()
	panel.custom_minimum_size = Vector2(320, 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	box.add_child(UI.heading("SETTINGS", 26, UI.TEXT, 1))

	var toggles := HBoxContainer.new()
	toggles.add_theme_constant_override("separation", 10)
	box.add_child(toggles)
	toggles.add_child(_toggle_button("SOUND", "sound", true))
	toggles.add_child(_toggle_button("MUSIC", "music", true))
	var letters_row := HBoxContainer.new()
	letters_row.add_theme_constant_override("separation", 10)
	box.add_child(letters_row)
	letters_row.add_child(_toggle_button("DOT LETTERS", "letters", false))

	var close := UI.chunky_button("CLOSE", 17, "gold")
	close.custom_minimum_size = Vector2(264, 0)
	close.pressed.connect(func() -> void:
		Sfx.play("click")
		_overlay.queue_free())
	box.add_child(close)

	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.8, 0.8)
	create_tween().tween_property(panel, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _toggle_button(name_txt: String, key: String, def: bool) -> Button:
	var on: bool = Progress.get_setting(key, def)
	var b := UI.chunky_button(_toggle_text(name_txt, on), 13, "green" if on else "dark")
	b.custom_minimum_size = Vector2(127, 0)
	b.pressed.connect(func() -> void:
		var now: bool = not Progress.get_setting(key, def)
		Progress.set_setting(key, now)
		if key == "music":
			Sfx.set_music(now)
		Sfx.play("click")
		# Rebuild the style in place.
		var fresh := UI.chunky_button(_toggle_text(name_txt, now), 13, "green" if now else "dark")
		for st in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(st, fresh.get_theme_stylebox(st))
		for cst in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(cst, fresh.get_theme_color(cst))
		b.text = _toggle_text(name_txt, now))
	return b


func _toggle_text(name_txt: String, on: bool) -> String:
	return "%s %s" % [name_txt, "ON" if on else "OFF"]
