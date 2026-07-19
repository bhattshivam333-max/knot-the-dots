extends Node
## Headless end-to-end test: navigates screens and plays levels through the
## Board's input pipeline. Run:
##   godot --headless --path . res://tests/test_play.tscn

var fails := 0


func _ready() -> void:
	await _run()
	# Don't leave test results in the player's save file.
	DirAccess.remove_absolute(OS.get_user_data_dir().path_join("progress.cfg"))
	get_tree().quit(1 if fails > 0 else 0)


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok - " + what)
	else:
		fails += 1
		print("  FAIL - " + what)


func _draw_solution(board: Board, c: int) -> void:
	var sol: Array = board.solution[c]
	board._press(sol[0])
	for k in range(1, sol.size()):
		board._drag_to(sol[k])
	board._release()


func _run() -> void:
	var main: Control = load("res://main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().process_frame
	await get_tree().process_frame

	print("menu screen")
	_check(main.current is MenuScreen, "menu builds")

	print("daily login bonus")
	var info: Dictionary = Progress.daily_bonus_info()
	_check(not info.is_empty() and int(info["amount"]) >= 10, "bonus available on first launch")
	var wallet_before: int = Progress.coins()
	var claimed: Dictionary = Progress.claim_daily_bonus()
	_check(Progress.coins() == wallet_before + int(claimed["amount"]), "bonus pays coins")
	_check(Progress.daily_bonus_info().is_empty(), "bonus claimable once per day")

	print("select screen")
	main.show_select()
	await get_tree().process_frame
	_check(main.current is SelectScreen, "select builds")

	print("zones map every level to a valid critter")
	var zones_ok := true
	for pi in Levels.PACKS.size():
		for li in int(Levels.PACKS[pi]["count"]):
			var z := Zones.zone_of_level(pi, li, int(Levels.PACKS[pi]["count"]))
			if z < 0 or z >= Zones.ZONES.size():
				zones_ok = false
	_check(zones_ok, "zone_of_level in range for all 240 levels")

	print("solve level 1 by drawing each solution path")
	main.show_game(0, 0)
	await get_tree().process_frame
	var gs: GameScreen = main.current
	var board: Board = gs.board
	_check(board.solution.size() >= 3, "level has flows")
	_check(gs.time_left > 0.0, "timer is running")

	var coins_before: int = Progress.coins()
	for c in board.solution.size():
		_draw_solution(board, c)
	_check(board.done_count() == board.solution.size(), "all pairs connected")
	_check(board.coverage() == 1.0, "board fully covered")
	_check(board.locked, "win detected")
	_check(gs._stars_for_time() == 3, "fast solve earns 3 stars")
	await get_tree().create_timer(0.8).timeout
	_check(is_instance_valid(gs._overlay), "win overlay appears")
	_check(Progress.coins() > coins_before, "win pays coins")

	print("undo restores the previous state")
	main.show_game(0, 1)
	await get_tree().process_frame
	gs = main.current
	board = gs.board
	_draw_solution(board, 0)
	_check(board.paths[0].size() > 1, "path drawn")
	_check(board.can_undo(), "undo available")
	board.undo()
	_check(board.paths[0].is_empty(), "undo cleared the drawn path")

	print("cutting: drawing across another line severs it")
	var sol0: Array = board.solution[0]
	_draw_solution(board, 0)
	var len_before: int = board.paths[0].size()
	# Find a non-dot cell of line 0 with a neighbor belonging to another
	# color's solution, then walk that color up to it and step across.
	var found := false
	for vi in range(1, sol0.size() - 1):
		var victim: Vector2i = sol0[vi]
		for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nb: Vector2i = victim + dir
			if sol0.has(nb) or board.dots.has(nb):
				continue
			for d in range(1, board.solution.size()):
				var sd: Array = board.solution[d]
				var k: int = sd.find(nb)
				if k == -1:
					continue
				board._press(sd[0])
				for step in range(1, k + 1):
					board._try_step(d, sd[step])
				board._try_step(d, victim)
				board._release()
				found = true
				break
			if found:
				break
		if found:
			break
	_check(found, "found a place to cross lines")
	_check(board.paths[0].size() < len_before, "crossed line was cut")
	_check(not board.completed[0], "cut line no longer complete")

	print("hints solve the level")
	board.restart()
	for i in board.solution.size():
		board.apply_hint()
	_check(board.locked, "hints finish the level")

	print("hint button spends coins")
	main.show_game(0, 2)
	await get_tree().process_frame
	gs = main.current
	board = gs.board
	coins_before = Progress.coins()
	gs._on_hint()
	_check(Progress.coins() == coins_before - GameScreen.HINT_COST, "hint costs coins")
	_check(board.done_count() == 1, "hint drew one flow")

	print("pause freezes the board")
	gs._on_pause()
	_check(board.frozen, "board frozen while paused")
	_check(is_instance_valid(gs._overlay), "pause overlay appears")

	print("time up shows lose overlay")
	main.show_game(0, 3)
	await get_tree().process_frame
	gs = main.current
	gs.time_left = 0.01
	await get_tree().create_timer(0.2).timeout
	_check(gs.ended, "time up ends the level")
	_check(gs.board.frozen, "board frozen after time up")
	_check(is_instance_valid(gs._overlay), "lose overlay appears")

	print("bridge pack level solves the same way")
	main.show_game(5, 0)
	await get_tree().process_frame
	gs = main.current
	board = gs.board
	_check(not board.bridge_cells.is_empty(), "bridge level has bridges")
	for c in board.solution.size():
		_draw_solution(board, c)
	_check(board.locked, "bridge level won")

	print("daily puzzle screen")
	main.show_daily()
	await get_tree().process_frame
	_check(main.current is GameScreen and (main.current as GameScreen).is_daily, "daily builds")

	print("done: %d failures" % fails)
