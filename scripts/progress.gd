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


## Daily login bonus: 10 coins on day 1, +5 per consecutive day, capped
## at 40. Missing a day resets the streak.
func daily_bonus_info() -> Dictionary:
	var today := int(Time.get_unix_time_from_system() / 86400.0)
	var last := int(cfg.get_value("wallet", "last_bonus_day", 0))
	if today == last:
		return {}
	var streak := int(cfg.get_value("wallet", "streak", 0))
	streak = streak + 1 if last == today - 1 else 1
	return {"amount": mini(10 + (streak - 1) * 5, 40), "streak": streak}


func claim_daily_bonus() -> Dictionary:
	var info := daily_bonus_info()
	if info.is_empty():
		return {}
	var today := int(Time.get_unix_time_from_system() / 86400.0)
	cfg.set_value("wallet", "last_bonus_day", today)
	cfg.set_value("wallet", "streak", int(info["streak"]))
	cfg.set_value("wallet", "coins", coins() + int(info["amount"]))
	cfg.save(SAVE_PATH)
	return info


# ------------------------------------------------------------------ mascots

const FEED_COST := 10
const FEED_GAIN := 35
const HUNGER_PER_DAY := 20


func owned_mascots() -> Array:
	return cfg.get_value("mascots", "owned", [])


func owns_mascot(kind: String) -> bool:
	return kind in owned_mascots()


func buy_mascot(kind: String, price: int) -> bool:
	if owns_mascot(kind) or not spend_coins(price):
		return false
	var arr := owned_mascots()
	arr.append(kind)
	cfg.set_value("mascots", "owned", arr)
	cfg.set_value("mascots", "fed_" + kind,
			{"value": 70, "at": Time.get_unix_time_from_system()})
	if active_mascot() == "":
		cfg.set_value("mascots", "active", kind)
	cfg.save(SAVE_PATH)
	return true


func active_mascot() -> String:
	return cfg.get_value("mascots", "active", "")


func set_active_mascot(kind: String) -> void:
	if owns_mascot(kind):
		cfg.set_value("mascots", "active", kind)
		cfg.save(SAVE_PATH)


## 0-100, decaying HUNGER_PER_DAY per day since last fed.
func fullness(kind: String) -> int:
	var d: Dictionary = cfg.get_value("mascots", "fed_" + kind, {})
	if d.is_empty():
		return 0
	var days := (Time.get_unix_time_from_system() - float(d["at"])) / 86400.0
	return clampi(int(d["value"]) - int(days * HUNGER_PER_DAY), 0, 100)


func feed_mascot(kind: String) -> bool:
	if not owns_mascot(kind) or fullness(kind) >= 100:
		return false
	if not spend_coins(FEED_COST):
		return false
	cfg.set_value("mascots", "fed_" + kind, {
		"value": clampi(fullness(kind) + FEED_GAIN, 0, 100),
		"at": Time.get_unix_time_from_system()})
	cfg.save(SAVE_PATH)
	return true


func get_setting(key: String, def: Variant) -> Variant:
	return cfg.get_value("settings", key, def)


func set_setting(key: String, value: Variant) -> void:
	cfg.set_value("settings", key, value)
	cfg.save(SAVE_PATH)
