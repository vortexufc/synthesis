extends CharacterBody2D

const VELOCIDADE = 200.0

var direcao_horizontal: float
var direcao_vertical: float

var ultima_direcao = "baixo"

# [Trap-1] Mímico — flag que trava o movimento do player
var travado: bool = false

# [Trap-1] HP Global do jogador (0.0 a 1.0, representa 100%)
# Futuramente pode ser substituído por um autoload de stats
var hp: float = 1.0

func _physics_process(_delta: float) -> void:
	# Se travado pelo Mímico, não processa input de movimento
	if travado:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	direcao_horizontal = Input.get_axis("esquerda", "direita")
	direcao_vertical = Input.get_axis("cima", "baixo")

	velocity = Vector2.ZERO
	
	if not direcao_vertical == 0:
		velocity.y = direcao_vertical * VELOCIDADE
		if direcao_vertical < 0:
			ultima_direcao = "cima"
			$sprite.play("correr_cima")
		else:
			ultima_direcao = "baixo"
			$sprite.play("correr_baixo")
	elif not direcao_horizontal == 0:
		velocity.x = direcao_horizontal * VELOCIDADE
		if direcao_horizontal < 0:
			ultima_direcao = "esquerda"
			$sprite.play("correr_esquerda")
		else:
			ultima_direcao = "direita"
			$sprite.play("correr_direita")
	else:
		$sprite.play("idle_" + ultima_direcao)
	
	# Exemplo áudio
	if Input.is_action_just_pressed("ui_accept"):
		AudioManager.play_sfx("ui-1")
	
	
	move_and_slide()

# [Trap-1] Chamado pelo Mímico para aplicar penalidade e feedback visual
func receber_dano_mimico() -> void:
	# Subtrai 15% do HP Global
	hp = max(0.0, hp - 0.15)
	print("[Mímico] HP restante: %.0f%%" % (hp * 100))

	# Flash vermelho no sprite (placeholder visual)
	var tween = create_tween()
	tween.tween_property($sprite, "modulate", Color(1, 0.1, 0.1, 1), 0.08)
	tween.tween_property($sprite, "modulate", Color(1, 1, 1, 1), 0.35)
