class_name StoreScreen
extends Control
## Mascot store: adopt the six zone critters with coins, keep them fed
## (fullness decays daily) and pick which one hangs out on the menu.

var main: Node

var _coin_chip: UI.CoinChip
var _cards: VBoxContainer


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	margin.add_theme_constant_override("margin_top", 56)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var top := HBoxContainer.new()
	box.add_child(top)
	var back := UI.icon_button("‹")
	back.pressed.connect(func() -> void:
		Sfx.play("click")
		main.show_menu())
	top.add_child(back)
	var title := UI.label("MASCOTS", 17, UI.TEXT_SOFT, UI.fredoka(600, 2))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(title)
	_coin_chip = UI.CoinChip.new(Progress.coins(), true)
	top.add_child(_coin_chip)

	box.add_child(UI.label("Adopt a buddy and keep it fed!", 13, UI.TEXT_DIM))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	_cards = VBoxContainer.new()
	_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards.add_theme_constant_override("separation", 12)
	scroll.add_child(_cards)

	for z in Zones.ZONES:
		_cards.add_child(_card(z))


func _card(z: Dictionary) -> Control:
	var kind: String = z["critter"]

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.05)
	sb.set_corner_radius_all(20)
	sb.set_border_width_all(1)
	sb.border_color = UI.CHIP_BORDER
	sb.content_margin_left = 12.0
	sb.content_margin_right = 14.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", sb)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	var portrait := Control.new()
	portrait.custom_minimum_size = Vector2(84, 100)
	var critter := Critter.new(kind)
	critter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	critter.hungry = Progress.owns_mascot(kind) and Progress.fullness(kind) < 35
	portrait.add_child(critter)
	row.add_child(portrait)

	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", 4)
	row.add_child(mid)
	mid.add_child(UI.label(z["pet"], 17, UI.TEXT, UI.fredoka(650), HORIZONTAL_ALIGNMENT_LEFT))
	mid.add_child(UI.label("%s - %s" % [z["name"], kind.capitalize()], 11,
			UI.TEXT_DIM, UI.nunito(700), HORIZONTAL_ALIGNMENT_LEFT))

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 12)
	bar.max_value = 100.0
	bar.show_percentage = false
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = Color(0, 0, 0, 0.35)
	bg_sb.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("background", bg_sb)
	var fill_sb := StyleBoxFlat.new()
	fill_sb.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("fill", fill_sb)
	mid.add_child(bar)
	var status := UI.label("", 10, UI.TEXT_DIM, UI.fredoka(600, 1), HORIZONTAL_ALIGNMENT_LEFT)
	mid.add_child(status)

	var buttons := VBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 8)
	row.add_child(buttons)

	var buy := UI.chunky_button("%d" % int(z["price"]), 14, "gold")
	(buy as UI.ChunkyButton).edge = 4.0
	(buy as UI.ChunkyButton).radius = 14.0
	buy.custom_minimum_size = Vector2(96, 42)
	buttons.add_child(buy)

	var feed := UI.chunky_button("FEED %d" % Progress.FEED_COST, 12, "green")
	(feed as UI.ChunkyButton).edge = 4.0
	(feed as UI.ChunkyButton).radius = 14.0
	feed.custom_minimum_size = Vector2(96, 40)
	buttons.add_child(feed)

	var select := UI.chunky_button("SELECT", 12, "purple")
	(select as UI.ChunkyButton).edge = 4.0
	(select as UI.ChunkyButton).radius = 14.0
	select.custom_minimum_size = Vector2(96, 38)
	buttons.add_child(select)

	var refresh := func() -> void:
		var owned := Progress.owns_mascot(kind)
		var full := Progress.fullness(kind)
		critter.hungry = owned and full < 35
		buy.visible = not owned
		feed.visible = owned
		select.visible = owned
		bar.visible = owned
		status.visible = owned
		bar.value = full
		fill_sb.bg_color = UI.GREEN if full >= 35 else Color("#ffb14d")
		if owned:
			status.text = "FULL" if full >= 100 else ("HAPPY" if full >= 35 else "HUNGRY!")
			feed.disabled = full >= 100
			var is_active := Progress.active_mascot() == kind
			select.text = "ACTIVE" if is_active else "SELECT"
			select.disabled = is_active
		else:
			buy.disabled = Progress.coins() < int(z["price"])
		_coin_chip.set_amount(Progress.coins())

	buy.pressed.connect(func() -> void:
		if Progress.buy_mascot(kind, int(z["price"])):
			Sfx.play("win")
			critter.feed_burst()
			_refresh_all()
		else:
			Sfx.play("cut"))

	feed.pressed.connect(func() -> void:
		if Progress.feed_mascot(kind):
			Sfx.play("connect")
			critter.feed_burst()
			refresh.call()
		else:
			Sfx.play("cut"))

	select.pressed.connect(func() -> void:
		Sfx.play("click")
		Progress.set_active_mascot(kind)
		_refresh_all())

	panel.set_meta("refresh", refresh)
	refresh.call()
	return panel


func _refresh_all() -> void:
	for card in _cards.get_children():
		if card.has_meta("refresh"):
			(card.get_meta("refresh") as Callable).call()
