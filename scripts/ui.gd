class_name UI
## Shared colors and small factory helpers for code-built UI.

const BG := Color("#121826")
const PANEL := Color("#1b2233")
const PANEL_LIGHT := Color("#242e47")
const ACCENT := Color("#3f8cff")
const TEXT := Color("#e8ecf4")
const TEXT_DIM := Color("#8b93a7")
const GOLD := Color("#ffd93d")


static func button(text: String, font_size := 26, accent := false) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = ACCENT if accent else PANEL_LIGHT
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 26.0
	sb.content_margin_right = 26.0
	sb.content_margin_top = 14.0
	sb.content_margin_bottom = 14.0
	b.add_theme_stylebox_override("normal", sb)
	var sbh: StyleBoxFlat = sb.duplicate()
	sbh.bg_color = sb.bg_color.lightened(0.08)
	b.add_theme_stylebox_override("hover", sbh)
	var sbp: StyleBoxFlat = sb.duplicate()
	sbp.bg_color = sb.bg_color.darkened(0.15)
	b.add_theme_stylebox_override("pressed", sbp)
	var sbd: StyleBoxFlat = sb.duplicate()
	sbd.bg_color = Color(sb.bg_color, 0.4)
	b.add_theme_stylebox_override("disabled", sbd)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, TEXT)
	b.add_theme_color_override("font_disabled_color", TEXT_DIM)
	return b


static func label(text: String, font_size := 24, color := TEXT,
		align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	return l


static func panel_style(radius := 22.0, color := PANEL) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(int(radius))
	sb.content_margin_left = 34.0
	sb.content_margin_right = 34.0
	sb.content_margin_top = 28.0
	sb.content_margin_bottom = 28.0
	return sb


static func spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
