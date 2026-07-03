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


func _run() -> void:
	var main: Control = load("res://main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().process_frame
	await get_tree().process_frame

	print("menu screen")
	_check(main.current is MenuScreen, "menu builds")

	print("select screen")
	main.show_select()
	await get_tree().process_frame
	_check(main.current is SelectScreen, "select builds")

	print("solve level 1 by drawing each solution path")
	main.show_game(0, 0)
	await get_tree().process_frame
	var gs: GameScreen = main.current
	var board: Board = gs.board
	_check(board.solution.size() >= 3, "level has flows")

	for c in board.solution.size():
		var sol: Array = board.solution[c]
		board._press(sol[0])
		for k in range(1, sol.size()):
			board._drag_to(sol[k])
		board._release()
	_check(board.done_count() == board.solution.size(), "all pairs connected")
	_check(board.coverage() == 1.0, "board fully covered")
	_check(board.locked, "win detected")
	_check(board.moves == board.solution.size(), "perfect move count")
	_check(board.stars_earned() == 3, "3 stars")
	await get_tree().create_timer(0.8).timeout
	_check(is_instance_valid(gs._win_layer), "win overlay appears")

	print("cutting: drawing across another line severs it")
	main.show_game(0, 1)
	await get_tree().process_frame
	gs = main.current
	board = gs.board
	var sol0: Array = board.solution[0]
	board._press(sol0[0])
	for k in range(1, sol0.size()):
		board._drag_to(sol0[k])
	board._release()
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
	_check(board.stars_earned() == 1, "hint caps stars at 1")

	print("bridge pack level solves the same way")
	main.show_game(5, 0)
	await get_tree().process_frame
	gs = main.current
	board = gs.board
	_check(not board.bridge_cells.is_empty(), "bridge level has bridges")
	for c in board.solution.size():
		var sol: Array = board.solution[c]
		board._press(sol[0])
		for k in range(1, sol.size()):
			board._drag_to(sol[k])
		board._release()
	_check(board.locked, "bridge level won")

	print("daily puzzle screen")
	main.show_daily()
	await get_tree().process_frame
	_check(main.current is GameScreen and (main.current as GameScreen).is_daily, "daily builds")

	print("done: %d failures" % fails)
