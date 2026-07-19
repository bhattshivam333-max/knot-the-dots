class_name Zones
## Terrain zones of the level map. The map's terrain bands and the gameplay
## screen both derive a level's zone from here, so the critter you meet on
## the map is the one that accompanies you in that level.

const STEP := 104.0

const ZONES := [
	{"name": "Meadow", "critter": "fox", "pet": "Pip", "price": 100},
	{"name": "Lake", "critter": "frog", "pet": "Momo", "price": 150},
	{"name": "Violet Hills", "critter": "owl", "pet": "Luna", "price": 200},
	{"name": "Desert", "critter": "cactus", "pet": "Spike", "price": 250},
	{"name": "Teal Forest", "critter": "firefly", "pet": "Glow", "price": 300},
	{"name": "Rose Canyon", "critter": "bat", "pet": "Echo", "price": 350},
]


static func map_height(count: int) -> float:
	return count * STEP + 170.0


## Y of level node i on the map (the road runs bottom to top).
static func level_y(count: int, i: int) -> float:
	return map_height(count) - 100.0 - i * STEP


## Terrain bands from top to bottom: [{top, band}]. Deterministic per pack;
## the map painter uses the same sequence.
static func band_rows(pack_idx: int, h_total: float) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242 + pack_idx * 77
	var rows: Array = []
	var y := -60.0
	var bi := pack_idx
	while y < h_total:
		rows.append({"top": y, "band": bi})
		y += 340.0 + rng.randf() * 160.0
		bi += 1
	return rows


static func zone_of_level(pack_idx: int, level_idx: int, count: int) -> int:
	var yl := level_y(count, level_idx)
	var rows := band_rows(pack_idx, map_height(count))
	var band: int = rows[0]["band"]
	for row in rows:
		if row["top"] <= yl:
			band = row["band"]
	return band % ZONES.size()


static func zone_for_daily(date: Dictionary) -> int:
	return Levels.daily_seed(date) % ZONES.size()
