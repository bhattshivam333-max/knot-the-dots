class_name Levels
## Level pack definitions and the shared color palette.

const PALETTE: Array[Color] = [
	Color("#ff4d57"), # red
	Color("#31d287"), # green
	Color("#3f8cff"), # blue
	Color("#ffd93d"), # yellow
	Color("#ff8b3d"), # orange
	Color("#2fd6e8"), # cyan
	Color("#e05bff"), # magenta
	Color("#a4e846"), # lime
	Color("#8b5bff"), # purple
	Color("#ff5bb0"), # pink
	Color("#c9a06a"), # tan
	Color("#7ef0c9"), # mint
	Color("#f0f0f5"), # white
	Color("#9aa5b8"), # gray
	Color("#b03a48"), # maroon
	Color("#0aa574"), # teal
]

const PACKS := [
	{"name": "Beginner", "size": 5, "count": 40, "seed": 1000, "bridges": false},
	{"name": "Classic", "size": 6, "count": 40, "seed": 2000, "bridges": false},
	{"name": "Advanced", "size": 7, "count": 40, "seed": 3000, "bridges": false},
	{"name": "Expert", "size": 8, "count": 40, "seed": 4000, "bridges": false},
	{"name": "Master", "size": 9, "count": 40, "seed": 5000, "bridges": false},
	{"name": "Bridges", "size": 7, "count": 40, "seed": 6000, "bridges": true},
]


static func get_level(pack_idx: int, level_idx: int) -> Dictionary:
	var p: Dictionary = PACKS[pack_idx]
	return LevelGen.generate(int(p["size"]), int(p["seed"]) + level_idx, bool(p["bridges"]))


static func level_id(pack_idx: int, level_idx: int) -> String:
	return "p%d_%d" % [pack_idx, level_idx]


static func daily_seed(date: Dictionary) -> int:
	return int(date["year"]) * 10000 + int(date["month"]) * 100 + int(date["day"])


static func daily_id(date: Dictionary) -> String:
	return "d%d" % daily_seed(date)


static func daily_level(date: Dictionary) -> Dictionary:
	var n := 6 + (int(date["day"]) % 3)
	var with_bridges := int(date.get("weekday", 1)) == 0 # Sundays get bridges
	return LevelGen.generate(n, 990000 + daily_seed(date), with_bridges)
