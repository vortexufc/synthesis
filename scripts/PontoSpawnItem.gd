@tool
extends Marker2D
class_name PontoSpawnItem

# ponto de spawn de item na sala (mostra icone no editor)

enum TipoItemPreview {
	HERDAR_DO_GERENCIADOR = 0,
	PERGAMINHO = 1,
	LIVRO = 2,
	BATERIA = 3,
	CHIP = 4,
	MOEDA = 5,
	CHAVE = 6
}

@export var tipo_preview: TipoItemPreview = TipoItemPreview.HERDAR_DO_GERENCIADOR:
	set(valor):
		tipo_preview = valor
		if Engine.is_editor_hint():
			queue_redraw()

static var _tex_pergaminho: Texture2D = null
static var _tex_livro: Texture2D = null
static var _tex_bateria: Texture2D = null
static var _tex_chip: Texture2D = null
static var _tex_moeda: Texture2D = null
static var _tex_chave: Texture2D = null

func _init() -> void:
	gizmo_extents = 20.0
	add_to_group("pontos_item")

func _enter_tree() -> void:
	add_to_group("pontos_item")
	if Engine.is_editor_hint():
		queue_redraw()

func _ready() -> void:
	add_to_group("pontos_item")
	if Engine.is_editor_hint():
		queue_redraw()

func _carregar_texturas() -> void:
	if _tex_pergaminho == null:
		_tex_pergaminho = load("res://assets/sprites/pergaminho.png")
	if _tex_livro == null:
		_tex_livro = load("res://assets/sprites/ui/item_livro_formulas.png")
	if _tex_bateria == null:
		_tex_bateria = load("res://assets/sprites/ui/item_bateria.png")
	if _tex_chip == null:
		_tex_chip = load("res://assets/sprites/ui/item_chip.png")
	if _tex_moeda == null:
		_tex_moeda = load("res://assets/sprites/ui/coin.png")
	if _tex_chave == null:
		_tex_chave = load("res://assets/sprites/ui/icon_key_transparent.png")

func _obter_tipo_resolvido() -> int:
	if tipo_preview != TipoItemPreview.HERDAR_DO_GERENCIADOR:
		return tipo_preview
		
	var pai = get_parent()
	if pai != null and "tipo_item" in pai:
		return int(pai.tipo_item) + 1
		
	return TipoItemPreview.PERGAMINHO

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
		
	_carregar_texturas()
	var tipo = _obter_tipo_resolvido()
	
	# circulo de destaque
	var cor_aura = Color(0.2, 0.8, 1.0, 0.20)
	var cor_borda = Color(0.2, 0.85, 1.0, 0.80)
	
	match tipo:
		TipoItemPreview.PERGAMINHO:
			cor_aura = Color(0.9, 0.8, 0.3, 0.25)
			cor_borda = Color(1.0, 0.85, 0.3, 0.85)
		TipoItemPreview.LIVRO:
			cor_aura = Color(0.2, 0.6, 1.0, 0.25)
			cor_borda = Color(0.3, 0.7, 1.0, 0.85)
		TipoItemPreview.BATERIA:
			cor_aura = Color(0.15, 0.65, 1.0, 0.25)
			cor_borda = Color(0.25, 0.80, 1.0, 0.85)
		TipoItemPreview.CHIP:
			cor_aura = Color(0.15, 0.85, 0.50, 0.25)
			cor_borda = Color(0.25, 1.0, 0.60, 0.85)
		TipoItemPreview.MOEDA, TipoItemPreview.CHAVE:
			cor_aura = Color(1.0, 0.85, 0.2, 0.25)
			cor_borda = Color(1.0, 0.85, 0.2, 0.85)
			
	draw_circle(Vector2.ZERO, 22.0, cor_aura)
	draw_arc(Vector2.ZERO, 22.0, 0, TAU, 32, cor_borda, 1.5)
	
	var dest = Rect2(-16, -16, 32, 32)
	match tipo:
		TipoItemPreview.PERGAMINHO:
			if _tex_pergaminho:
				draw_texture_rect_region(_tex_pergaminho, dest, Rect2(0, 0, 64, 64), Color(1.0, 0.95, 0.8, 0.90))
		TipoItemPreview.LIVRO:
			if _tex_livro:
				draw_texture_rect(_tex_livro, dest, false, Color(0.85, 0.95, 1.0, 0.90))
		TipoItemPreview.BATERIA:
			if _tex_bateria:
				draw_texture_rect(_tex_bateria, dest, false, Color(1.0, 1.0, 1.0, 0.95))
		TipoItemPreview.CHIP:
			if _tex_chip:
				draw_texture_rect(_tex_chip, dest, false, Color(1.0, 1.0, 1.0, 0.95))
		TipoItemPreview.MOEDA:
			if _tex_moeda:
				draw_texture_rect_region(_tex_moeda, dest, Rect2(300, 107, 370, 370), Color(1.0, 1.0, 1.0, 0.95))
		TipoItemPreview.CHAVE:
			if _tex_chave:
				draw_texture_rect(_tex_chave, dest, false, Color(1.0, 0.9, 0.3, 0.90))
