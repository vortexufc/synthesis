extends Node2D

var parabens_scene = preload("res://scenes/ui/parabens_ui.tscn")
var _parabens_aberto := false

func _ready() -> void:
	var area = Area2D.new()
	area.name = "PortaFinal"
	area.monitoring = true
	area.monitorable = false
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(60, 60) # Tamanho suficiente para detectar de perto
	collision.shape = shape
	area.add_child(collision)
	
	# Porta fechada fica no topo-centro da Sala 02
	# Player começa em Vector2(580, 946), então a porta está no topo
	area.position = Vector2(580, 300)
	
	# Layer/mask para detectar CharacterBody2D do player (layer 1)
	area.collision_layer = 0   # Area não precisa ter layer própria
	area.collision_mask = 1    # Detecta corpos na layer 1 (player)
	
	area.body_entered.connect(_on_door_entered)
	add_child(area)
	
	print("[Sala02] Porta final criada em: ", area.global_position, " | Tamanho: ", shape.size)
	
	# Info do mapa para calibrar posição
	var floor_map = get_node_or_null("Floor") as TileMapLayer
	if floor_map:
		var rect = floor_map.get_used_rect()
		var cell_size = 16.0 * floor_map.scale.x
		print("[Sala02] Floor Rect: ", rect, " | Em Pixels: Pos=", Vector2(rect.position) * cell_size, " Size=", Vector2(rect.size) * cell_size)

func _on_door_entered(body: Node2D) -> void:
	if _parabens_aberto:
		return
	if body.is_in_group("player"):
		print("[Sala02] Player encostou na porta final! Mostrando PARABÉNS!")
		_parabens_aberto = true
		var ui = parabens_scene.instantiate()
		get_tree().root.add_child(ui)
		ui.mostrar()

func _process(_delta: float) -> void:
	var player = get_node_or_null("Player")
	if player:
		if Engine.get_frames_drawn() % 60 == 0:
			var porta = get_node_or_null("PortaFinal")
			var porta_pos = porta.global_position if porta else Vector2.ZERO
			print("[Sala02 DEBUG] Player Pos: ", player.global_position, " | Porta Pos: ", porta_pos)
