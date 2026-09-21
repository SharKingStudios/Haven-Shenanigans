extends Node

# Signal-driven sound controller, based on the reference project's event hookup pattern.
# It synthesizes original chirpy tones at runtime; no borrowed recordings are used.
var beat_time := 0.0
var beat_step := 0

func _ready() -> void:
	get_tree().node_added.connect(_try_connect)
	for node in get_tree().get_nodes_in_group("runner"): _try_connect(node)

func _try_connect(node: Node) -> void:
	if node.has_signal("jumped") and not node.is_connected("jumped", Callable(self, "play_jump")): node.connect("jumped", Callable(self, "play_jump"))
	if node.has_signal("double_jumped") and not node.is_connected("double_jumped", Callable(self, "play_double_jump")): node.connect("double_jumped", Callable(self, "play_double_jump"))
	if node.has_signal("landed") and not node.is_connected("landed", Callable(self, "play_land")): node.connect("landed", Callable(self, "play_land"))

func play_ui() -> void: _play_notes([660.0, 990.0], 0.10, 0.16)
func play_jump() -> void: _play_notes([392.0, 587.0], 0.16, 0.18)
func play_double_jump() -> void: _play_notes([523.0, 784.0, 1046.0], 0.19, 0.15)
func play_land() -> void: _play_notes([220.0, 330.0], 0.09, 0.11)
func play_hurt() -> void: _play_notes([280.0, 180.0], 0.26, 0.2)
func play_win() -> void: _play_notes([523.0, 659.0, 784.0, 1046.0], 0.42, 0.18)

func _play_notes(notes: Array, seconds: float, volume: float) -> void:
	for i in notes.size():
		var player := AudioStreamPlayer.new()
		player.stream = _tone(float(notes[i]), seconds, volume / maxf(1.0, notes.size() * 0.65), i * 0.035)
		add_child(player); player.finished.connect(player.queue_free); player.play()

func _tone(freq: float, seconds: float, volume: float, silence := 0.0) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * (seconds + silence))
	var data := PackedByteArray(); data.resize(count * 2)
	for n in count:
		var t := float(n) / rate
		var env := 0.0 if t < silence else exp(-(t - silence) * 11.0)
		var wave := sin(TAU * freq * t) * 0.72 + sin(TAU * freq * 2.01 * t) * 0.28
		data.encode_s16(n * 2, int(clampf(wave * env * volume, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate = rate; stream.data = data
	return stream

func _process(delta: float) -> void:
	beat_time += delta
	if beat_time > 0.29:
		beat_time = 0.0
		var scale := [392.0, 494.0, 587.0, 659.0, 587.0, 494.0, 440.0, 523.0]
		_play_notes([scale[beat_step % scale.size()]], 0.20, 0.045); beat_step += 1
