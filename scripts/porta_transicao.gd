extends Area2D

@export var proxima_cena: String = ""
@export var porta_de_retorno: bool = false

# Cooldown para evitar teletransporte imediato ao carregar a cena (loop infinito)
var _cooldown_ativo: bool = true

func _ready() -> void:
	add_to_group("porta_transicao")
	body_entered.connect(_on_body_entered)
	
	# Aguarda antes de ativar a porta
	await get_tree().create_timer(0.6).timeout
	_cooldown_ativo = false
	
	# Após o cooldown, verifica se o player já está dentro da área
	# (necessário se o player spawnou dentro da zona de colisão)
	for body in get_overlapping_bodies():
		if body.name == "Player":
			_on_body_entered(body)
			break

func _on_body_entered(body: Node2D) -> void:
	if _cooldown_ativo:
		return
		
	if body.name == "Player":
		var cena_alvo = proxima_cena
		
		# SEMPRE marca se o jogador acabou de usar uma porta de retorno
		if get_node_or_null("/root/DungeonGenerator"):
			DungeonGenerator.vindo_de_porta_de_retorno = porta_de_retorno
		
		# Se nenhuma cena foi definida no Editor, puxa do Gerador de Masmorra
		if cena_alvo == "" and get_node_or_null("/root/DungeonGenerator"):
			var arquivo_sala = get_tree().current_scene.scene_file_path
			
			if porta_de_retorno:
				cena_alvo = DungeonGenerator.get_sala_anterior(arquivo_sala)
			else:
				cena_alvo = DungeonGenerator.get_proxima_sala(arquivo_sala)
		
		print("[PortaTransicao] porta_de_retorno=", porta_de_retorno, " | Indo para: ", cena_alvo)
			
		if cena_alvo != "":
			_cooldown_ativo = true  # Evita duplo disparo
			TransitionScreen.change_scene(cena_alvo)
