extends CharacterBody2D

const VELOCIDADE = 100.0

var direcao_horizontal: int
var direcao_vertical: int

var ultima_direcao = "baixo"

func _physics_process(_delta: float) -> void:

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
