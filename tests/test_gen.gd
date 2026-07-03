extends SceneTree
## Headless validation: every level in every pack (plus 30 daily puzzles)
## must fully tile the grid with valid non-crossing paths.
## Run:  godot --headless --path . -s res://tests/test_gen.gd


func _init() -> void:
	var fails := 0
	var t0 := Time.get_ticks_msec()

	for pi in Levels.PACKS.size():
		var pack: Dictionary = Levels.PACKS[pi]
		for li in int(pack["count"]):
			var lv := Levels.get_level(pi, li)
			var err := _validate(lv, bool(pack["bridges"]))
			if err != "":
				print("FAIL pack %d level %d: %s" % [pi, li, err])
				fails += 1

	for d in 30:
		var date := {"year": 2026, "month": 7, "day": 1 + d, "weekday": (d + 3) % 7}
		var lv := Levels.daily_level(date)
		var err := _validate(lv, true)
		if err != "":
			print("FAIL daily %d: %s" % [d + 1, err])
			fails += 1

	var packs_total := 0
	for p in Levels.PACKS:
		packs_total += int(p["count"])
	print("Validated %d levels + 30 dailies in %d ms, failures: %d" % [
		packs_total, Time.get_ticks_msec() - t0, fails])
	quit(1 if fails > 0 else 0)


func _validate(lv: Dictionary, allow_bridges: bool) -> String:
	var n: int = lv["n"]
	var bridges := {}
	for b in lv["bridges"]:
		bridges[b] = true
	if not allow_bridges and not bridges.is_empty():
		return "unexpected bridges"
	if lv["paths"].size() > Levels.PALETTE.size():
		return "too many colors (%d)" % lv["paths"].size()

	var cover := {}
	for path in lv["paths"]:
		if path.size() < 3:
			return "path too short (%d)" % path.size()
		var seen := {}
		for k in path.size():
			var c: Vector2i = path[k]
			if c.x < 0 or c.y < 0 or c.x >= n or c.y >= n:
				return "cell out of bounds %s" % c
			if seen.has(c):
				return "path revisits %s" % c
			seen[c] = true
			if k > 0:
				var d: Vector2i = (path[k] - path[k - 1]).abs()
				if d.x + d.y != 1:
					return "path not contiguous at %s" % c
			cover[c] = cover.get(c, 0) + 1
		if bridges.has(path[0]) or bridges.has(path.back()):
			return "dot placed on a bridge"

	for y in n:
		for x in n:
			var c := Vector2i(x, y)
			var cnt: int = cover.get(c, 0)
			if bridges.has(c):
				if cnt != 2:
					return "bridge %s covered %d times (want 2)" % [c, cnt]
			elif cnt != 1:
				return "cell %s covered %d times (want 1)" % [c, cnt]
	return ""
