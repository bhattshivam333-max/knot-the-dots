extends Node
## Autoload "Sfx": pooled sound player + looping background music.

const NAMES := ["click", "pop", "cut", "connect", "win", "lose"]

var streams := {}
var players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer


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

	var music_path := "res://assets/sfx/music.wav"
	if ResourceLoader.exists(music_path):
		var stream: AudioStreamWAV = load(music_path)
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.data.size() / 2 # 16-bit mono frames
		music_player = AudioStreamPlayer.new()
		music_player.stream = stream
		music_player.volume_db = -16.0
		music_player.bus = "Master"
		add_child(music_player)
		if Progress.get_setting("music", true):
			music_player.play()


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


func set_music(on: bool) -> void:
	Progress.set_setting("music", on)
	if music_player == null:
		return
	if on and not music_player.playing:
		music_player.play()
	elif not on:
		music_player.stop()
