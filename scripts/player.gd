extends CharacterBody2D


const VELOCIDADE = 300.0

var direcao_horizontal: int
var direcao_vertical: int

func _physics_process(_delta: float) -> void:
	
	direcao_horizontal = Input.get_axis("esquerda", "direita")
	direcao_vertical = Input.get_axis("cima", "baixo")
	
	velocity = Vector2.ZERO
	
	if not direcao_vertical == 0:
		velocity.y = direcao_vertical * VELOCIDADE
	elif not direcao_horizontal == 0:
		velocity.x = direcao_horizontal * VELOCIDADE
	
	# Exemplo áudio
	if Input.is_action_just_pressed("ui_accept"):
		AudioManager.play_sfx("ui-1")
	
	
	move_and_slide()
