extends Node2D

# script do corredor de física

func _ready() -> void:
	if get_node_or_null("/root/DatabaseManager"):
		DatabaseManager.active_dungeon = "Física"
	if get_node_or_null("/root/DungeonGenerator"):
		DungeonGenerator.masmorra_retorno_hub = "Física"
		
	if get_node_or_null("/root/AudioManager"):
		AudioManager.start_playlist()
