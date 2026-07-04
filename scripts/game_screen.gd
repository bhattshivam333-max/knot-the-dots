class_name GameScreen
extends Control
## Gameplay screen per the KNOTS design: pause + level/timer + coins header,
## the board, UNDO/HINT buttons, and pause / win / lose overlays.

const HINT_COST := 15

var main: Node
var pack_idx := 0
var level_idx := 0
var is_daily := false

var board: Board
var time_limit := 45.0
var time_left := 45.0
var ended := false

var _coin_chip: UI.CoinChip
var _timer_label: Label
var _timer_chip: PanelContainer
var _timer_red := false
var _hint_btn: Button
var _overlay: Control


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 26)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	# Header: pause | level + timer | coins.
	var top := HBoxContainer.new()
	box.add_child(top)

	var pause_btn := UI.icon_button()
	pause_btn.add_child(UI.center_icon(UI.PauseIcon.new(), 10.0))
	pause_btn.pressed.connect(_on_pause)
	top.add_child(pause_btn)

	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", 6)
	top.add_child(mid)
	mid.add_child(UI.heading(_title_text(), 16, UI.TEXT_SOFT, 2))
	_timer_chip = UI.chip()
	_timer_chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var tbox: HBoxContainer = _timer_chip.get_child(0)
	_timer_label = UI.label("0:00", 14, Color("#cfc4ea"), UI.fredoka(600))
	tbox.add_child(_timer_label)
	mid.add_child(_timer_chip)

	_coin_chip = UI.CoinChip.new(Progress.coins(), true)
	top.add_child(_coin_chip)

	board = Board.new()
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.show_letters = bool(Progress.get_setting("letters", false))
	board.state_changed.connect(_update_hint_state)
	board.level_won.connect(_on_won)
	box.add_child(board)

	# Bottom: UNDO | HINT.
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 16)
	box.add_child(bottom)

	var undo := UI.chunky_button("UNDO", 17, "purple")
	undo.custom_minimum_size = Vector2(150, 60)
	undo.pressed.connect(func() -> void:
		if board.can_undo():
			Sfx.play("cut")
			board.undo())
	bottom.add_child(undo)

	_hint_btn = UI.chunky_button("HINT  %d" % HINT_COST, 17, "gold")
	_hint_btn.custom_minimum_size = Vector2(150, 60)
	_hint_btn.pressed.connect(_on_hint)
	bottom.add_child(_hint_btn)

	var level := _load_level()
	board.setup(level)
	time_limit = float(Levels.time_limit(level["n"], not level["bridges"].is_empty()))
	time_left = time_limit
	_update_timer_label()
	_update_hint_state()


func _process(delta: float) -> void:
	if ended or board.locked or board.frozen:
		return
	time_left = maxf(0.0, time_left - delta)
	_update_timer_label()
	if time_left <= 0.0:
		_on_time_up()


func _update_timer_label() -> void:
	var t := int(ceilf(time_left))
	_timer_label.text = "%d:%02d" % [t / 60, t % 60]
	var low := time_left <= 10.0
	if low != _timer_red:
		_timer_red = low
		var sb: StyleBoxFlat = _timer_chip.get_theme_stylebox("panel").duplicate()
		sb.bg_color = Color(UI.RED, 0.15) if low else UI.CHIP_BG
		sb.border_color = Color(UI.RED, 0.35) if low else UI.CHIP_BORDER
		_timer_chip.add_theme_stylebox_override("panel", sb)
		_timer_label.add_theme_color_override("font_color",
				Color("#ff8095") if low else Color("#cfc4ea"))


func _update_hint_state() -> void:
	if _hint_btn == null:
		return
	var can := Progress.coins() >= HINT_COST and not board.locked and board.done_count() < board.solution.size()
	_hint_btn.disabled = not can
	_hint_btn.modulate.a = 1.0 if can else 0.7


func _on_hint() -> void:
	if board.locked or board.frozen:
		return
	if not Progress.spend_coins(HINT_COST):
		return
	Sfx.play("click")
	_coin_chip.set_amount(Progress.coins())
	board.apply_hint()
	_update_hint_state()


func _load_level() -> Dictionary:
	if is_daily:
		return Levels.daily_level(Time.get_datetime_dict_from_system())
	return Levels.get_level(pack_idx, level_idx)


func _title_text() -> String:
	if is_daily:
		var d := Time.get_datetime_dict_from_system()
		return "DAILY %d/%d" % [d["day"], d["month"]]
	return "LEVEL %d" % (level_idx + 1)


func _level_id() -> String:
	if is_daily:
		return Levels.daily_id(Time.get_datetime_dict_from_system())
	return Levels.level_id(pack_idx, level_idx)


func _stars_for_time() -> int:
	var frac := time_left / time_limit
	if frac >= 0.55:
		return 3
	if frac >= 0.22:
		return 2
	return 1


# ------------------------------------------------------------------ pause

func _on_pause() -> void:
	if ended or board.locked or is_instance_valid(_overlay):
		return
	Sfx.play("click")
	board.frozen = true
	var box := _make_overlay_panel(300)
	box.add_child(UI.heading("PAUSED", 26, UI.TEXT, 1))

	var resume := UI.chunky_button("RESUME", 19, "gold")
	resume.custom_minimum_size = Vector2(244, 60)
	resume.pressed.connect(func() -> void:
		Sfx.play("click")
		board.frozen = false
		_overlay.queue_free())
	box.add_child(resume)

	var restart := UI.chunky_button("RESTART LEVEL", 15, "purple2")
	restart.custom_minimum_size = Vector2(244, 54)
	restart.pressed.connect(func() -> void:
		Sfx.play("click")
		_restart())
	box.add_child(restart)

	var toggles := HBoxContainer.new()
	toggles.add_theme_constant_override("separation", 10)
	box.add_child(toggles)
	toggles.add_child(_toggle_button("SOUND", "sound"))
	toggles.add_child(_toggle_button("MUSIC", "music"))

	box.add_child(_home_button())


func _restart() -> void:
	if is_daily:
		main.show_daily()
	else:
		main.show_game(pack_idx, level_idx)


# ------------------------------------------------------------------ win / lose

func _on_won() -> void:
	ended = true
	var stars := _stars_for_time()
	var coins_earned := 20 + stars * 10
	Progress.add_coins(coins_earned)
	Progress.record(_level_id(), stars)
	_coin_chip.set_amount(Progress.coins())
	await get_tree().create_timer(0.55).timeout
	if not is_inside_tree():
		return
	_show_win(stars, coins_earned)


func _show_win(stars: int, coins_earned: int) -> void:
	var box := _make_overlay_panel(310)

	var confetti := ConfettiFx.new()
	confetti.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(confetti)
	_overlay.move_child(confetti, 1) # above dim, below panel

	box.add_child(UI.heading("LEVEL COMPLETE!", 24, UI.GOLD_LIGHT, 1))

	var stars_row := StarRow.new()
	stars_row.star_size = 42.0
	stars_row.count = 0
	stars_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(stars_row)

	var coin_chip := UI.chip()
	coin_chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var csb: StyleBoxFlat = coin_chip.get_theme_stylebox("panel").duplicate()
	csb.bg_color = Color(UI.GOLD, 0.12)
	csb.border_color = Color(UI.GOLD, 0.3)
	coin_chip.add_theme_stylebox_override("panel", csb)
	var cbox: HBoxContainer = coin_chip.get_child(0)
	cbox.add_child(UI.CoinDot.new(11.0))
	cbox.add_child(UI.label("+%d" % coins_earned, 18, UI.GOLD_PALE, UI.fredoka(700)))
	box.add_child(coin_chip)

	var next_btn: Button
	if not is_daily and level_idx + 1 < int(Levels.PACKS[pack_idx]["count"]):
		next_btn = UI.chunky_button("NEXT LEVEL", 19, "gold")
		next_btn.pressed.connect(func() -> void:
			Sfx.play("click")
			main.show_game(pack_idx, level_idx + 1))
	else:
		next_btn = UI.chunky_button("LEVELS", 19, "gold")
		next_btn.pressed.connect(func() -> void:
			Sfx.play("click")
			if is_daily:
				main.show_menu()
			else:
				main.show_select())
	next_btn.custom_minimum_size = Vector2(254, 60)
	box.add_child(next_btn)

	box.add_child(_home_button())

	# Reveal stars one by one.
	var tw := create_tween()
	for i in stars:
		tw.tween_interval(0.28)
		var n := i + 1
		tw.tween_callback(func() -> void:
			stars_row.count = n
			Sfx.play("pop"))


func _on_time_up() -> void:
	if ended:
		return
	ended = true
	board.frozen = true
	Sfx.play("lose")
	var box := _make_overlay_panel(300)
	box.add_child(UI.heading("TIME'S UP!", 26, Color("#ff8095"), 1))
	box.add_child(UI.label("So close - give it another shot.", 15, Color("#c9bde0")))

	var retry := UI.chunky_button("TRY AGAIN", 19, "red")
	retry.custom_minimum_size = Vector2(244, 60)
	retry.pressed.connect(func() -> void:
		Sfx.play("click")
		_restart())
	box.add_child(retry)

	box.add_child(_home_button())


# ------------------------------------------------------------------ helpers

func _make_overlay_panel(width: float) -> VBoxContainer:
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
	panel.custom_minimum_size = Vector2(width, 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.8, 0.8)
	create_tween().tween_property(panel, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return box


func _home_button() -> Button:
	var b := UI.chunky_button("HOME", 14, "ghost")
	b.pressed.connect(func() -> void:
		Sfx.play("click")
		main.show_menu())
	return b


func _toggle_button(name_txt: String, key: String) -> Button:
	var on: bool = Progress.get_setting(key, true)
	var b := UI.chunky_button("%s %s" % [name_txt, "ON" if on else "OFF"], 13,
			"green" if on else "dark")
	b.custom_minimum_size = Vector2(117, 0)
	b.pressed.connect(func() -> void:
		var now: bool = not Progress.get_setting(key, true)
		Progress.set_setting(key, now)
		if key == "music":
			Sfx.set_music(now)
		Sfx.play("click")
		var fresh := UI.chunky_button("%s %s" % [name_txt, "ON" if now else "OFF"], 13,
				"green" if now else "dark")
		for st in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(st, fresh.get_theme_stylebox(st))
		for cst in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(cst, fresh.get_theme_color(cst))
		b.text = "%s %s" % [name_txt, "ON" if now else "OFF"])
	return b


## Falling confetti rectangles, per the design's win animation.
class ConfettiFx:
	extends Control

	var _bits: Array = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var palette := [Color("#ff5c72"), Color("#37e08c"), Color("#ffcc33"),
				Color("#b775f5"), Color("#5ec8ff")]
		for i in 30:
			_bits.append({
				"x": rng.randf(),
				"y": -rng.randf() * 400.0 - 20.0,
				"speed": rng.randf_range(220.0, 420.0),
				"rot": rng.randf() * TAU,
				"spin": rng.randf_range(-4.0, 4.0),
				"w": 7.0 + 4.0 * (i % 2),
				"h": 14.0 + 3.0 * (i % 3),
				"col": palette[i % palette.size()],
			})

	func _process(delta: float) -> void:
		for b in _bits:
			b["y"] += b["speed"] * delta
			b["rot"] += b["spin"] * delta
			if b["y"] > size.y + 30.0:
				b["y"] = -30.0
		queue_redraw()

	func _draw() -> void:
		for b in _bits:
			draw_set_transform(Vector2(b["x"] * size.x, b["y"]), b["rot"], Vector2.ONE)
			draw_rect(Rect2(-b["w"] / 2.0, -b["h"] / 2.0, b["w"], b["h"]), b["col"])
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
