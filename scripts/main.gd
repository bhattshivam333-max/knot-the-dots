extends Control
## Root node: swaps between the menu / level-select / game screens
## and handles the Android back button.

var current: Control = null


func _ready() -> void:
	var bg := BgFx.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	show_menu()


func _swap(screen: Control) -> void:
	if is_instance_valid(current):
		current.queue_free()
	current = screen
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.modulate.a = 0.0
	create_tween().tween_property(screen, "modulate:a", 1.0, 0.18)


func show_menu() -> void:
	var s := MenuScreen.new()
	s.main = self
	_swap(s)


func show_select() -> void:
	var s := SelectScreen.new()
	s.main = self
	_swap(s)


func show_game(pack_idx: int, level_idx: int) -> void:
	var s := GameScreen.new()
	s.main = self
	s.pack_idx = pack_idx
	s.level_idx = level_idx
	_swap(s)


func show_daily() -> void:
	var s := GameScreen.new()
	s.main = self
	s.is_daily = true
	_swap(s)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if current is GameScreen:
			show_select()
		elif current is SelectScreen:
			show_menu()
		else:
			get_tree().quit()
