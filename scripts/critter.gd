class_name Critter
extends Control
## A zone mascot drawn entirely in code: fox, frog, owl, cactus, firefly
## or bat. Idles with a gentle breathing bob and blinks; reacts to game
## events with short squash-and-stretch animations:
##   react_happy()  - pair connected: little double hop
##   react_sad()    - line got cut: wince and head shake
##   celebrate()    - level won: keeps jumping
##   set_worried()  - timer low: trembles, wide eyes
##   droop()        - time up: sags flat

enum Mood { IDLE, HAPPY, SAD, CELEBRATE, WORRIED, DROOP }

const REACT_TIME := 0.9

var kind := "fox"
var mood: int = Mood.IDLE
var hungry := false

var _t := 0.0
var _mood_t := 0.0
var _blink := 0.0
var _hearts: Array = []


func _init(p_kind := "fox") -> void:
	kind = p_kind
	custom_minimum_size = Vector2(84, 96)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	if _mood_t > 0.0:
		_mood_t -= delta
		if _mood_t <= 0.0 and (mood == Mood.HAPPY or mood == Mood.SAD):
			mood = Mood.IDLE
	if _blink > 0.0:
		_blink -= delta
	elif mood == Mood.IDLE and randf() < delta / 3.5:
		_blink = 0.12
	for i in range(_hearts.size() - 1, -1, -1):
		_hearts[i]["t"] += delta
		if _hearts[i]["t"] > 1.2:
			_hearts.remove_at(i)
	queue_redraw()


## Feeding: happy hop plus a little burst of floating hearts.
func feed_burst() -> void:
	hungry = false
	react_happy()
	for i in 5:
		_hearts.append({
			"p": Vector2(size.x / 2.0 + randf_range(-18.0, 18.0), size.y - 46.0),
			"t": -randf() * 0.25,
		})


func react_happy() -> void:
	if mood == Mood.CELEBRATE or mood == Mood.DROOP:
		return
	mood = Mood.HAPPY
	_mood_t = REACT_TIME


func react_sad() -> void:
	if mood == Mood.CELEBRATE or mood == Mood.DROOP:
		return
	mood = Mood.SAD
	_mood_t = REACT_TIME


func celebrate() -> void:
	mood = Mood.CELEBRATE


func set_worried(on: bool) -> void:
	if mood == Mood.IDLE or mood == Mood.WORRIED:
		mood = Mood.WORRIED if on else Mood.IDLE


func droop() -> void:
	mood = Mood.DROOP


# ------------------------------------------------------------------ drawing

func _draw() -> void:
	# Pose: bounce (y offset), squash (vertical scale) and tilt, all
	# anchored at the feet.
	var bounce := sin(_t * 2.2) * 1.5
	var squash := 1.0 + sin(_t * 2.2) * 0.015
	var tilt := 0.0
	match mood:
		Mood.HAPPY:
			var p := 1.0 - _mood_t / REACT_TIME
			bounce = -absf(sin(p * TAU)) * 9.0
			squash = 1.0 + 0.07 * sin(p * TAU * 2.0)
		Mood.SAD:
			var p := 1.0 - _mood_t / REACT_TIME
			tilt = sin(p * TAU * 2.5) * 0.1 * (1.0 - p)
			bounce = 2.0
			squash = 0.95
		Mood.CELEBRATE:
			bounce = -absf(sin(_t * 5.0)) * 12.0
			tilt = sin(_t * 5.0) * 0.1
			squash = 1.0 + 0.05 * sin(_t * 10.0)
		Mood.WORRIED:
			tilt = sin(_t * 24.0) * 0.02
			bounce = sin(_t * 2.2) * 1.0
		Mood.DROOP:
			bounce = 6.0
			squash = 0.86
			tilt = 0.12

	var feet := Vector2(size.x / 2.0, size.y - 6.0)
	draw_set_transform(feet, 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 22.0, Color(0, 0, 0, 0.22), true, -1.0, true)
	draw_set_transform(feet + Vector2(0, bounce), tilt, Vector2(2.0 - squash, squash))
	match kind:
		"frog":
			_frog()
		"owl":
			_owl()
		"cactus":
			_cactus()
		"firefly":
			_firefly()
		"bat":
			_bat()
		_:
			_fox()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for h in _hearts:
		var ht: float = h["t"]
		if ht < 0.0:
			continue
		var hp: Vector2 = h["p"] - Vector2(sin(ht * 7.0) * 4.0, ht * 44.0)
		_heart(hp, 5.5, Color("#ff5c72", clampf(1.0 - ht / 1.2, 0.0, 1.0)))


func _heart(c: Vector2, s: float, col: Color) -> void:
	draw_circle(c + Vector2(-s * 0.5, -s * 0.3), s * 0.55, col, true, -1.0, true)
	draw_circle(c + Vector2(s * 0.5, -s * 0.3), s * 0.55, col, true, -1.0, true)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-s * 1.0, -s * 0.05),
		c + Vector2(s * 1.0, -s * 0.05),
		c + Vector2(0, s * 1.0),
	]), col)


## Eyes + mouth. `pos` is between the eyes, in body-local coords.
func _face(pos: Vector2, s := 1.0, dark := Color("#241a2e"), eye_dx := 7.0) -> void:
	var happy := mood == Mood.HAPPY or mood == Mood.CELEBRATE
	var sad := mood == Mood.SAD or mood == Mood.DROOP \
			or (hungry and mood == Mood.IDLE)
	var wide := mood == Mood.WORRIED
	for sx in [-1.0, 1.0]:
		var ep := pos + Vector2(sx * eye_dx * s, 0)
		if _blink > 0.0:
			draw_line(ep - Vector2(3.0 * s, 0), ep + Vector2(3.0 * s, 0), dark, 2.0 * s, true)
		elif happy:
			draw_arc(ep + Vector2(0, 1.5 * s), 3.4 * s, PI + 0.35, TAU - 0.35, 10, dark, 2.2 * s, true)
		else:
			var r := 3.1 * s * (1.3 if wide else 1.0)
			draw_circle(ep, r, dark, true, -1.0, true)
			draw_circle(ep + Vector2(r * 0.3, -r * 0.3), r * 0.32, Color(1, 1, 1, 0.9), true, -1.0, true)
	var mp := pos + Vector2(0, 6.5 * s)
	if happy:
		draw_arc(mp, 4.0 * s, 0.3, PI - 0.3, 10, dark, 2.2 * s, true)
	elif sad:
		draw_arc(mp + Vector2(0, 3.5 * s), 4.0 * s, PI + 0.4, TAU - 0.4, 10, dark, 2.2 * s, true)
	elif wide:
		draw_circle(mp, 2.2 * s, dark, true, -1.0, true)
	else:
		draw_line(mp - Vector2(2.4 * s, 0), mp + Vector2(2.4 * s, 0), dark, 2.0 * s, true)


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)


# ---------------------------------------------------------------- the six

func _fox() -> void:
	var orange := Color("#ff8b3d")
	var inner := Color("#c95f24")
	for sx in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(sx * 22, -56), Vector2(sx * 4, -48), Vector2(sx * 17, -34)]), orange)
		draw_colored_polygon(PackedVector2Array([
			Vector2(sx * 18, -52), Vector2(sx * 8, -47), Vector2(sx * 15, -38)]), inner)
	draw_circle(Vector2(0, -26), 23.0, orange, true, -1.0, true)
	_ellipse(Vector2(0, -14), 12.0, 10.0, Color("#ffe3c9"))
	draw_circle(Vector2(0, -21), 3.0, Color("#241a2e"), true, -1.0, true) # nose
	_face(Vector2(0, -32), 1.0)


func _frog() -> void:
	var green := Color("#37e08c")
	for sx in [-1.0, 1.0]:
		draw_circle(Vector2(sx * 10, -42), 8.5, green, true, -1.0, true)
	draw_circle(Vector2(0, -20), 21.0, green, true, -1.0, true)
	_ellipse(Vector2(0, -12), 12.0, 9.0, Color("#a8f5cd"))
	for sx in [-1.0, 1.0]: # cheeks
		draw_circle(Vector2(sx * 13, -24), 3.0, Color("#ff8fa5", 0.6), true, -1.0, true)
	_face(Vector2(0, -42), 1.0, Color("#173d28"), 10.0)


func _owl() -> void:
	var purple := Color("#b775f5")
	var dark := Color("#8a4fd0")
	for sx in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(sx * 18, -52), Vector2(sx * 5, -48), Vector2(sx * 13, -40)]), purple)
	draw_circle(Vector2(0, -25), 22.0, purple, true, -1.0, true)
	for sx in [-1.0, 1.0]: # folded wings
		_ellipse(Vector2(sx * 17, -18), 6.0, 12.0, dark)
	_ellipse(Vector2(0, -12), 11.0, 9.0, Color("#e2ccff"))
	for sx in [-1.0, 1.0]: # eye rings
		draw_circle(Vector2(sx * 8, -32), 6.5, Color("#f4ebff"), true, -1.0, true)
	draw_colored_polygon(PackedVector2Array([ # beak
		Vector2(-3, -26), Vector2(3, -26), Vector2(0, -20)]), Color("#ffb14d"))
	_face(Vector2(0, -32), 1.0, Color("#241a2e"), 8.0)


func _cactus() -> void:
	var green := Color("#3ec978")
	var dark := green.darkened(0.2)
	draw_rect(Rect2(-13, -46, 26, 46), green)
	draw_circle(Vector2(0, -46), 13.0, green, true, -1.0, true)
	for arm in [[-1.0, -30.0], [1.0, -24.0]]: # little arms
		var sx: float = arm[0]
		var ay: float = arm[1]
		draw_rect(Rect2(sx * 14.0 + (0.0 if sx > 0 else -9.0), ay, 9.0, 14.0), dark)
		draw_circle(Vector2(sx * 18.5, ay), 4.5, dark, true, -1.0, true)
	for i in 5: # spikes
		var sp := Vector2(-10.0 + i * 5.0, -8.0 - (i % 2) * 20.0)
		draw_line(sp, sp + Vector2(0, -3.5), Color(1, 1, 1, 0.5), 1.4, true)
	for i in 5: # flower
		var a := TAU * i / 5.0 - PI / 2.0
		draw_circle(Vector2(0, -56) + Vector2(cos(a), sin(a)) * 4.0, 3.4,
				Color("#ff8fa5"), true, -1.0, true)
	draw_circle(Vector2(0, -56), 2.6, Color("#ffe066"), true, -1.0, true)
	_face(Vector2(0, -34), 1.0, Color("#14351f"))


func _firefly() -> void:
	var glow := 0.5 + 0.5 * sin(_t * 3.0)
	if mood == Mood.HAPPY or mood == Mood.CELEBRATE:
		glow = 1.0
	var gold := Color("#ffe066")
	draw_circle(Vector2(0, -14), 14.0 + glow * 7.0, Color(gold, 0.10 + glow * 0.12), true, -1.0, true)
	var flap := absf(sin(_t * (26.0 if mood == Mood.HAPPY or mood == Mood.CELEBRATE else 7.0)))
	for sx in [-1.0, 1.0]:
		_ellipse(Vector2(sx * 8, -38), 5.5, 7.0 + flap * 4.0, Color(1, 1, 1, 0.22))
	draw_circle(Vector2(0, -14), 10.0, gold, true, -1.0, true) # glowing tail
	draw_circle(Vector2(0, -30), 10.0, Color("#3a2f5c"), true, -1.0, true)
	for sx in [-1.0, 1.0]: # antennae
		var base := Vector2(sx * 4, -39)
		draw_line(base, base + Vector2(sx * 5, -7), Color("#3a2f5c"), 1.6, true)
		draw_circle(base + Vector2(sx * 5, -7), 1.8, gold, true, -1.0, true)
	_face(Vector2(0, -30), 0.8, Color("#f1ecff"), 5.5)


func _bat() -> void:
	var body := Color("#4a3566")
	var wing := Color("#37254e")
	var flap := sin(_t * (14.0 if mood == Mood.HAPPY or mood == Mood.CELEBRATE else 3.0))
	for sx in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(sx * 10, -30),
			Vector2(sx * 34, -36 - flap * 7.0),
			Vector2(sx * 26, -22 - flap * 3.0),
			Vector2(sx * 16, -16),
		]), wing)
	for sx in [-1.0, 1.0]: # ears
		draw_colored_polygon(PackedVector2Array([
			Vector2(sx * 12, -48), Vector2(sx * 2, -44), Vector2(sx * 9, -34)]), body)
	draw_circle(Vector2(0, -26), 17.0, body, true, -1.0, true)
	for sx in [-1.0, 1.0]: # fangs
		draw_colored_polygon(PackedVector2Array([
			Vector2(sx * 4 - 1.5, -18), Vector2(sx * 4 + 1.5, -18), Vector2(sx * 4, -14)]),
			Color(1, 1, 1, 0.9))
	_face(Vector2(0, -30), 0.9, Color("#f1ecff"), 6.5)
