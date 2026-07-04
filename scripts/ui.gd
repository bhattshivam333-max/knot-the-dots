class_name UI
## KNOTS design system, matched 1:1 to the "Knots UI" Claude Design mockup.
## The viewport is 390x844 (the mockup's phone frame), so every dimension,
## font size and gradient stop below is the mockup's exact CSS value.

const BG_TOP := Color("#251a3f")
const BG_MID := Color("#170f2b")
const BG_BOT := Color("#0d0a1a")

const PANEL_BORDER := Color(1, 1, 1, 0.08)
const BOARD_BG := Color(0, 0, 0, 0.25)

const TEXT := Color("#f1ecff")
const TEXT_SOFT := Color("#e9e2ff")
const TEXT_DIM := Color("#a9a0c8")
const TEXT_FAINT := Color("#9d92c7")
const ICON_COL := Color("#cfc4ea")

const GOLD := Color("#ffc233")
const GOLD_LIGHT := Color("#ffe066")
const GOLD_DARK := Color("#b06f00")
const GOLD_TEXT := Color("#3a2000")
const GOLD_PALE := Color("#ffe9b0")
const GREEN := Color("#37e08c")
const RED := Color("#ff5c72")
const LEVEL_CHIP_TEXT := Color("#b9adf0")

const CHIP_BG := Color(1, 1, 1, 0.06)
const CHIP_BORDER := Color(1, 1, 1, 0.08)

# Gradient stops straight from the mockup's CSS linear-gradients.
const GRAD_GOLD := [[0.0, Color("#ffe066")], [0.55, Color("#ffc233")], [1.0, Color("#ffa500")]]
const GRAD_PURPLE := [[0.0, Color("#3a2f5c")], [1.0, Color("#291f47")]]
const GRAD_PURPLE2 := [[0.0, Color("#5b4a99")], [1.0, Color("#40316f")]]
const GRAD_GREEN := [[0.0, Color("#6ef0ac")], [0.55, Color("#37e08c")], [1.0, Color("#1f9e63")]]
const GRAD_GREEN2 := [[0.0, Color("#6ef0ac")], [1.0, Color("#37e08c")]]
const GRAD_RED := [[0.0, Color("#ff8095")], [0.55, Color("#ff5c72")], [1.0, Color("#e63a52")]]
const GRAD_DARK := [[0.0, Color("#3a3450")], [1.0, Color("#2a2540")]]
const GRAD_LOCKED := [[0.0, Color("#443a5e")], [1.0, Color("#332a4a")]]
const GRAD_PANEL := [[0.0, Color("#2c2050")], [1.0, Color("#1a1330")]]
const GRAD_PANEL_LOSE := [[0.0, Color("#3a2030")], [1.0, Color("#1e1224")]]
const GRAD_TITLE := [[0.0, Color("#ffe89a")], [0.55, Color("#ffc233")], [1.0, Color("#ff9d00")]]

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
	# The axis must be the int OpenType tag: string keys are silently ignored.
	fv.variation_opentype = {0x77676874: weight} # 'wght'
	if spacing != 0:
		fv.spacing_glyph = spacing
	_font_cache[key] = fv
	return fv


# ------------------------------------------------------------ gradient drawing

static func grad_color(stops: Array, t: float) -> Color:
	t = clampf(t, 0.0, 1.0)
	if t <= stops[0][0]:
		return stops[0][1]
	for i in range(1, stops.size()):
		if t <= stops[i][0]:
			var a: Array = stops[i - 1]
			var b: Array = stops[i]
			var span: float = b[0] - a[0]
			return (a[1] as Color).lerp(b[1], 0.0 if span <= 0.0 else (t - a[0]) / span)
	return stops[stops.size() - 1][1]


static func round_points(rect: Rect2, radius: float, stops: Array = []) -> PackedVector2Array:
	var r := minf(radius, minf(rect.size.x, rect.size.y) / 2.0)
	var pts := PackedVector2Array()
	var segs := 10
	var corners := [
		[rect.position + Vector2(r, r), PI],                        # top-left
		[Vector2(rect.end.x - r, rect.position.y + r), 1.5 * PI],   # top-right
		[rect.end - Vector2(r, r), 0.0],                            # bottom-right
		[Vector2(rect.position.x + r, rect.end.y - r), 0.5 * PI],   # bottom-left
	]
	# Interior y positions at each gradient stop, to help interpolation.
	var mid_ys: Array = []
	for s in stops:
		var y: float = rect.position.y + s[0] * rect.size.y
		if y > rect.position.y + r and y < rect.end.y - r:
			mid_ys.append(y)
	for ci in 4:
		var c: Vector2 = corners[ci][0]
		var start: float = corners[ci][1]
		for i in segs + 1:
			var ang: float = start + (i / float(segs)) * 0.5 * PI
			pts.append(c + Vector2(cos(ang), sin(ang)) * r)
		if ci == 1: # descending the right edge
			for y in mid_ys:
				pts.append(Vector2(rect.end.x, y))
		elif ci == 3: # ascending the left edge
			for j in range(mid_ys.size() - 1, -1, -1):
				pts.append(Vector2(rect.position.x, mid_ys[j]))
	return pts


static func draw_round_grad(ci: CanvasItem, rect: Rect2, radius: float, stops: Array) -> void:
	var pts := round_points(rect, radius, stops)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(grad_color(stops, (p.y - rect.position.y) / rect.size.y))
	ci.draw_polygon(pts, cols)


static func draw_round_flat(ci: CanvasItem, rect: Rect2, radius: float, col: Color) -> void:
	ci.draw_polygon(round_points(rect, radius), PackedColorArray([col]))


static func draw_round_border(ci: CanvasItem, rect: Rect2, radius: float,
		col: Color, width := 1.0) -> void:
	var pts := round_points(rect, radius)
	pts.append(pts[0])
	ci.draw_polyline(pts, col, width, true)


static func brighten_stops(stops: Array, amt: float) -> Array:
	var out: Array = []
	for s in stops:
		out.append([s[0], (s[1] as Color).lightened(amt)])
	return out


# ------------------------------------------------------------ buttons

## Chunky arcade button: vertical gradient body over a solid 3D bottom edge
## (CSS `box-shadow: 0 Npx 0 <edge>`); pressing sinks the body onto the edge.
class ChunkyButton:
	extends Button

	var stops: Array = UI.GRAD_GOLD
	var edge_color := UI.GOLD_DARK
	var edge := 5.0
	var radius := 20.0
	var glow := Color(0, 0, 0, 0)

	func configure(p_stops: Array, p_edge_color: Color, p_edge: float, p_radius: float,
			fg: Color, font: Font, font_size: int, pad_h: float) -> void:
		stops = p_stops
		edge_color = p_edge_color
		edge = p_edge
		radius = p_radius
		add_theme_font_override("font", font)
		add_theme_font_size_override("font_size", font_size)
		for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			add_theme_color_override(st, fg)
		add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.4))
		var sbn := StyleBoxEmpty.new()
		sbn.content_margin_left = pad_h
		sbn.content_margin_right = pad_h
		sbn.content_margin_top = 0.0
		sbn.content_margin_bottom = edge
		var sbp := StyleBoxEmpty.new()
		sbp.content_margin_left = pad_h
		sbp.content_margin_right = pad_h
		sbp.content_margin_top = edge - 1.0
		sbp.content_margin_bottom = 1.0
		for st in ["normal", "hover", "disabled", "focus"]:
			add_theme_stylebox_override(st, sbn)
		add_theme_stylebox_override("pressed", sbp)

	func _draw() -> void:
		var mode := get_draw_mode()
		var pressed := mode == DRAW_PRESSED
		var eh := 1.0 if pressed else edge
		var body := Rect2(0, edge - eh, size.x, size.y - edge)
		var r := minf(radius, body.size.y / 2.0)
		if glow.a > 0.0 and not pressed and not disabled:
			for k in 3:
				UI.draw_round_flat(self, body.grow(2.0 + k * 3.0)
						.grow_side(SIDE_BOTTOM, 5.0), r + k * 3.0, Color(glow, glow.a * 0.16))
		UI.draw_round_flat(self,
				Rect2(body.position + Vector2(0, eh), body.size), r, edge_color)
		var st := stops
		if disabled:
			st = UI.GRAD_DARK
		elif mode == DRAW_HOVER:
			st = UI.brighten_stops(stops, 0.06)
		UI.draw_round_grad(self, body, r, st)
		# Script _draw paints after the built-in text, so render it ourselves
		# on top of the gradient (it also sinks with the body when pressed).
		if text != "":
			var f := get_theme_font("font")
			var fs := get_theme_font_size("font_size")
			var col := get_theme_color("font_disabled_color" if disabled else "font_color")
			var base_y := body.position.y + (body.size.y - f.get_height(fs)) / 2.0 + f.get_ascent(fs)
			draw_string(f, Vector2(0, base_y), text,
					HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, col)


## kind: gold | purple | purple2 | green | dark | red | locked | ghost
static func chunky_button(text: String, font_size := 16, kind := "gold",
		spacing := 0, weight := -1) -> Button:
	if kind == "ghost":
		var g := Button.new()
		g.text = text
		g.add_theme_font_override("font", nunito(700, 1))
		g.add_theme_font_size_override("font_size", font_size)
		for st in ["normal", "hover", "pressed", "disabled", "focus"]:
			g.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		for st in ["font_color", "font_hover_color", "font_focus_color"]:
			g.add_theme_color_override(st, TEXT_FAINT)
		g.add_theme_color_override("font_pressed_color", TEXT)
		return g

	var stops: Array
	var edge_col: Color
	var fg: Color
	var w := 600
	match kind:
		"purple":
			stops = GRAD_PURPLE; edge_col = Color("#170f2b"); fg = TEXT_SOFT
		"purple2":
			stops = GRAD_PURPLE2; edge_col = Color("#241a44"); fg = TEXT_SOFT
		"green":
			stops = GRAD_GREEN2; edge_col = Color("#1f9e63"); fg = Color("#1b3a2a")
		"dark":
			stops = GRAD_DARK; edge_col = Color("#1a1628"); fg = ICON_COL
		"red":
			stops = GRAD_RED; edge_col = Color("#a02638"); fg = Color.WHITE; w = 700
		"locked":
			stops = GRAD_LOCKED; edge_col = Color("#221c33"); fg = Color(1, 1, 1, 0.6); w = 700
		_:
			stops = GRAD_GOLD; edge_col = GOLD_DARK; fg = GOLD_TEXT; w = 700
	if weight > 0:
		w = weight

	var b := ChunkyButton.new()
	b.text = text
	b.configure(stops, edge_col, 5.0, 20.0, fg, fredoka(w, spacing), font_size, 24.0)
	return b


## Glassy 44x44 icon button (back, pause, gear); presses scale to 0.92.
static func icon_button(glyph: String = "") -> Button:
	var b := Button.new()
	b.text = glyph
	b.custom_minimum_size = Vector2(44, 44)
	b.add_theme_font_override("font", fredoka(600))
	b.add_theme_font_size_override("font_size", 22)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.07)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(1)
	sb.border_color = Color(1, 1, 1, 0.09)
	b.add_theme_stylebox_override("normal", sb)
	var sbh: StyleBoxFlat = sb.duplicate()
	sbh.bg_color = Color(1, 1, 1, 0.12)
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(st, ICON_COL)
	b.button_down.connect(func() -> void:
		b.pivot_offset = b.size / 2.0
		b.scale = Vector2(0.92, 0.92))
	b.button_up.connect(func() -> void:
		b.scale = Vector2.ONE)
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


# ------------------------------------------------------------ labels & chips

static func label(text: String, font_size := 15, color := TEXT, font: Font = null,
		align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if font else nunito(700))
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	return l


static func heading(text: String, font_size := 26, color := TEXT, spacing := 1) -> Label:
	return label(text, font_size, color, fredoka(600, spacing))


## Glassy pill chip; returns the PanelContainer with an HBox child to fill.
static func chip(radius := 20, pad := Vector4(8, 8, 14, 8)) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = CHIP_BG
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(1)
	sb.border_color = CHIP_BORDER
	sb.content_margin_left = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_right = pad.z
	sb.content_margin_bottom = pad.w
	p.add_theme_stylebox_override("panel", sb)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	p.add_child(box)
	return p


## Rounded panel with the mockup's vertical gradient, border and drop shadow.
class GradientPanel:
	extends PanelContainer

	var stops: Array = UI.GRAD_PANEL
	var radius := 28.0

	func _init(pad := Vector4(28, 32, 28, 28)) -> void:
		var sb := StyleBoxEmpty.new()
		sb.content_margin_left = pad.x
		sb.content_margin_top = pad.y
		sb.content_margin_right = pad.z
		sb.content_margin_bottom = pad.w
		add_theme_stylebox_override("panel", sb)
		resized.connect(func() -> void: pivot_offset = size / 2.0)

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		for k in 4:
			UI.draw_round_flat(self, rect.grow(3.0 + k * 6.0)
					.grow_side(SIDE_BOTTOM, 8.0), radius + k * 6.0, Color(0, 0, 0, 0.1))
		UI.draw_round_grad(self, rect, radius, stops)
		UI.draw_round_border(self, rect, radius, UI.PANEL_BORDER, 1.0)


static func overlay_panel(stops: Array = GRAD_PANEL, pad := Vector4(28, 32, 28, 28)) -> PanelContainer:
	var p := GradientPanel.new(pad)
	p.stops = stops
	return p


static func spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


# ------------------------------------------------------------ drawn icons

## Gold coin disc, drawn glossy (radial highlight + dark inset ring).
class CoinDot:
	extends Control

	var radius := 13.0

	func _init(r := 13.0) -> void:
		radius = r
		custom_minimum_size = Vector2(r * 2.0, r * 2.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c, radius, Color("#ffb000"), true, -1.0, true)
		draw_circle(c + Vector2(-radius * 0.25, -radius * 0.3), radius * 0.55,
				Color("#ffe066"), true, -1.0, true)
		draw_arc(c, radius - 1.0, 0.0, TAU, 40, Color("#7a4b00", 0.8), 2.0, true)


## Coins pill: 26px coin + Fredoka 600 16px on the menu; 22px + 14px elsewhere.
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
		sb.content_margin_right = 14.0
		sb.content_margin_top = 8.0
		sb.content_margin_bottom = 8.0
		add_theme_stylebox_override("panel", sb)
		var box := HBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		add_child(box)
		box.add_child(CoinDot.new(11.0 if small else 13.0))
		_label = UI.label(str(amount), 14 if small else 16, UI.GOLD_PALE, UI.fredoka(600))
		box.add_child(_label)

	func set_amount(v: int) -> void:
		_label.text = str(v)


## Padlock: 16x13 shackle over a 22x17 rounded body, white at 55%.
class LockIcon:
	extends Control

	func _init() -> void:
		custom_minimum_size = Vector2(24, 28)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var col := Color(1, 1, 1, 0.55)
		var cx := size.x / 2.0
		draw_arc(Vector2(cx, 11.0), 6.75, PI, TAU, 20, col, 2.5, true)
		var sb := StyleBoxFlat.new()
		sb.bg_color = col
		sb.set_corner_radius_all(5)
		draw_style_box(sb, Rect2(cx - 11.0, 11.0, 22.0, 17.0))


class GearIcon:
	extends Control

	func _init() -> void:
		custom_minimum_size = Vector2(22, 22)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var col := UI.ICON_COL
		var c := size / 2.0
		for i in 8:
			var ang := i * TAU / 8.0
			draw_line(c + Vector2(cos(ang), sin(ang)) * 5.5,
					c + Vector2(cos(ang), sin(ang)) * 10.0, col, 3.2, true)
		draw_circle(c, 6.4, col, true, -1.0, true)
		draw_circle(c, 2.9, Color("#251a3f"), true, -1.0, true)


## Two 4x16 rounded bars with a 4px gap.
class PauseIcon:
	extends Control

	func _init() -> void:
		custom_minimum_size = Vector2(12, 16)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = UI.ICON_COL
		sb.set_corner_radius_all(2)
		var y := (size.y - 16.0) / 2.0
		draw_style_box(sb, Rect2(size.x / 2.0 - 6.0, y, 4.0, 16.0))
		draw_style_box(sb, Rect2(size.x / 2.0 + 2.0, y, 4.0, 16.0))


## Counter-clockwise undo arrow.
class UndoIcon:
	extends Control

	var color := UI.TEXT_SOFT

	func _init() -> void:
		custom_minimum_size = Vector2(18, 18)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		var r := 6.5
		draw_arc(c, r, -0.4 * PI, 1.1 * PI, 24, color, 2.4, true)
		var tip := c + Vector2(cos(-0.4 * PI), sin(-0.4 * PI)) * r
		var dirv := Vector2(cos(-0.4 * PI + 0.5 * PI), sin(-0.4 * PI + 0.5 * PI))
		var nv := Vector2(cos(-0.4 * PI), sin(-0.4 * PI))
		draw_colored_polygon(PackedVector2Array([
			tip + dirv * -5.0 + nv * 3.2,
			tip + dirv * -5.0 - nv * 3.2,
			tip + dirv * 2.0,
		]), color)


## Little lightbulb for the hint button.
class BulbIcon:
	extends Control

	var color := UI.GOLD_TEXT

	func _init() -> void:
		custom_minimum_size = Vector2(16, 18)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := Vector2(size.x / 2.0, 7.0)
		draw_circle(c, 6.0, color, true, -1.0, true)
		var sb := StyleBoxFlat.new()
		sb.bg_color = color
		sb.set_corner_radius_all(1)
		draw_style_box(sb, Rect2(c.x - 3.0, 13.0, 6.0, 2.0))
		draw_style_box(sb, Rect2(c.x - 2.0, 16.0, 4.0, 2.0))


## Expanding fading ring, like the mockup's knotsPulseRing keyframes.
class PulseRing:
	extends Control

	var color := Color("#ffc233")
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t = fmod(_t + delta, 2.0)
		queue_redraw()

	func _draw() -> void:
		var f := _t / 1.4
		if f > 1.0:
			return
		var base := minf(size.x, size.y) / 2.0
		draw_arc(size / 2.0, base + f * 16.0, 0.0, TAU, 48,
				Color(color, 0.55 * (1.0 - f)), 3.0, true)
