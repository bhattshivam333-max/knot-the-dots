class_name LevelGen
## Procedural puzzle generator.
##
## Builds a level by partitioning the grid into non-crossing snake paths that
## together cover every cell. The two ends of each path become that color's
## dots, so every generated level is solvable by construction (the paths
## themselves are one full-coverage solution). In bridge mode a growing path
## may tunnel straight through a perpendicular straight segment of an earlier
## path; that cell becomes a bridge.
##
## Generation is deterministic for a given (size, seed, bridges) triple.

const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const MIN_LEN := 3
const MAX_COLORS := 16


static func generate(n: int, seed_val: int, with_bridges := false) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("dotknot_%d_%d_%s" % [n, seed_val, str(with_bridges)])
	for relaxed in [false, true]:
		for attempt in 800:
			var res := _attempt(n, rng, with_bridges, relaxed)
			if not res.is_empty():
				return res
	return _fallback(n)


static func _attempt(n: int, rng: RandomNumberGenerator, with_bridges: bool, relaxed: bool) -> Dictionary:
	var owner := {}    # cell -> index of the path that first claimed it
	var second := {}   # bridge cell -> index of the path tunnelling through
	var bridges := {}
	var paths: Array = []
	var empties := {}
	for y in n:
		for x in n:
			empties[Vector2i(x, y)] = true

	var min_paths: int = 3 if relaxed else maxi(3, n - 1)
	var max_paths: int = MAX_COLORS if relaxed else mini(MAX_COLORS, n + 2 + n / 2)

	while not empties.is_empty():
		if paths.size() >= max_paths:
			return {}
		var pid := paths.size()
		var start := _pick_start(empties, rng)
		var path: Array = [start]
		empties.erase(start)
		owner[start] = pid
		var target := rng.randi_range(MIN_LEN, n + 3)
		_grow(path, pid, paths, owner, second, bridges, empties, n, rng, target, with_bridges)
		if path.size() < target:
			# Stuck growing forward; try extending from the other end.
			path.reverse()
			_grow(path, pid, paths, owner, second, bridges, empties, n, rng, target, with_bridges)
			path.reverse()
		if path.size() < MIN_LEN:
			return {}
		paths.append(path)

	if paths.size() < min_paths:
		return {}
	return {"n": n, "paths": paths, "bridges": bridges.keys()}


static func _grow(path: Array, pid: int, paths: Array, owner: Dictionary, second: Dictionary,
		bridges: Dictionary, empties: Dictionary, n: int, rng: RandomNumberGenerator,
		target: int, with_bridges: bool) -> void:
	while path.size() < target:
		var head: Vector2i = path.back()
		var normal: Array = []
		var bridged: Array = []
		for dir in DIRS:
			var nc: Vector2i = head + dir
			if not _in_bounds(nc, n):
				continue
			if empties.has(nc):
				if _touches_path(nc, head, path):
					continue
				normal.append(nc)
			elif with_bridges and owner.has(nc) and owner[nc] != pid \
					and not bridges.has(nc) and not second.has(nc):
				# Tunnel candidate: cell of an earlier path we could cross under.
				var op: Array = paths[owner[nc]]
				var j: int = op.find(nc)
				if j <= 0 or j >= op.size() - 1:
					continue
				var a: Vector2i = op[j - 1]
				var b: Vector2i = op[j + 1]
				var straight_h := a.y == nc.y and b.y == nc.y
				var straight_v := a.x == nc.x and b.x == nc.x
				if not (straight_h or straight_v):
					continue
				var my_h: bool = dir.y == 0
				if straight_h == my_h:
					continue # must cross perpendicular
				var far: Vector2i = nc + dir
				if not _in_bounds(far, n) or not empties.has(far):
					continue
				if _touches_path(far, head, path):
					continue
				bridged.append({"mid": nc, "far": far})

		var use_bridge := not bridged.is_empty() and (normal.is_empty() or rng.randf() < 0.3)
		if use_bridge:
			var pick: Dictionary = bridged[rng.randi_range(0, bridged.size() - 1)]
			var mid: Vector2i = pick["mid"]
			var far: Vector2i = pick["far"]
			bridges[mid] = true
			second[mid] = pid
			path.append(mid)
			path.append(far)
			empties.erase(far)
			owner[far] = pid
		elif normal.is_empty():
			return
		else:
			var nc: Vector2i = _choose_cell(normal, empties, rng)
			path.append(nc)
			empties.erase(nc)
			owner[nc] = pid


## Prefer cells with the fewest empty neighbours so pockets get filled
## before they become unreachable orphans.
static func _choose_cell(cands: Array, empties: Dictionary, rng: RandomNumberGenerator) -> Vector2i:
	if rng.randf() < 0.2:
		return cands[rng.randi_range(0, cands.size() - 1)]
	var best: Array = []
	var best_count := 99
	for c in cands:
		var cnt := _empty_neighbors(c, empties)
		if cnt < best_count:
			best_count = cnt
			best = [c]
		elif cnt == best_count:
			best.append(c)
	return best[rng.randi_range(0, best.size() - 1)]


static func _pick_start(empties: Dictionary, rng: RandomNumberGenerator) -> Vector2i:
	var best: Array = []
	var best_count := 99
	for c in empties:
		var cnt := _empty_neighbors(c, empties)
		if cnt < best_count:
			best_count = cnt
			best = [c]
		elif cnt == best_count:
			best.append(c)
	return best[rng.randi_range(0, best.size() - 1)]


static func _empty_neighbors(cell: Vector2i, empties: Dictionary) -> int:
	var cnt := 0
	for dir in DIRS:
		if empties.has(cell + dir):
			cnt += 1
	return cnt


## True if `cell` orthogonally touches the current path anywhere besides
## `head`. Keeping the snake from hugging itself makes cleaner puzzles.
static func _touches_path(cell: Vector2i, head: Vector2i, path: Array) -> bool:
	for dir in DIRS:
		var nb: Vector2i = cell + dir
		if nb == head:
			continue
		if path.has(nb):
			return true
	return false


static func _in_bounds(c: Vector2i, n: int) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < n and c.y < n


## Serpentine rows; trivially valid. Only used if random generation
## somehow fails every attempt.
static func _fallback(n: int) -> Dictionary:
	var paths: Array = []
	for y in n:
		var row: Array = []
		for x in n:
			row.append(Vector2i(x if y % 2 == 0 else n - 1 - x, y))
		paths.append(row)
	return {"n": n, "paths": paths, "bridges": []}
