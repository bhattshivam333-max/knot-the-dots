class_name MenuScreen
extends Control
## Title screen: logo, Play / Levels / Daily, and settings toggles.

var main: Node


func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	box.custom_minimum_size = Vector2(420, 0)
	center.add_child(box)

	var title := UI.label("KNOT THE DOTS", 58, UI.TEXT)
	box.add_child(title)

	var decor := KnotDecor.new()
	decor.custom_minimum_size = Vector2(360, 74)
	decor.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(decor)

	box.add_child(UI.label("Line & Color Puzzle", 26, UI.TEXT_DIM))
	box.add_child(UI.spacer(26))

	var play := UI.button("Play", 30, true)
	play.pressed.connect(func() -> void:
		Sfx.play("click")
		var nxt: Dictionary = Progress.next_unfinished()
		if nxt.is_empty():
			main.show_select()
		else:
			main.show_game(nxt["pack"], nxt["level"]))
	box.add_child(play)

	var levels_btn := UI.button("Levels", 30)
	levels_btn.pressed.connect(func() -> void:
		Sfx.play("click")
		main.show_select())
	box.add_child(levels_btn)

	var today := Time.get_datetime_dict_from_system()
	var daily_done: bool = Progress.is_completed(Levels.daily_id(today))
	var daily := UI.button("Daily Puzzle" + ("  - done!" if daily_done else ""), 30)
	daily.pressed.connect(func() -> void:
		Sfx.play("click")
		main.show_daily())
	box.add_child(daily)

	box.add_child(UI.spacer(18))

	var toggles := HBoxContainer.new()
	toggles.alignment = BoxContainer.ALIGNMENT_CENTER
	toggles.add_theme_constant_override("separation", 14)
	box.add_child(toggles)

	var sound := UI.button(_sound_text(), 20)
	sound.pressed.connect(func() -> void:
		Progress.set_setting("sound", not Progress.get_setting("sound", true))
		sound.text = _sound_text()
		Sfx.play("click"))
	toggles.add_child(sound)

	var letters := UI.button(_letters_text(), 20)
	letters.pressed.connect(func() -> void:
		Progress.set_setting("letters", not Progress.get_setting("letters", false))
		letters.text = _letters_text()
		Sfx.play("click"))
	toggles.add_child(letters)

	box.add_child(UI.spacer(10))
	var total := 0
	for p in Levels.PACKS:
		total += int(p["count"])
	box.add_child(UI.label("%d levels + daily puzzles" % total, 17, UI.TEXT_DIM))


func _sound_text() -> String:
	return "Sound: On" if Progress.get_setting("sound", true) else "Sound: Off"


func _letters_text() -> String:
	return "Letters: On" if Progress.get_setting("letters", false) else "Letters: Off"


## Decorative wavy line threading through colored dots under the title.
class KnotDecor:
	extends Control

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var n := 5
		var margin := 26.0
		var span := size.x - margin * 2.0
		var cy := size.y / 2.0
		var pts := PackedVector2Array()
		var samples := 60
		for i in samples + 1:
			var t := float(i) / samples
			pts.append(Vector2(margin + t * span, cy + sin(t * PI * 2.0) * size.y * 0.28))
		draw_polyline(pts, Color(1, 1, 1, 0.25), 5.0, true)
		for i in n:
			var t := float(i) / (n - 1)
			var p := Vector2(margin + t * span, cy + sin(t * PI * 2.0) * size.y * 0.28)
			draw_circle(p, 12.0, Levels.PALETTE[i], true, -1.0, true)
