class_name MenuScreen
extends Control
## Title screen, 1:1 with the mockup: coins + gear header, gradient KNOTS
## logo with drop shadow, LEVEL chip, gold PLAY button, settings overlay.

var main: Node

var _coin_chip: UI.CoinChip
var _overlay: Control


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	margin.add_theme_constant_override("margin_top", 56)
	margin.add_theme_constant_override("margin_bottom", 44)
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
	gear.add_child(UI.center_icon(UI.GearIcon.new(), 11.0))
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
	logo.add_theme_constant_override("separation", 6)
	logo_zone.add_child(logo)
	logo.add_child(_gradient_title("KNOTS", 64))
	logo.add_child(UI.label("CONNECT THE DOTS", 15, UI.TEXT_DIM, UI.nunito(700, 3)))

	# Bottom block: level chip + PLAY + secondary buttons.
	var bottom := VBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 22)
	box.add_child(bottom)

	var level_num: int = Progress.total_completed() + 1
	var chip := UI.chip(20, Vector4(20, 8, 20, 8))
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var chip_box: HBoxContainer = chip.get_child(0)
	chip_box.add_child(UI.label("LEVEL %d" % level_num, 14, UI.LEVEL_CHIP_TEXT, UI.fredoka(600, 2)))
	var chip_sb: StyleBoxFlat = chip.get_theme_stylebox("panel").duplicate()
	chip_sb.bg_color = Color("#7c5cff", 0.18)
	chip_sb.border_color = Color("#7c5cff", 0.35)
	chip.add_theme_stylebox_override("panel", chip_sb)
	bottom.add_child(chip)

	var next: Dictionary = Progress.next_unfinished()
	var play := UI.chunky_button("PLAY", 30, "gold", 1)
	play.custom_minimum_size = Vector2(230, 76)
	(play as UI.ChunkyButton).radius = 26.0
	(play as UI.ChunkyButton).edge = 7.0
	(play as UI.ChunkyButton).glow = Color("#ff9600", 0.25)
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

	var levels_btn := UI.chunky_button("LEVELS", 14, "purple")
	levels_btn.custom_minimum_size = Vector2(0, 44)
	levels_btn.pressed.connect(func() -> void:
		Sfx.play("click")
		main.show_select())
	row.add_child(levels_btn)

	var today := Time.get_datetime_dict_from_system()
	var daily_done: bool = Progress.is_completed(Levels.daily_id(today))
	var daily := UI.chunky_button("DAILY" + (" *" if daily_done else ""), 14, "purple")
	daily.custom_minimum_size = Vector2(0, 44)
	daily.pressed.connect(func() -> void:
		Sfx.play("click")
		main.show_daily())
	row.add_child(daily)


## Fredoka 700 title with the mockup's gold vertical gradient
## (#ffe89a -> #ffc233 55% -> #ff9d00) and 4px black drop shadow.
func _gradient_title(text: String, font_size: int) -> Control:
	var wrapper := Control.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var font := UI.fredoka(700, 1)
	var shadow := UI.label(text, font_size, Color(0, 0, 0, 0.35), font)
	var grad := UI.label(text, font_size, Color.WHITE, font)
	wrapper.custom_minimum_size = Vector2(
		font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x,
		font.get_height(font_size) + 4.0)

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float px_height = 74.0;
varying float vy;
void vertex() { vy = VERTEX.y; }
void fragment() {
	float t = clamp(vy / px_height, 0.0, 1.0);
	vec3 top = vec3(1.0, 0.9098, 0.6039);   // #ffe89a
	vec3 mid = vec3(1.0, 0.7608, 0.2);      // #ffc233
	vec3 bot = vec3(1.0, 0.6157, 0.0);      // #ff9d00
	vec3 col = t < 0.55 ? mix(top, mid, t / 0.55) : mix(mid, bot, (t - 0.55) / 0.45);
	COLOR = vec4(col, texture(TEXTURE, UV).a * COLOR.a);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	grad.material = mat

	for l in [shadow, grad]:
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		wrapper.add_child(l)
	shadow.offset_top = 4
	shadow.offset_bottom = 4
	grad.resized.connect(func() -> void:
		mat.set_shader_parameter("px_height", grad.size.y))
	return wrapper


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
	panel.custom_minimum_size = Vector2(300, 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	box.add_child(UI.heading("SETTINGS", 24, UI.TEXT, 1))

	var toggles := HBoxContainer.new()
	toggles.add_theme_constant_override("separation", 10)
	box.add_child(toggles)
	toggles.add_child(_toggle_button("SOUND", "sound", true))
	toggles.add_child(_toggle_button("MUSIC", "music", true))
	var letters_row := HBoxContainer.new()
	letters_row.add_theme_constant_override("separation", 10)
	box.add_child(letters_row)
	letters_row.add_child(_toggle_button("DOT LETTERS", "letters", false))

	var close := UI.chunky_button("CLOSE", 16, "gold")
	close.custom_minimum_size = Vector2(244, 52)
	close.pressed.connect(func() -> void:
		Sfx.play("click")
		_overlay.queue_free())
	box.add_child(close)

	panel.scale = Vector2(0.8, 0.8)
	create_tween().tween_property(panel, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _toggle_button(name_txt: String, key: String, def: bool) -> Button:
	var on: bool = Progress.get_setting(key, def)
	var b := UI.chunky_button(_toggle_text(name_txt, on), 12, "green" if on else "dark", 1)
	b.custom_minimum_size = Vector2(117, 48)
	var cb := b as UI.ChunkyButton
	cb.radius = 16.0
	cb.edge = 4.0
	b.pressed.connect(func() -> void:
		var now: bool = not Progress.get_setting(key, def)
		Progress.set_setting(key, now)
		if key == "music":
			Sfx.set_music(now)
		Sfx.play("click")
		cb.stops = UI.GRAD_GREEN2 if now else UI.GRAD_DARK
		cb.edge_color = Color("#1f9e63") if now else Color("#1a1628")
		var fg := Color("#1b3a2a") if now else UI.ICON_COL
		for st in ["font_color", "font_hover_color", "font_pressed_color"]:
			cb.add_theme_color_override(st, fg)
		cb.text = _toggle_text(name_txt, now)
		cb.queue_redraw())
	return b


func _toggle_text(name_txt: String, on: bool) -> String:
	return "%s %s" % [name_txt, "ON" if on else "OFF"]
