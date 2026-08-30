extends Node2D

var monstros_na_sala = 0

func _ready() -> void:
	print("Sala01 Iniciada - Injetando Teste de Chaves e Portas")
	
	# Pega os monstros da sala
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	monstros_na_sala = inimigos.size()
	
	for inimigo in inimigos:
		inimigo.tree_exited.connect(_on_inimigo_derrotado.bind(inimigo.global_position))
	
	# Substitui a porta de transicao
	var porta = get_node_or_null("PortaTransicao")
	if porta:
		# Desliga a PortaTransicao temporariamente para ela não interferir
		porta.process_mode = Node.PROCESS_MODE_DISABLED
		porta.hide()
		
		var trancada = StaticBody2D.new()
		trancada.name = "PortaTrancadaTeste"
		trancada.position = porta.position
		
		var script_porta = load("res://scripts/PortaTrancada.gd")
		trancada.set_script(script_porta)
		
		# Clona o sprite da porta original para a porta trancada
		var sprite_porta = porta.get_node_or_null("SpritePorta")
		if sprite_porta:
			trancada.add_child(sprite_porta.duplicate())
			
		var col_porta = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(100, 100)
		col_porta.shape = rect
		trancada.add_child(col_porta)
		
		call_deferred("add_child", trancada)
		# Não deletamos mais a original!

func _on_inimigo_derrotado(pos: Vector2) -> void:
	# O _on_inimigo_derrotado roda quando o monstro some do mapa
	monstros_na_sala -= 1
	print("Monstro derrotado! Restam: ", monstros_na_sala)
	
	if monstros_na_sala <= 0:
		_dropar_chave(pos)

func _dropar_chave(pos: Vector2) -> void:
	print("Último monstro morto! Dropando a chave!")
	var chave = Area2D.new()
	chave.name = "ChaveTeste"
	chave.position = pos
	var script_chave = load("res://scripts/ItemChave.gd")
	chave.set_script(script_chave)
	
	var sprite_chave = Sprite2D.new()
	sprite_chave.name = "Sprite2D"
	sprite_chave.texture = load("res://assets/sprites/ui/icon_key.jpg")
	sprite_chave.scale = Vector2(0.04, 0.04)
	chave.add_child(sprite_chave)
	
	var col_chave = CollisionShape2D.new()
	var cir_chave = CircleShape2D.new()
	cir_chave.radius = 40.0
	col_chave.shape = cir_chave
	chave.add_child(col_chave)
	
	call_deferred("add_child", chave)
