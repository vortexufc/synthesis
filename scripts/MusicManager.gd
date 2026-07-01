extends Node # Autoloads de script puro precisam herdar de Node no Godot

# Variável para controlar o player de áudio que vamos criar via código
var audio_player: AudioStreamPlayer

func _ready() -> void:
	# 1. Instancia o player de áudio dinamicamente na memória
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player) # Adiciona ele como filho desse nó global
	
	# 2. Carrega a trilha do menu
	var som = load("res://audio/synthesis - menu theme.wav")
	if som:
		audio_player.stream = som
		audio_player.play()
		print("Música do menu iniciada dinamicamente com sucesso!")
	else:
		print("AVISO: Arquivo 'synthesis - menu theme.wav' não foi encontrado no caminho especificado.")

func parar_musica_menu() -> void:
	# Verifica com segurança se o player existe e se está tocando
	if audio_player and audio_player.playing:
		audio_player.stop()
		print("Música do menu parada!")
