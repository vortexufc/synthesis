extends Node

## Autoload responsável por gerar os conteúdos e dicas dos Pergaminhos Arcanos
## encontrados em baús ao longo das salas dos andares da masmorra.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## Gera até 4 páginas de dicas com base no andar atual ou em questões locais.
func obter_paginas_dicas(andar_id: int = 1, questoes_custom: Array = [], num_paginas: int = 4) -> Array[String]:
	var paginas: Array[String] = []
	var max_paginas = clamp(num_paginas, 1, 4)
	
	var lista_questoes: Array = []
	if questoes_custom.size() > 0:
		lista_questoes = questoes_custom.duplicate()
	else:
		lista_questoes = DatabaseManager.carregar_perguntas_locais(andar_id)
		
	if lista_questoes.is_empty() and get_node_or_null("/root/QuizManager"):
		lista_questoes = QuizManager.questions.duplicate()
		
	# Embaralha as questões para que cada baú traga um pergaminho com dicas variadas
	lista_questoes.shuffle()
	
	var total_para_pegar = min(max_paginas, lista_questoes.size())
	
	for i in range(total_para_pegar):
		var q = lista_questoes[i]
		if q is Dictionary:
			var pergunta = q.get("question", "")
			var opcoes = q.get("options", [])
			var idx_correto = int(q.get("answer", 0))
			
			var resposta_correta = ""
			if idx_correto >= 0 and idx_correto < opcoes.size():
				resposta_correta = str(opcoes[idx_correto])
				
			var titulo_andar = _get_nome_andar(andar_id)
			
			var pagina_text = "📜 PERGAMINHO ARCANO (%s)\n" % titulo_andar
			pagina_text += "── PÁGINA %d de %d ──\n\n" % [i + 1, total_para_pegar]
			pagina_text += "💡 DICA DE ESTUDO:\n"
			pagina_text += "Tópico: " + _resumir_pergunta(pergunta) + "\n\n"
			pagina_text += "🔍 CONCEITO RELEVANTE:\n"
			pagina_text += pergunta + "\n\n"
			if resposta_correta != "":
				pagina_text += "✨ Lembre-se: O princípio fundamental está associado a: \"" + resposta_correta + "\"."
				
			paginas.append(pagina_text)
			
	# Se por algum motivo não houver questões suficientes, preenche com pergaminhos genéricos do andar
	if paginas.is_empty():
		paginas = _gerar_paginas_genericas(andar_id)
		
	return paginas

func _resumir_pergunta(texto: String) -> String:
	if texto.length() > 60:
		return texto.substr(0, 57) + "..."
	return texto

func _get_nome_andar(andar_id: int) -> String:
	match andar_id:
		1: return "Andar de Biologia"
		2: return "Andar de Química / Alquimia"
		3: return "Andar de Física"
		_: return "Torre da Masmorra"

func _gerar_paginas_genericas(andar_id: int) -> Array[String]:
	var titulo = _get_nome_andar(andar_id)
	return [
		"📜 PERGAMINHO ARCANO (%s)\n── PÁGINA 1 de 4 ──\n\n💡 Dica de Biologia:\nCélulas somáticas dividem-se por Mitose para regeneração de tecidos. Lembre-se das fases: Prófase, Metáfase, Anáfase e Telófase!" % titulo,
		"📜 PERGAMINHO ARCANO (%s)\n── PÁGINA 2 de 4 ──\n\n💡 Dica de Química:\nNa tabela periódica, elementos do Grupo 18 são Gases Nobres e possuem a camada de valência completa!" % titulo,
		"📜 PERGAMINHO ARCANO (%s)\n── PÁGINA 3 de 4 ──\n\n💡 Dica de Física:\nA Primeira Lei de Newton afirma que um corpo permanece em repouso ou em movimento retilíneo uniforme a menos que uma força resultante atue sobre ele." % titulo,
		"📜 PERGAMINHO ARCANO (%s)\n── PÁGINA 4 de 4 ──\n\n💡 Dica Final:\nEstude os conceitos fundamentais antes de enfrentar os Guardiões do Andar!" % titulo
	]
