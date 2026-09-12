extends "res://scripts/levels/sala_quimica.gd"

func _ready() -> void:
	print("Sala02 Iniciada - Iluminação Realista e Gerenciamento de Drops")
	super._ready()
			
	var porta = get_node_or_null("PortaTransicao")
	if porta:
		porta.process_mode = Node.PROCESS_MODE_DISABLED
		porta.hide()
		
		var trancada = StaticBody2D.new()
		trancada.name = "PortaTrancadaTeste"
		trancada.position = porta.position
		
		var script_porta = load("res://scripts/PortaTrancada.gd")
		if script_porta: trancada.set_script(script_porta)
		
		var sprite_porta = porta.get_node_or_null("SpritePorta")
		if sprite_porta:
			trancada.add_child(sprite_porta.duplicate())
			
		var col_porta = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(100, 100)
		col_porta.shape = rect
		trancada.add_child(col_porta)
		
		call_deferred("add_child", trancada)

func _on_inimigo_derrotado(pos: Vector2) -> void:
	monstros_na_sala -= 1
	print("Robô derrotado! Restam: ", monstros_na_sala)
	
	if monstros_na_sala <= 0:
		_dropar_chave(pos)

func _dropar_chave(pos: Vector2) -> void:
	print("Último robô morto! Dropando a chave!")
	var cena_chave = load("res://scenes/Entidades/ItemChave.tscn")
	if not cena_chave: return
	var chave = cena_chave.instantiate()
	chave.position = pos
	call_deferred("add_child", chave)
