extends Node
## Autoload "Sfx": tiny pooled sound player.

const NAMES := ["click", "pop", "cut", "connect", "win"]

var streams := {}
var players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for n in NAMES:
		var path := "res://assets/sfx/%s.wav" % n
		if ResourceLoader.exists(path):
			streams[n] = load(path)
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		players.append(p)


func play(name: String, volume_db := 0.0) -> void:
	if not streams.has(name):
		return
	if not Progress.get_setting("sound", true):
		return
	for p in players:
		if not p.playing:
			p.stream = streams[name]
			p.pitch_scale = randf_range(0.96, 1.04)
			p.volume_db = volume_db
			p.play()
			return
