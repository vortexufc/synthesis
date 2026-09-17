@tool
extends Marker2D
class_name PontoSpawnBau

# ponto onde nasce bau na sala (mostra preview no editor)

const TEX_OBJETOS = preload("res://assets/sprites/tilesets/Alquimia/OBJETOS.png")

func _init() -> void:
	gizmo_extents = 24.0
	add_to_group("pontos_bau")

func _enter_tree() -> void:
	add_to_group("pontos_bau")
	if Engine.is_editor_hint():
		queue_redraw()

func _ready() -> void:
	add_to_group("pontos_bau")
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	# so desenha no editor
	if not Engine.is_editor_hint():
		return
		
	if TEX_OBJETOS:
		# bau de madeira padrao
		var reg = Rect2(1024, 336, 48, 48)
		var cor_borda = Color(1.0, 0.85, 0.25, 0.9)
		var cor_mod = Color(1.0, 0.95, 0.7, 0.75)
		
		var pai = get_parent()
		if pai != null and "cena_bau" in pai and pai.cena_bau != null:
			var path = pai.cena_bau.resource_path
			if "bau3" in path: # bau de metal
				reg = Rect2(768, 336, 48, 48)
				cor_borda = Color(0.3, 0.85, 1.0, 0.95)
				cor_mod = Color(0.85, 0.95, 1.0, 0.85)
			elif "bau2" in path: # bau azul
				reg = Rect2(896, 336, 48, 48)
				cor_borda = Color(0.65, 0.45, 1.0, 0.95)
				cor_mod = Color(0.85, 0.8, 1.0, 0.85)
				
		var dest = Rect2(-30, -30, 60, 60)
		draw_texture_rect_region(TEX_OBJETOS, dest, reg, cor_mod)
		
		# contorno pra enxergar facil
		draw_rect(dest, cor_borda, false, 1.5)
