extends Node2D

# script base das salas de biologia (Estufa)

var monstros_na_sala: int = 0
var total_monstros_inicial: int = 0
var _chave_dropada: bool = false

@export_group("Recompensas")
# ativa o drop de chave ao derrotar o ultimo monstro da sala
@export var dropar_chave_no_ultimo_monstro: bool = false

func _ready() -> void:
	if get_node_or_null("/root/DatabaseManager"):
		DatabaseManager.active_dungeon = "Biologia"
	if get_node_or_null("/root/DungeonGenerator"):
		DungeonGenerator.masmorra_retorno_hub = "Biologia"
		# consulta o DungeonGenerator para saber se essa sala usa chave
		dropar_chave_no_ultimo_monstro = DungeonGenerator.sala_usa_chave(scene_file_path)
		print("[Sala Biologia] dropar_chave_no_ultimo_monstro = ", dropar_chave_no_ultimo_monstro, " para ", scene_file_path)
		
	if get_node_or_null("/root/AudioManager"):
		AudioManager.start_playlist()
		
	_iniciar_sistema_inimigos_e_portas()

func _iniciar_sistema_inimigos_e_portas() -> void:
	var inimigos = get_tree().get_nodes_in_group("inimigos")
	var count = 0
	for inimigo in inimigos:
		if is_ancestor_of(inimigo) and not inimigo.is_queued_for_deletion():
			count += 1
			if inimigo.has_signal("inimigo_derrotado") and not inimigo.inimigo_derrotado.is_connected(_on_inimigo_derrotado):
				inimigo.inimigo_derrotado.connect(_on_inimigo_derrotado)
			elif inimigo.has_node("EnemyTrigger"):
				var trig = inimigo.get_node("EnemyTrigger")
				if trig.has_signal("inimigo_derrotado") and not trig.inimigo_derrotado.is_connected(_on_inimigo_derrotado):
					trig.inimigo_derrotado.connect(_on_inimigo_derrotado)
			
	if count == 0:
		for child in get_children():
			if not child.is_queued_for_deletion() and not child.is_in_group("player") and child.name != "Player" and not child.name.begins_with("Player"):
				if child.has_node("EnemyTrigger") or child.name.begins_with("Slime") or child.name.begins_with("Robo") or (child is CharacterBody2D):
					count += 1
					if child.has_signal("inimigo_derrotado") and not child.inimigo_derrotado.is_connected(_on_inimigo_derrotado):
						child.inimigo_derrotado.connect(_on_inimigo_derrotado)
					elif child.has_node("EnemyTrigger"):
						var trig = child.get_node("EnemyTrigger")
						if trig.has_signal("inimigo_derrotado") and not trig.inimigo_derrotado.is_connected(_on_inimigo_derrotado):
							trig.inimigo_derrotado.connect(_on_inimigo_derrotado)
					
	monstros_na_sala = count
	total_monstros_inicial = count

func _contar_monstros_restantes() -> int:
	var count = 0
	for inimigo in get_tree().get_nodes_in_group("inimigos"):
		if is_ancestor_of(inimigo) and is_instance_valid(inimigo) and not inimigo.is_queued_for_deletion():
			count += 1
	return count

func _on_inimigo_derrotado(pos: Vector2) -> void:
	monstros_na_sala = max(0, monstros_na_sala - 1)
	var vivos_restantes = _contar_monstros_restantes()
	print("[Sala Biologia] Inimigo derrotado. Restantes contados: %d, contador: %d" % [vivos_restantes, monstros_na_sala])
	if not _chave_dropada and (monstros_na_sala <= 0 or vivos_restantes <= 1) and _deve_dropar_chave():
		_chave_dropada = true
		_dropar_chave(pos)

func _deve_dropar_chave() -> bool:
	if dropar_chave_no_ultimo_monstro:
		return true
	for p in get_tree().get_nodes_in_group("porta_transicao"):
		if is_ancestor_of(p) and (p.get("esta_trancada") == true or p.get("precisa_de_chave") == true):
			return true
	if has_node("PortaTrancada") or has_node("PortaTrancadaTeste"):
		return true
	return false

func _dropar_chave(pos: Vector2) -> void:
	var cena_atual = scene_file_path.to_lower()
	if "boss" in cena_atual or "biologia04" in cena_atual:
		return
	var cena_chave = load("res://scenes/Entidades/Items/ItemChave.tscn")
	if not cena_chave:
		cena_chave = load("res://scenes/Entidades/ItemChave.tscn")
	if not cena_chave:
		return
	var chave = cena_chave.instantiate()
	chave.position = to_local(pos)
	call_deferred("add_child", chave)
	print("[Sala Biologia] Chave dropada com sucesso na posição: ", pos)
