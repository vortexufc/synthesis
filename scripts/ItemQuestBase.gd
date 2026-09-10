extends Area2D

@export var nome_item: String = "Item Desconhecido"
@export var descricao_item: String = "Um item genérico de missão."

var coletavel = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 15 # Pega o player
	body_entered.connect(_coletar)
	
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): coletavel = true)
	tween.tween_callback(_verificar_coleta_imediata)
	
	var tween_float = create_tween().set_loops()
	var sprite = $Sprite2D
	if sprite:
		tween_float.tween_property(sprite, "position:y", -10.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween_float.tween_property(sprite, "position:y", 10.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _verificar_coleta_imediata() -> void:
	for corpo in get_overlapping_bodies():
		_coletar(corpo)

func _coletar(corpo: Node2D) -> void:
	if not coletavel: return
	if corpo.is_in_group("player") or corpo.name.begins_with("Player"):
		if get_node_or_null("/root/PlayerStats"):
			PlayerStats.itens.append({
				"nome": nome_item,
				"descricao": descricao_item
			})
			PlayerStats.salvar()
			PlayerStats.quests_atualizadas.emit()
			
			var hud = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("mostrar_mensagem"):
				var total = 0
				for it in PlayerStats.itens:
					if it.get("nome") == nome_item: total += 1
				hud.mostrar_mensagem(nome_item + " (" + str(total) + "/5)")
				
		queue_free()
