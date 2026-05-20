extends Node2D

func _ready() -> void:
	var porta_script = load("res://scripts/porta_transicao.gd")
	var area = Area2D.new()
	area.name = "PortaTransicao"
	area.set_script(porta_script)
	area.set("proxima_cena", "res://scenes/Salas/Salas_BuildTGXP/Sala02.tscn")

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(60, 60)
	collision.shape = shape
	area.add_child(collision)

	# Posição que o usuário confirmou que funciona (porta da esquerda)
	area.position = Vector2(280, 270)

	# A porta detecta os corpos (que estão no mask 1)
	area.collision_layer = 0
	area.collision_mask = 1

	add_child(area)

	print("[Sala01] Porta de transição configurada em: ", area.global_position)

func _process(_delta: float) -> void:
	var player = get_node_or_null("Player")
	if player:
		if Engine.get_frames_drawn() % 60 == 0:
			var porta = get_node_or_null("PortaTransicao")
			var porta_pos = porta.global_position if porta else Vector2.ZERO
			print("[Sala01 DEBUG] Player Pos: ", player.global_position, " | Porta Pos: ", porta_pos)
