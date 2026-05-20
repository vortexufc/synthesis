extends CanvasLayer

@onready var titulo = $ColorRect/VBoxContainer/Titulo
@onready var subtitulo = $ColorRect/VBoxContainer/Subtitulo
@onready var btn_menu = $ColorRect/VBoxContainer/HBoxContainer/BtnMenuPrincipal
@onready var color_rect = $ColorRect

var particulas: CPUParticles2D

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	btn_menu.pressed.connect(_on_menu_pressed)
	
	# particulas douradas
	particulas = CPUParticles2D.new()
	particulas.emitting = false
	particulas.amount = 120
	particulas.lifetime = 2.5
	particulas.one_shot = false
	particulas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	var screen_size = get_viewport().get_visible_rect().size
	particulas.emission_rect_extents = screen_size / 2.0
	particulas.position = screen_size / 2.0
	particulas.gravity = Vector2(0, 40)
	particulas.color = Color.GOLD
	particulas.scale_amount_min = 2.0
	particulas.scale_amount_max = 6.0
	add_child(particulas)

func mostrar() -> void:
	get_tree().paused = true
	show()
	particulas.emitting = true

func _on_menu_pressed() -> void:
	hide()
	particulas.emitting = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
