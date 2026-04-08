extends Node

var audio_scene = preload("res://scenes/audio.tscn")

var sfx = {
	"ui-1": preload("res://assets/audio/sfx/ui-1.wav"),
	"ui-2": preload("res://assets/audio/sfx/ui-2.wav"),
	"ui-3": preload("res://assets/audio/sfx/ui-3.wav")
}


func play_sfx(audio):
	var audio_instance = audio_scene.instantiate()
	audio_instance.stream = sfx[audio]
	add_child(audio_instance)
