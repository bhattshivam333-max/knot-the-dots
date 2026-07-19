extends Node
## Captures PNG screenshots of each screen for visual review.
## Run (windowed):  godot --path . res://tests/screenshot.tscn -- outdir=/tmp

var outdir := "/tmp"

var _save_backup := PackedByteArray()
var _had_save := false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("outdir="):
			outdir = arg.trim_prefix("outdir=")
	if FileAccess.file_exists("user://progress.cfg"):
		_had_save = true
		_save_backup = FileAccess.get_file_as_bytes("user://progress.cfg")
	for section in ["wallet", "mascots", "levels", "settings"]:
		if Progress.cfg.has_section(section):
			Progress.cfg.erase_section(section)
	await _run()
	if _had_save:
		var f := FileAccess.open("user://progress.cfg", FileAccess.WRITE)
		f.store_buffer(_save_backup)
		f.close()
	else:
		DirAccess.remove_absolute(OS.get_user_data_dir().path_join("progress.cfg"))
	get_tree().quit()


func _shot(name: String) -> void:
	await get_tree().create_timer(0.7).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(outdir.path_join(name + ".png"))
	print("saved " + name)


func _run() -> void:
	var main: Control = load("res://main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().process_frame
	await get_tree().process_frame

	await _shot("1_menu")

	main.show_select()
	await get_tree().process_frame
	await _shot("2_select")

	Progress.add_coins(300)
	Progress.buy_mascot("fox", 100)
	Progress.buy_mascot("frog", 150)
	main.show_store()
	await get_tree().process_frame
	await _shot("6_store")

	main.show_game(0, 2)
	await get_tree().process_frame
	var gs: GameScreen = main.current
	var board: Board = gs.board
	# Draw two full lines and one partial so the shot shows gameplay.
	for c in mini(2, board.solution.size()):
		var sol: Array = board.solution[c]
		board._press(sol[0])
		for k in range(1, sol.size()):
			board._drag_to(sol[k])
		board._release()
	if board.solution.size() > 2:
		var sol: Array = board.solution[2]
		board._press(sol[0])
		for k in range(1, sol.size() / 2 + 1):
			board._drag_to(sol[k])
		board._release()
	await _shot("3_game")

	# Finish the level to capture the win overlay.
	for c in board.solution.size():
		var sol: Array = board.solution[c]
		board._press(sol[0])
		for k in range(1, sol.size()):
			board._drag_to(sol[k])
		board._release()
	await get_tree().create_timer(1.4).timeout
	await _shot("4_win")

	main.show_game(5, 0)
	await get_tree().process_frame
	gs = main.current
	board = gs.board
	for c in mini(3, board.solution.size()):
		var sol: Array = board.solution[c]
		board._press(sol[0])
		for k in range(1, sol.size()):
			board._drag_to(sol[k])
		board._release()
	await _shot("5_bridges")
