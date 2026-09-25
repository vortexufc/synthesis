extends Node

# cena base pros efeitos sonoros
var audio_scene = preload("res://scenes/Mecanicas/audio.tscn")

# toca as musicas
var music_player: AudioStreamPlayer
var battle_player: AudioStreamPlayer

# controle da musica atual
var current_music: AudioStream = null
var previous_music: AudioStream = null

# som dos passos
var pode_tocar_passo := true

# sons de dano
var pode_tocar_dano := true
var pode_tocar_ataque := true

# musica do mapa
var musica_atual := -1
var music_state = MusicState.MENU
const MUSIC_FADE_TIME := 1.0

# lista de efeitos sonoros
var sfx = {
	"ui-1": preload("res://assets/audio/sfx/ui-1.wav"),
	"ui-2": preload("res://assets/audio/sfx/ui-2.wav"),
	"ui-3": preload("res://assets/audio/sfx/ui-3.wav"),
	"ui_1": preload("res://assets/audio/sfx/ui_1.wav"),
	"ui_2": preload("res://assets/audio/sfx/ui_2.wav"),
	"ui_3": preload("res://assets/audio/sfx/ui_3.wav"),
	"ui_4": preload("res://assets/audio/sfx/ui_4.wav"),
	"ui_5": preload("res://assets/audio/sfx/ui_5.wav"),
	"ui_6": preload("res://assets/audio/sfx/ui_6.wav"),
	"acerto_1": preload("res://assets/audio/sfx/acerto_1.wav"),
	"acerto_2": preload("res://assets/audio/sfx/acerto_2.wav"),
	"acerto_3": preload("res://assets/audio/sfx/acerto_3.wav"),
	"win": preload("res://assets/audio/sfx/win.wav"),
	"fail": preload("res://assets/audio/sfx/fail.wav"),
	"erro_1": preload("res://assets/audio/sfx/fail.wav"),
	"erro": preload("res://assets/audio/sfx/fail.wav"),
	"transicao-1": preload("res://assets/audio/sfx/transicao-1.wav"),
	"moedas": preload("res://assets/audio/sfx/acerto_1.wav"),
	"moeda": preload("res://assets/audio/sfx/acerto_1.wav")
}

# sons de passos
var sfx_caminhar = [
	preload("res://assets/audio/sfx/passo_pedra_1.wav"),
	preload("res://assets/audio/sfx/passo_pedra_2.wav")
]

# sons quando toma dano
var sfx_tomar_dano = [
	preload("res://assets/audio/sfx/dano_1.wav"),
	preload("res://assets/audio/sfx/dano_2.wav"),
	preload("res://assets/audio/sfx/dano_3.wav"),
	preload("res://assets/audio/sfx/dano_4.wav")
]

# sons de ataque
var sfx_atacar = [
	preload("res://assets/audio/sfx/ataque_1.wav"),
	preload("res://assets/audio/sfx/ataque_2.wav"),
	preload("res://assets/audio/sfx/ataque_3.wav")
]

# musicas de fundo
var playlist = [
	preload("res://assets/audio/ost/1.wav"),
	preload("res://assets/audio/ost/3.wav"),
	preload("res://assets/audio/ost/4.wav")
]

enum MusicState {
	MENU,
	EXPLORACAO,
	BATALHA
}

func _ready():
	# cria o player de musica
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	
	battle_player = AudioStreamPlayer.new()
	battle_player.bus = "Music"
	add_child(battle_player)
	
	music_player.finished.connect(_on_music_finished)
	music_player.volume_db = 0
	battle_player.volume_db = 0

func _input(event: InputEvent) -> void:
	if OS.has_feature("web"):
		if event is InputEventMouseButton or event is InputEventKey:
			if music_state == MusicState.MENU and music_player and not music_player.playing:
				play_menu_music()

# toca efeito sonoro
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

# toca musica de fundo
func play_music(music: AudioStream) -> void:
	if music == null:
		push_error("Tentou tocar música nula")
		return

	if current_music == music and music_player.playing:
		return

	current_music = music

	if music_player.playing:
		var tween_fade = create_tween()

		tween_fade.tween_property(music_player, "volume_db", -40.0, MUSIC_FADE_TIME)

		await tween_fade.finished

	music_player.stream = music
	music_player.volume_db = -40.0
	music_player.play()

	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", 0.0, MUSIC_FADE_TIME)

func play_menu_music():
	music_state = MusicState.MENU
	play_music(preload("res://assets/audio/ost/5.wav"))

func start_playlist():
	if music_state == MusicState.EXPLORACAO:
		return

	music_state = MusicState.EXPLORACAO
	play_random_music()

func play_random_music():
	if playlist.is_empty():
		return

	var indice = randi() % playlist.size()

	while indice == musica_atual and playlist.size() > 1:
		indice = randi() % playlist.size()

	musica_atual = indice
	play_music(playlist[indice])

func _on_music_finished():
	play_random_music()

func play_battle_music(battle_music: AudioStream):
	if battle_player.playing:
		return

	music_state = MusicState.BATALHA

	music_player.stream_paused = true

	battle_player.stream = battle_music
	battle_player.play()

func restore_previous_music():
	if battle_player.playing:
		battle_player.stop()

	music_state = MusicState.EXPLORACAO

	music_player.stream_paused = false

func stop_battle_music():
	if battle_player.playing:
		battle_player.stop()

func tocar_som_caminhada():
	if !pode_tocar_passo:
		return

	pode_tocar_passo = false

	var player := AudioStreamPlayer.new()
	player.stream = sfx_caminhar.pick_random()
	player.bus = "SFX"
	add_child(player)

	player.play()

	player.finished.connect(func():
		player.queue_free()
	)

	get_tree().create_timer(0.28).timeout.connect(func():
		pode_tocar_passo = true
	)

func tocar_som_dano():
	if !pode_tocar_dano:
		return

	pode_tocar_dano = false

	var player := AudioStreamPlayer.new()
	player.stream = sfx_tomar_dano.pick_random()
	player.bus = "SFX"
	add_child(player)

	player.play()

	player.finished.connect(func():
		player.queue_free()
	)
	
	await get_tree().create_timer(0.28).timeout
	pode_tocar_dano = true
	
func tocar_som_ataque():
	if !pode_tocar_ataque:
		return

	pode_tocar_ataque = false

	var player := AudioStreamPlayer.new()
	player.stream = sfx_atacar.pick_random()
	player.bus = "SFX"
	add_child(player)

	player.play()

	player.finished.connect(func():
		player.queue_free()
	)
	
	await get_tree().create_timer(0.28).timeout
	pode_tocar_ataque = true
	
