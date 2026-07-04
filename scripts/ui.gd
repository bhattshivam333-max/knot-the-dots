class_name UI
## KNOTS design system: colors, fonts and factory helpers for code-built UI.
## Ported from the "Knots UI" Claude Design mockup.

const BG_TOP := Color("#251a3f")
const BG_MID := Color("#170f2b")
const BG_BOT := Color("#0d0a1a")

const PANEL := Color("#231a40")
const PANEL_BORDER := Color(1, 1, 1, 0.08)
const BOARD_BG := Color(0, 0, 0, 0.25)

const TEXT := Color("#f1ecff")
const TEXT_SOFT := Color("#e9e2ff")
const TEXT_DIM := Color("#a9a0c8")
const TEXT_FAINT := Color("#9d92c7")

const GOLD := Color("#ffc233")
const GOLD_LIGHT := Color("#ffe066")
const GOLD_DARK := Color("#b06f00")
const GOLD_TEXT := Color("#3a2000")
const GOLD_PALE := Color("#ffe9b0")

const PURPLE_BTN := Color("#322852")
const PURPLE_BTN_DARK := Color("#170f2b")
const PURPLE_MED := Color("#4c3b85")
const PURPLE_MED_DARK := Color("#241a44")
const LEVEL_CHIP_TEXT := Color("#b9adf0")

const GREEN := Color("#37e08c")
const GREEN_LIGHT := Color("#6ef0ac")
const GREEN_DARK := Color("#1f9e63")
const GREEN_TEXT := Color("#0c3a24")

const RED := Color("#ff5c72")
const RED_DARK := Color("#a02638")

const LOCKED_BG := Color("#3b3157")
const LOCKED_DARK := Color("#221c33")

const CHIP_BG := Color(1, 1, 1, 0.06)
const CHIP_BORDER := Color(1, 1, 1, 0.09)

static var _fredoka_file: FontFile
static var _nunito_file: FontFile
static var _font_cache := {}


static func fredoka(weight := 600, spacing := 0) -> Font:
	return _font("fredoka", weight, spacing)


static func nunito(weight := 700, spacing := 0) -> Font:
	return _font("nunito", weight, spacing)


static func _font(family: String, weight: int, spacing: int) -> Font:
	var key := "%s_%d_%d" % [family, weight, spacing]
	if _font_cache.has(key):
		return _font_cache[key]
	if _fredoka_file == null:
		_fredoka_file = load("res://assets/fonts/Fredoka.ttf")
		_nunito_file = load("res://assets/fonts/Nunito.ttf")
	var fv := FontVariation.new()
	fv.base_font = _fredoka_file if family == "fredoka" else _nunito_file
	fv.variation_opentype = {"wght": weight}
	if spacing != 0:
		fv.spacing_glyph = spacing
	_font_cache[key] = fv
	return fv


## Chunky arcade button with a solid 3D bottom edge that squashes on press.
## kind: "gold" | "purple" | "green" | "red" | "dark" | "ghost"
static func chunky_button(text: String, font_size := 18, kind := "gold") -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", fredoka(650, 1))
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	if kind == "ghost":
		for st in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		b.add_theme_font_override("font", nunito(800, 1))
		for st in ["font_color", "font_hover_color", "font_focus_color"]:
			b.add_theme_color_override(st, TEXT_FAINT)
		b.add_theme_color_override("font_pressed_color", TEXT)
		return b

	var bg: Color
	var edge: Color
	var fg: Color
	match kind:
		"purple":
			bg = PURPLE_BTN; edge = PURPLE_BTN_DARK; fg = TEXT_SOFT
		"purple2":
			bg = PURPLE_MED; edge = PURPLE_MED_DARK; fg = TEXT_SOFT
		"green":
			bg = GREEN; edge = GREEN_DARK; fg = GREEN_TEXT
		"red":
			bg = RED; edge = RED_DARK; fg = Color.WHITE
		"dark":
			bg = Color("#332c4c"); edge = Color("#1a1628"); fg = Color(1, 1, 1, 0.45)
		_:
			bg = GOLD; edge = GOLD_DARK; fg = GOLD_TEXT

	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(20)
	sb.border_width_bottom = 6
	sb.border_color = edge
	sb.content_margin_left = 24.0
	sb.content_margin_right = 24.0
	sb.content_margin_top = 12.0
	sb.content_margin_bottom = 16.0
	b.add_theme_stylebox_override("normal", sb)

	var sbh: StyleBoxFlat = sb.duplicate()
	sbh.bg_color = bg.lightened(0.07)
	b.add_theme_stylebox_override("hover", sbh)

	var sbp: StyleBoxFlat = sb.duplicate()
	sbp.bg_color = bg.darkened(0.06)
	sbp.border_width_bottom = 1
	sbp.content_margin_top = 17.0
	sbp.content_margin_bottom = 11.0
	b.add_theme_stylebox_override("pressed", sbp)

	var sbd: StyleBoxFlat = sb.duplicate()
	sbd.bg_color = Color("#332c4c")
	sbd.border_color = Color("#1a1628")
	b.add_theme_stylebox_override("disabled", sbd)

	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(st, fg)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.4))
	return b


## Small square glassy icon button (back, pause, gear...).
static func icon_button(glyph: String = "") -> Button:
	var b := Button.new()
	b.text = glyph
	b.custom_minimum_size = Vector2(52, 52)
	b.add_theme_font_override("font", fredoka(600))
	b.add_theme_font_size_override("font_size", 26)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.07)
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(1)
	sb.border_color = CHIP_BORDER
	b.add_theme_stylebox_override("normal", sb)
	var sbh: StyleBoxFlat = sb.duplicate()
	sbh.bg_color = Color(1, 1, 1, 0.12)
	b.add_theme_stylebox_override("hover", sbh)
	var sbp: StyleBoxFlat = sb.duplicate()
	sbp.bg_color = Color(1, 1, 1, 0.04)
	b.add_theme_stylebox_override("pressed", sbp)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(st, Color("#cfc4ea"))
	return b


## Anchor a fixed-size icon control to the exact center of its parent.
static func center_icon(icon: Control, half := 12.0) -> Control:
	icon.anchor_left = 0.5
	icon.anchor_top = 0.5
	icon.anchor_right = 0.5
	icon.anchor_bottom = 0.5
	icon.offset_left = -half
	icon.offset_top = -half
	icon.offset_right = half
	icon.offset_bottom = half
	return icon


static func label(text: String, font_size := 20, color := TEXT, font: Font = null,
		align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if font else nunito(700))
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	return l


static func heading(text: String, font_size := 26, color := TEXT_SOFT, spacing := 2) -> Label:
	return label(text, font_size, color, fredoka(650, spacing))


## Glassy pill chip; returns the PanelContainer with an HBox child to fill.
static func chip() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = CHIP_BG
	sb.set_corner_radius_all(20)
	sb.set_border_width_all(1)
	sb.border_color = CHIP_BORDER
	sb.content_margin_left = 10.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	p.add_theme_stylebox_override("panel", sb)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	p.add_child(box)
	return p


static func overlay_panel() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL
	sb.set_corner_radius_all(28)
	sb.set_border_width_all(1)
	sb.border_color = PANEL_BORDER
	sb.content_margin_left = 28.0
	sb.content_margin_right = 28.0
	sb.content_margin_top = 30.0
	sb.content_margin_bottom = 26.0
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 30
	sb.shadow_offset = Vector2(0, 14)
	p.add_theme_stylebox_override("panel", sb)
	return p


static func spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


## Gold coin disc, drawn glossy.
class CoinDot:
	extends Control

	var radius := 12.0

	func _init(r := 12.0) -> void:
		radius = r
		custom_minimum_size = Vector2(r * 2.0 + 2.0, r * 2.0 + 2.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c, radius, Color("#ffb000"), true, -1.0, true)
		draw_circle(c + Vector2(-radius * 0.25, -radius * 0.3), radius * 0.55,
				Color("#ffe066"), true, -1.0, true)
		draw_arc(c, radius - 1.5, 0.0, TAU, 40, Color("#7a4b00", 0.8), 2.5, true)


## Coins pill: gold disc + amount, updatable via set_amount().
class CoinChip:
	extends PanelContainer

	var _label: Label

	func _init(amount := 0, small := false) -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = UI.CHIP_BG
		sb.set_corner_radius_all(20)
		sb.set_border_width_all(1)
		sb.border_color = UI.CHIP_BORDER
		sb.content_margin_left = 8.0
		sb.content_margin_right = 16.0
		sb.content_margin_top = 7.0
		sb.content_margin_bottom = 7.0
		add_theme_stylebox_override("panel", sb)
		var box := HBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		add_child(box)
		box.add_child(CoinDot.new(10.0 if small else 13.0))
		_label = UI.label(str(amount), 15 if small else 17, UI.GOLD_PALE, UI.fredoka(600))
		box.add_child(_label)

	func set_amount(v: int) -> void:
		_label.text = str(v)


## Padlock glyph for locked levels, drawn by hand.
class LockIcon:
	extends Control

	func _init() -> void:
		custom_minimum_size = Vector2(24, 26)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var col := Color(1, 1, 1, 0.55)
		var cx := size.x / 2.0
		draw_arc(Vector2(cx, 10), 6.5, PI, TAU, 20, col, 3.0, true)
		var sb := StyleBoxFlat.new()
		sb.bg_color = col
		sb.set_corner_radius_all(5)
		draw_style_box(sb, Rect2(cx - 10, 10, 20, 15))


## Gear glyph for the settings button, drawn by hand.
class GearIcon:
	extends Control

	func _init() -> void:
		custom_minimum_size = Vector2(24, 24)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var col := Color("#cfc4ea")
		var c := size / 2.0
		for i in 8:
			var ang := i * TAU / 8.0
			draw_line(c + Vector2(cos(ang), sin(ang)) * 6.0,
					c + Vector2(cos(ang), sin(ang)) * 11.0, col, 3.5, true)
		draw_circle(c, 7.0, col, true, -1.0, true)
		draw_circle(c, 3.2, Color("#251a3f"), true, -1.0, true)


## Pause bars glyph.
class PauseIcon:
	extends Control

	func _init() -> void:
		custom_minimum_size = Vector2(20, 20)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var col := Color("#cfc4ea")
		var sb := StyleBoxFlat.new()
		sb.bg_color = col
		sb.set_corner_radius_all(2)
		var h := size.y
		draw_style_box(sb, Rect2(size.x / 2.0 - 7, (h - 16) / 2.0, 5, 16))
		draw_style_box(sb, Rect2(size.x / 2.0 + 2, (h - 16) / 2.0, 5, 16))
