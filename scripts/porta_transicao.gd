extends Area2D

@export var proxima_cena: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		var cena_alvo = proxima_cena
		
		# [Level-4] Se nenhuma cena foi definida no Editor, puxa do Gerador de Masmorra
		if cena_alvo == "" and get_node_or_null("/root/DungeonGenerator"):
			var arquivo_sala = owner.scene_file_path if owner else ""
			cena_alvo = DungeonGenerator.get_proxima_sala(arquivo_sala)
			
		if cena_alvo != "":
			TransitionScreen.change_scene(cena_alvo)
