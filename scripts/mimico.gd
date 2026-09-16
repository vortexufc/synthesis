## [Trap-1] Armadilha: O Mímico (Baú Falso)
## Lore: Criado para punir aprendizes que buscam atalhos fáceis.
## Fluxo: player entra na área → travado → tremor + flash vermelho → -70 HP → banner explicativo → libera.
extends Area2D

# Controla se a armadilha já foi ativada (dispara uma única vez)
var ja_ativado: bool = false

# Duração do tremor em segundos
@export var duracao_tremor: float = 0.5
# Intensidade do tremor (deslocamento em pixels)
@export var intensidade_tremor: float = 8.0
# Dano massivo causado pela mordida do Mímico
@export var dano: float = 70.0

@onready var sprite: Sprite2D = $BauSprite if has_node("BauSprite") else null
var tex_aberto: AtlasTexture = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var base_tex = load("res://assets/sprites/tilesets/Alquimia/OBJETOS.png")
	if base_tex:
		tex_aberto = AtlasTexture.new()
		tex_aberto.atlas = base_tex
		tex_aberto.region = Rect2(1024, 528, 48, 48)

func _on_body_entered(body: Node2D) -> void:
	# Só ativa uma vez e só para o Player
	if ja_ativado:
		return
	if not body.name == "Player":
		return

	ja_ativado = true
	set_deferred("monitoring", false) # desativa colisão futura

	# Emite sinal global (pode ser ouvido pela HUD)
	GlobalSignals.mimico_ativado.emit(body)

	# Inicia a sequência assíncrona da armadilha
	_sequencia_mimico(body)

func _sequencia_mimico(player: Node2D) -> void:
	# 1) Trava o movimento do player
	player.travado = true

	# Habilita o StaticBody2D para que o jogador não possa passar por cima do baú
	if has_node("StaticBody2D/CollisionShape2D"):
		$StaticBody2D/CollisionShape2D.set_deferred("disabled", false)

	# Abre o baú com dentes/saliva avermelhada
	if sprite and tex_aberto:
		sprite.texture = tex_aberto
		sprite.self_modulate = Color(2.0, 0.35, 0.35)
		var tw_m = create_tween().set_loops(4)
		tw_m.tween_property(sprite, "rotation", deg_to_rad(6.0), 0.06)
		tw_m.tween_property(sprite, "rotation", deg_to_rad(-6.0), 0.06)
		tw_m.tween_property(sprite, "rotation", 0.0, 0.06)

	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx("ui-2")
		AudioManager.play_sfx("fail")

	# 2) Tremor + flash vermelho simultâneos
	_executar_tremor(player)
	_flash_vermelho(player)

	# 3) Aplica o dano de 70 HP e feedback no player
	await get_tree().create_timer(duracao_tremor * 0.4).timeout
	player.receber_dano_mimico(dano)

	# 4) Exibe alerta explicativo na tela para o jogador entender o ocorrido
	_exibir_alerta_mimico(dano)

	# 5) Libera o movimento após o tremor inicial
	await get_tree().create_timer(0.4).timeout
	player.travado = false

## Tremor: oscila a posição do player rapidamente
func _executar_tremor(player: Node2D) -> void:
	var pos_original: Vector2 = player.position
	var tween = create_tween()

	# Monta sequência de chacoalhadas
	var passos: int = int(duracao_tremor / 0.05)
	for i in passos:
		var offset := Vector2(
			randf_range(-intensidade_tremor, intensidade_tremor),
			randf_range(-intensidade_tremor * 0.5, intensidade_tremor * 0.5)
		)
		tween.tween_property(player, "position", pos_original + offset, 0.04)
	# Volta à posição original no fim
	tween.tween_property(player, "position", pos_original, 0.06)

## Flash vermelho: ColorRect vermelho semi-transparente sobre a tela
func _flash_vermelho(player: Node2D) -> void:
	# Cria o overlay vermelho como filho do CanvasLayer do player (ou da cena)
	var canvas := CanvasLayer.new()
	canvas.layer = 10 # acima de tudo
	var rect := ColorRect.new()
	rect.color = Color(1, 0, 0, 0.0)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	player.add_child(canvas)

	# Fade in → fade out vermelho
	var tween = create_tween()
	tween.tween_property(rect, "color", Color(1, 0, 0, 0.45), 0.08)
	tween.tween_property(rect, "color", Color(1, 0, 0, 0.0), 0.35)
	await tween.finished

	# Remove o overlay da memória
	canvas.queue_free()

## Exibe um banner imersivo na tela explicando o ataque do Mímico com botão para fechar
func _exibir_alerta_mimico(dano_causado: float) -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 106
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(canvas)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(580, 140)
	panel.pivot_offset = Vector2(290, 70)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.03, 0.05, 0.97)
	sb.border_width_left = 3
	sb.border_width_right = 3
	sb.border_width_top = 3
	sb.border_width_bottom = 3
	sb.border_color = Color(1.0, 0.25, 0.25)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.shadow_color = Color(0.8, 0.1, 0.1, 0.55)
	sb.shadow_size = 30
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var font_titulo = SystemFont.new()
	font_titulo.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "Noto Sans", "sans-serif"])
	font_titulo.font_weight = 800

	var font_sans = SystemFont.new()
	font_sans.font_names = PackedStringArray(["Segoe UI", "Arial", "Roboto", "sans-serif"])
	font_sans.font_weight = 600

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Barra superior (com botão 'X' no canto direito)
	var hbox_top = HBoxContainer.new()
	hbox_top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(hbox_top)

	# Espaçador à esquerda com mesma largura do botão 'X' para manter o título perfeitamente centralizado
	var spacer_left = Control.new()
	spacer_left.custom_minimum_size = Vector2(28, 28)
	hbox_top.add_child(spacer_left)

	var lbl_titulo = Label.new()
	lbl_titulo.text = "⚠️ EMBOSCADA! VOCÊ FOI ENGANADO! ⚠️"
	lbl_titulo.add_theme_font_override("font", font_titulo)
	lbl_titulo.add_theme_font_size_override("font_size", 18)
	lbl_titulo.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	lbl_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox_top.add_child(lbl_titulo)

	var btn_x = Button.new()
	btn_x.text = "✕"
	btn_x.custom_minimum_size = Vector2(28, 28)
	btn_x.add_theme_font_size_override("font_size", 14)
	btn_x.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	
	var sb_x = StyleBoxFlat.new()
	sb_x.bg_color = Color(0.2, 0.05, 0.08, 0.8)
	sb_x.border_color = Color(0.6, 0.2, 0.2)
	sb_x.border_width_left = 1
	sb_x.border_width_right = 1
	sb_x.border_width_top = 1
	sb_x.border_width_bottom = 1
	sb_x.corner_radius_top_left = 6
	sb_x.corner_radius_top_right = 6
	sb_x.corner_radius_bottom_left = 6
	sb_x.corner_radius_bottom_right = 6
	btn_x.add_theme_stylebox_override("normal", sb_x)
	
	var sb_x_hover = sb_x.duplicate()
	sb_x_hover.bg_color = Color(0.8, 0.15, 0.15)
	btn_x.add_theme_stylebox_override("hover", sb_x_hover)
	btn_x.add_theme_stylebox_override("pressed", sb_x_hover)
	hbox_top.add_child(btn_x)

	# Mensagem descritiva
	var lbl_desc = Label.new()
	lbl_desc.text = "O baú era uma criatura mímica voraz disfarçada!\nMandíbulas arcanas e espinhos venenosos morderam você causando -%.0f HP!" % dano_causado
	lbl_desc.add_theme_font_override("font", font_sans)
	lbl_desc.add_theme_font_size_override("font_size", 14)
	lbl_desc.add_theme_color_override("font_color", Color(1.0, 0.88, 0.88))
	lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_desc)

	# Dica de sobrevivência
	var lbl_dica = Label.new()
	lbl_dica.text = "💡 DICA: Abra seu Inventário [I] e tome uma Poção de Cura para sobreviver!"
	lbl_dica.add_theme_font_override("font", font_sans)
	lbl_dica.add_theme_font_size_override("font_size", 13)
	lbl_dica.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	lbl_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_dica)

	# Fechamento seguro
	var fechou: Array = [false]
	var fechar_alerta = func():
		if fechou[0]: return
		fechou[0] = true
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx("ui-1")
		if is_instance_valid(panel):
			var tw_out = panel.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tw_out.tween_property(panel, "modulate:a", 0.0, 0.2)
			tw_out.tween_property(panel, "scale", Vector2(0.85, 0.85), 0.2)
			await tw_out.finished
		if is_instance_valid(canvas):
			canvas.queue_free()

	btn_x.pressed.connect(fechar_alerta)

	# Animação de entrada
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	var tw = panel.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.25)
	tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.25)
