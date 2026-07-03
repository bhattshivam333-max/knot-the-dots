class_name Board
extends Control
## The playable puzzle board: rendering, touch input and all game rules.
##
## Rules (Flow-style): drag from a dot to draw that color's line cell by cell.
## Lines may not cross; drawing over another line cuts its tail off. Drawing
## back over your own line rewinds it. Bridge cells allow exactly two lines
## to pass through, one horizontally and one vertically. The level is won
## when every pair is connected AND every cell is covered.

signal state_changed
signal level_won

var grid_n := 5
var solution: Array = []      # color -> Array[Vector2i], the generator's paths
var bridge_cells := {}        # Vector2i -> true
var dots := {}                # Vector2i -> color index
var paths: Array = []         # color -> Array[Vector2i] currently drawn
var completed: Array = []     # color -> bool
var occ := {}                 # Vector2i -> Array[color]
var z_order: Array = []       # draw order, most recently touched last

var moves := 0
var hint_used := false
var locked := false

var show_letters := false

var active := -1              # color being dragged, -1 when idle
var _press_color := -1
var _touch_index := -1
var _snapshot: Array = []
var _last_move_color := -1

var _pulse_t := 0.0
var _flash := {}              # color -> remaining flash time

var _cell_px := 0.0
var _origin := Vector2.ZERO
var _sb_bg := StyleBoxFlat.new()
var _sb_cell := StyleBoxFlat.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_sb_bg.bg_color = Color("#1b2233")
	_sb_bg.set_corner_radius_all(18)
	_sb_cell.set_corner_radius_all(8)
	resized.connect(queue_redraw)
	set_process(false)


func setup(level: Dictionary) -> void:
	grid_n = level["n"]
	solution = level["paths"]
	bridge_cells = {}
	for b in level["bridges"]:
		bridge_cells[b] = true
	dots = {}
	for i in solution.size():
		var p: Array = solution[i]
		dots[p[0]] = i
		dots[p.back()] = i
	restart()


func restart() -> void:
	paths = []
	completed = []
	z_order = []
	for i in solution.size():
		paths.append([])
		completed.append(false)
		z_order.append(i)
	occ = {}
	active = -1
	_press_color = -1
	_touch_index = -1
	moves = 0
	_last_move_color = -1
	hint_used = false
	locked = false
	_flash = {}
	set_process(false)
	queue_redraw()
	state_changed.emit()


func done_count() -> int:
	var c := 0
	for done in completed:
		if done:
			c += 1
	return c


func coverage() -> float:
	return float(occ.size()) / float(grid_n * grid_n)


func stars_earned() -> int:
	if hint_used:
		return 1
	if moves <= solution.size():
		return 3
	if moves <= solution.size() + 3:
		return 2
	return 1


## Fill in the solution for one unfinished color, cutting anything in the way.
func apply_hint() -> void:
	if locked:
		return
	var target := -1
	for c in solution.size():
		if not completed[c]:
			target = c
			break
	if target == -1:
		# All pairs connected but board not full: fix a path that differs.
		for c in solution.size():
			if not _matches_solution(c):
				target = c
				break
	if target == -1:
		return
	hint_used = true
	var sol: Array = solution[target].duplicate()
	for k in sol.size():
		var cell: Vector2i = sol[k]
		for d in occ.get(cell, []).duplicate():
			if d == target:
				continue
			if bridge_cells.has(cell):
				if _axis_h_at(d, cell) == _sol_axis_h(sol, k):
					_cut(d, cell, true)
			else:
				_cut(d, cell, true)
	paths[target] = sol
	completed[target] = true
	moves += 1
	_last_move_color = target
	_flash[target] = 1.0
	Sfx.play("connect")
	_after_change(target)
	_check_win()


func _matches_solution(c: int) -> bool:
	var p: Array = paths[c]
	var s: Array = solution[c]
	if p.size() != s.size():
		return false
	if p == s:
		return true
	var rev := s.duplicate()
	rev.reverse()
	return p == rev


# ------------------------------------------------------------------ input

func _gui_input(event: InputEvent) -> void:
	if locked:
		return
	if event is InputEventScreenTouch:
		_recalc_geometry()
		if event.pressed:
			if _touch_index == -1:
				_touch_index = event.index
				_press(_cell_of(event.position))
		elif event.index == _touch_index:
			_touch_index = -1
			_release()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_recalc_geometry()
		_drag_to(_cell_of(event.position))


func _press(cell: Vector2i) -> void:
	if cell.x < 0:
		return
	_snapshot = _make_snapshot()
	var c := -1
	if dots.has(cell):
		c = dots[cell]
		paths[c] = [cell]
		completed[c] = false
	elif occ.has(cell):
		var cands: Array = occ[cell]
		c = cands[0]
		for zi in z_order: # last in z-order (topmost) wins
			if zi in cands:
				c = zi
		for d in cands: # ...unless a line ends exactly here
			if not paths[d].is_empty() and paths[d].back() == cell:
				c = d
		var i: int = paths[c].find(cell)
		paths[c].resize(i + 1)
		completed[c] = false
	if c == -1:
		return
	active = c
	_press_color = c
	Sfx.play("pop")
	_after_change(c)


func _drag_to(cell: Vector2i) -> void:
	if active == -1 or cell.x < 0:
		return
	var guard := 0
	while guard < 64 and active != -1:
		guard += 1
		var head: Vector2i = paths[active].back()
		if head == cell:
			return
		var delta := cell - head
		var steps: Array = []
		if absi(delta.x) >= absi(delta.y):
			if delta.x != 0:
				steps.append(Vector2i(signi(delta.x), 0))
			if delta.y != 0:
				steps.append(Vector2i(0, signi(delta.y)))
		else:
			if delta.y != 0:
				steps.append(Vector2i(0, signi(delta.y)))
			if delta.x != 0:
				steps.append(Vector2i(signi(delta.x), 0))
		var moved := false
		for s in steps:
			if _try_step(active, head + s):
				moved = true
				break
		if not moved:
			return


func _release() -> void:
	active = -1
	_commit_move()
	_press_color = -1


func _commit_move() -> void:
	if _press_color == -1:
		return
	if _snapshot != _make_snapshot():
		if _press_color != _last_move_color:
			moves += 1
			_last_move_color = _press_color
		_snapshot = _make_snapshot()
		state_changed.emit()


func _try_step(c: int, next: Vector2i) -> bool:
	if next.x < 0 or next.y < 0 or next.x >= grid_n or next.y >= grid_n:
		return false
	var p: Array = paths[c]
	var head: Vector2i = p.back()

	# A line on a bridge must keep going straight.
	if bridge_cells.has(head) and p.size() >= 2:
		if next - head != head - p[p.size() - 2]:
			return false

	# Back onto our own line: rewind to that point.
	var own_i: int = p.find(next)
	if own_i != -1:
		p.resize(own_i + 1)
		completed[c] = false
		_after_change(c)
		return true

	# Dots block every color except their own.
	if dots.has(next):
		if dots[next] != c:
			return false
		p.append(next)
		completed[c] = true
		_flash[c] = 1.0
		active = -1
		Sfx.play("connect")
		_after_change(c)
		_commit_move()
		_press_color = -1
		_check_win()
		return true

	# Crossing other lines: cut them, unless a bridge lets us coexist.
	var here: Array = occ.get(next, [])
	if not here.is_empty():
		if bridge_cells.has(next):
			var my_h := (next - head).y == 0
			for d in here.duplicate():
				if d != c and _axis_h_at(d, next) == my_h:
					_cut(d, next)
		else:
			for d in here.duplicate():
				_cut(d, next)

	p.append(next)
	_after_change(c)
	return true


## Remove `cell` and everything after it from color d's line.
func _cut(d: int, cell: Vector2i, quiet := false) -> void:
	var i: int = paths[d].find(cell)
	if i == -1:
		return
	paths[d].resize(i)
	completed[d] = false
	if not quiet:
		Sfx.play("cut")


## Whether color d's line runs horizontally through `cell`.
func _axis_h_at(d: int, cell: Vector2i) -> bool:
	var dp: Array = paths[d]
	var j: int = dp.find(cell)
	if dp.size() < 2 or j == -1:
		return true
	var nb: Vector2i = dp[j - 1] if j > 0 else dp[j + 1]
	return nb.y == cell.y


func _sol_axis_h(sol: Array, k: int) -> bool:
	var nb: Vector2i = sol[k - 1] if k > 0 else sol[k + 1]
	return nb.y == sol[k].y


func _after_change(c: int) -> void:
	z_order.erase(c)
	z_order.append(c)
	_rebuild_occ()
	set_process(true)
	queue_redraw()
	state_changed.emit()


func _rebuild_occ() -> void:
	occ = {}
	for c in paths.size():
		for cell in paths[c]:
			if not occ.has(cell):
				occ[cell] = []
			occ[cell].append(c)


func _make_snapshot() -> Array:
	var snap: Array = []
	for p in paths:
		snap.append(p.duplicate())
	return snap


func _check_win() -> void:
	for done in completed:
		if not done:
			return
	if occ.size() < grid_n * grid_n:
		return
	locked = true
	Sfx.play("win")
	level_won.emit()


# ------------------------------------------------------------------ drawing

func _process(delta: float) -> void:
	_pulse_t += delta
	var busy := active != -1
	for k in _flash.keys():
		_flash[k] -= delta * 2.0
		if _flash[k] <= 0.0:
			_flash.erase(k)
		else:
			busy = true
	queue_redraw()
	if not busy:
		set_process(false)


func _recalc_geometry() -> void:
	var side := minf(size.x, size.y) - 8.0
	_cell_px = side / grid_n
	_origin = (size - Vector2(side, side)) / 2.0


func _center(cell: Vector2i) -> Vector2:
	return _origin + (Vector2(cell) + Vector2(0.5, 0.5)) * _cell_px


func _cell_of(pos: Vector2) -> Vector2i:
	var f := (pos - _origin) / _cell_px
	var cell := Vector2i(floori(f.x), floori(f.y))
	if cell.x < 0 or cell.y < 0 or cell.x >= grid_n or cell.y >= grid_n:
		return Vector2i(-1, -1)
	return cell


func _draw() -> void:
	_recalc_geometry()
	var side := _cell_px * grid_n
	draw_style_box(_sb_bg, Rect2(_origin, Vector2(side, side)))

	var grid_col := Color(1, 1, 1, 0.05)
	for i in range(1, grid_n):
		var o := _origin + Vector2(i * _cell_px, 0)
		draw_line(o, o + Vector2(0, side), grid_col, 1.5)
		o = _origin + Vector2(0, i * _cell_px)
		draw_line(o, o + Vector2(side, 0), grid_col, 1.5)

	# Soft tint on covered cells.
	var pad := _cell_px * 0.06
	for cell in occ:
		var col: Color = Levels.PALETTE[occ[cell][0]]
		_sb_cell.bg_color = Color(col, 0.12)
		draw_style_box(_sb_cell, Rect2(
			_origin + Vector2(cell) * _cell_px + Vector2(pad, pad),
			Vector2(_cell_px - pad * 2.0, _cell_px - pad * 2.0)))

	# Lines, most recently touched on top.
	var w := _cell_px * 0.34
	for c in z_order:
		var p: Array = paths[c]
		if p.is_empty():
			continue
		var col: Color = Levels.PALETTE[c]
		var pts := PackedVector2Array()
		for cell in p:
			pts.append(_center(cell))
		var glow := Color(col, 0.2)
		if pts.size() >= 2:
			draw_polyline(pts, glow, w * 1.9, true)
		for q in pts:
			draw_circle(q, w * 0.95, glow, true, -1.0, true)
		if pts.size() >= 2:
			draw_polyline(pts, col, w, true)
		for q in pts:
			draw_circle(q, w * 0.5, col, true, -1.0, true)

	# Bridge markers.
	for cell in bridge_cells:
		draw_arc(_center(cell), _cell_px * 0.43, 0.0, TAU, 40, Color(1, 1, 1, 0.4), 2.5, true)

	# Dots.
	var font := ThemeDB.fallback_font
	for cell in dots:
		var c: int = dots[cell]
		var col: Color = Levels.PALETTE[c]
		var ctr := _center(cell)
		var r := _cell_px * 0.3
		if c == active:
			r *= 1.0 + 0.08 * sin(_pulse_t * 8.0)
		if _flash.has(c):
			r *= 1.0 + 0.22 * _flash[c]
		if completed[c]:
			draw_arc(ctr, r + _cell_px * 0.08, 0.0, TAU, 40, Color(col, 0.55), 3.0, true)
		draw_circle(ctr, r, col, true, -1.0, true)
		if show_letters:
			var fs := int(_cell_px * 0.3)
			draw_string(font, ctr + Vector2(-r, fs * 0.36), char(65 + c),
					HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, fs, Color(0, 0, 0, 0.75))
