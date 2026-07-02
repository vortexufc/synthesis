extends Node

# Cena base para SFX (deve ser AudioStreamPlayer na raiz)
var audio_scene = preload("res://scenes/audio.tscn")

# Player único de música (persistente)
var music_player: AudioStreamPlayer

# Controle da música atual
var current_music: AudioStream = null
var previous_music: AudioStream = null

# Dicionário de SFX
var sfx = {
	"ui-1": preload("res://assets/audio/sfx/ui-1.wav"),
	"ui-2": preload("res://assets/audio/sfx/ui-2.wav"),
	"ui-3": preload("res://assets/audio/sfx/ui-3.wav"),
	"transicao-1": preload("res://assets/audio/sfx/transicao-1.wav")
}

func _ready():
	# cria player de música persistente
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

# SFX (efeitos sonoros)
func play_sfx(audio: String) -> void:
	if not sfx.has(audio):
		push_error("SFX não encontrado: " + audio)
		return

	var player := AudioStreamPlayer.new()

	player.stream = sfx[audio]
	player.bus = "SFX"
	add_child(player)

	player.play()

	player.finished.connect(func():
		player.queue_free()
	)

# MÚSICA (BGM contínua)
func play_music(music: AudioStream) -> void:
	if music == null:
		push_error("Tentou tocar música nula")
		return

	# se já está tocando a mesma música, não reinicia
	if current_music == music and music_player.playing:
		return

	current_music = music
	music_player.stream = music
	music_player.play()
	
func play_battle_music(battle_music: AudioStream) -> void:
	previous_music = current_music
	play_music(battle_music)

func restore_previous_music() -> void:
	if previous_music:
		play_music(previous_music)
