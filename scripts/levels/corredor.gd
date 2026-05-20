extends Node2D

func _ready() -> void:
	var porta_script = load("res://scripts/porta_transicao.gd")
	var area = Area2D.new()
	area.name = "PortaTransicao"
	area.set_script(porta_script)
	area.set("proxima_cena", "res://scenes/Salas/Salas_BuildTGXP/Sala01.tscn")

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(10, 10) # Área bem pequena
	collision.shape = shape
	area.add_child(collision)

	# Posiciona a porta (movi o Y para 380 para ele ter que entrar mais na porta)
	area.position = Vector2(620, 380)

	# A porta detecta os corpos (que estão no mask 1)
	area.collision_layer = 0
	area.collision_mask = 1

	add_child(area)

	print("[Corredor] Porta de transição configurada em: ", area.global_position)
