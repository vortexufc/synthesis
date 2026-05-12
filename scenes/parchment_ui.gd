extends CanvasLayer

# ==========================================
# 1. REFERÊNCIAS DOS NÓS VISUAIS
# ATENÇÃO: Ajuste os caminhos abaixo para baterem com o nome exato 
# dos seus nós na árvore de cena do ParchmentUI.
# ==========================================
@onready var texto_dica = $Control/BackgroundPapel/TextoDica
@onready var btn_esquerda = $Control/BackgroundPapel/BotoesContainer/BtnEsquerda
@onready var btn_direita = $Control/BackgroundPapel/BotoesContainer/BtnDireita
@onready var btn_fechar = $Control/BackgroundPapel/BotoesContainer/BtnFechar

# Variáveis para controlar a leitura
var paginas_do_texto: Array[String] = []
var pagina_atual: int = 0
var player_ref: Node2D = null

func _ready() -> void:
	# O pergaminho começa invisível
	hide()
	
	# Conecta os botões do pergaminho automaticamente
	btn_esquerda.pressed.connect(_voltar_pagina)
	btn_direita.pressed.connect(_avancar_pagina)
	btn_fechar.pressed.connect(_fechar_pergaminho)

# ==========================================
# 2. A FUNÇÃO QUE É CHAMADA PELO PERGAMINHO DO CHÃO
# ==========================================
func abrir_pergaminho(paginas: Array[String], player: Node2D) -> void:
	paginas_do_texto = paginas
	player_ref = player  # Guardamos quem é o player para destravar ele depois
	pagina_atual = 0     # Sempre começa na primeira página
	
	atualizar_tela()
	show() # Faz a interface aparecer na tela!

# ==========================================
# 3. LÓGICA DE ATUALIZAR O TEXTO E BOTÕES
# ==========================================
func atualizar_tela() -> void:
	# Prevenção de erro caso o array esteja vazio
	if paginas_do_texto.is_empty():
		return
		
	# Muda o texto na tela para a página atual
	texto_dica.text = paginas_do_texto[pagina_atual]
	
	# Esconde o botão "Esquerda" se estiver na página 0 (primeira)
	btn_esquerda.visible = pagina_atual > 0
	
	# Esconde o botão "Direita" se estiver na última página
	btn_direita.visible = pagina_atual < (paginas_do_texto.size() - 1)

# ==========================================
# 4. FUNÇÕES DOS BOTÕES (CLIQUES)
# ==========================================
func _voltar_pagina() -> void:
	if pagina_atual > 0:
		pagina_atual -= 1
		atualizar_tela()

func _avancar_pagina() -> void:
	if pagina_atual < paginas_do_texto.size() - 1:
		pagina_atual += 1
		atualizar_tela()

func _fechar_pergaminho() -> void:
	hide() # Esconde o pergaminho da tela
	
	# Mágica final: Destrava o player para ele voltar a se mexer!
	if player_ref:
		player_ref.travado = false
		player_ref = null # Limpa a referência
