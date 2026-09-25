extends Node2D

# script base das salas de biologia (Estufa)

func _ready() -> void:
	if get_node_or_null("/root/DatabaseManager"):
		DatabaseManager.active_dungeon = "Biologia"
	if get_node_or_null("/root/DungeonGenerator"):
		DungeonGenerator.masmorra_retorno_hub = "Biologia"
		
	if get_node_or_null("/root/AudioManager"):
		AudioManager.start_playlist()
