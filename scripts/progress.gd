extends Node
## Autoload "Progress": persistent save data (level results + settings).

const SAVE_PATH := "user://progress.cfg"

var cfg := ConfigFile.new()


func _ready() -> void:
	cfg.load(SAVE_PATH)


func stars(id: String) -> int:
	return int(cfg.get_value("levels", id, 0))


func is_completed(id: String) -> bool:
	return stars(id) > 0


func record(id: String, s: int) -> void:
	if s > stars(id):
		cfg.set_value("levels", id, s)
		cfg.save(SAVE_PATH)


func completed_count(pack_idx: int) -> int:
	var c := 0
	for i in int(Levels.PACKS[pack_idx]["count"]):
		if is_completed(Levels.level_id(pack_idx, i)):
			c += 1
	return c


func pack_unlocked(pack_idx: int) -> bool:
	return pack_idx == 0 or completed_count(pack_idx - 1) >= 5


## First not-yet-completed level, for the Play button.
func next_unfinished() -> Dictionary:
	for pi in Levels.PACKS.size():
		if not pack_unlocked(pi):
			continue
		for li in int(Levels.PACKS[pi]["count"]):
			if not is_completed(Levels.level_id(pi, li)):
				return {"pack": pi, "level": li}
	return {}


func total_completed() -> int:
	var c := 0
	for pi in Levels.PACKS.size():
		c += completed_count(pi)
	return c


func coins() -> int:
	return int(cfg.get_value("wallet", "coins", 30))


func add_coins(n: int) -> void:
	cfg.set_value("wallet", "coins", coins() + n)
	cfg.save(SAVE_PATH)


func spend_coins(n: int) -> bool:
	if coins() < n:
		return false
	cfg.set_value("wallet", "coins", coins() - n)
	cfg.save(SAVE_PATH)
	return true


func get_setting(key: String, def: Variant) -> Variant:
	return cfg.get_value("settings", key, def)


func set_setting(key: String, value: Variant) -> void:
	cfg.set_value("settings", key, value)
	cfg.save(SAVE_PATH)
