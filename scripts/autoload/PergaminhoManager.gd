extends Node

## Autoload responsável por gerar anotações de estudo baseadas nas questões do andar.
## Produz textos orgânicos e naturais, sem inteligência artificial ou modelos engessados.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## Gera até 4 páginas de anotações com base nas questões do andar atual ou da sala.
func obter_paginas_dicas(andar_id: int = 1, questoes_custom: Array = [], num_paginas: int = 4) -> Array[String]:
	var paginas: Array[String] = []
	var max_paginas = clamp(num_paginas, 1, 4)
	
	var lista_questoes: Array = []
	if questoes_custom.size() > 0:
		lista_questoes = questoes_custom.duplicate()
	else:
		lista_questoes = DatabaseManager.carregar_perguntas_locais(andar_id)
		if lista_questoes.is_empty():
			lista_questoes = DatabaseManager.carregar_perguntas_locais(0)
		
	if lista_questoes.is_empty() and get_node_or_null("/root/QuizManager"):
		lista_questoes = QuizManager.questions.duplicate()
		
	lista_questoes.shuffle()
	var total_para_pegar = min(max_paginas, lista_questoes.size())
	
	for i in range(total_para_pegar):
		var q = lista_questoes[i]
		if q is Dictionary:
			var nota = _formatar_anotacao_natural(q, andar_id)
			paginas.append(nota)
			
	if paginas.is_empty():
		paginas = _gerar_anotacoes_genericas(andar_id)
		
	return paginas

func _formatar_anotacao_natural(q: Dictionary, andar_id: int) -> String:
	var pergunta = str(q.get("question", "")).strip_edges()
	var opcoes = q.get("options", [])
	var idx_correto = int(q.get("answer", 0))
	var resposta_correta = ""
	if idx_correto >= 0 and idx_correto < opcoes.size():
		resposta_correta = str(opcoes[idx_correto]).strip_edges()
		
	var titulo_mago = _get_titulo_anotacao(andar_id)
	
	var texto = titulo_mago + "\n\n"
	texto += pergunta + "\n\n"
	if resposta_correta != "":
		texto += "Observação de estudo: o conceito central para responder esta questão envolve " + resposta_correta + "."
		
	return texto

func _get_titulo_anotacao(andar_id: int) -> String:
	match andar_id:
		3: return "Manuscrito de Biologia Arcana"
		1: return "Estudos da Tabela Alquímica"
		2: return "Pergaminho de Física e Mecânica"
		_: return "Anotações do Mago Pesquisador"

func _gerar_anotacoes_genericas(andar_id: int) -> Array[String]:
	match andar_id:
		3: # Biologia
			return [
				"Manuscrito de Biologia Arcana:\n\nPara regenerar ferimentos e multiplicar células somáticas idênticas, os organismos realizam o processo de Mitose. A Meiose é exclusiva para a produção de gametas.",
				"Manuscrito de Biologia Arcana:\n\nOs Slimes e os Fungos compartilham o mesmo modo de nutrição: digerem a matéria organica externamente e depois a absorvem. Isso é nutrição heterotrófica por absorção.",
				"Manuscrito de Biologia Arcana:\n\nNas células vegetais, a fotossíntese ocorre nos Cloroplastos, enquanto a síntese de energia ATP ocorre principalmente nas Mitocôndrias.",
				"Manuscrito de Biologia Arcana:\n\nA síntese de proteínas nas células é realizada pelos Ribossomos, que traduzem a sequência trazida pelo RNA mensageiro."
			]
		1: # Química / Alquimia
			return [
				"Estudos da Tabela Alquímica:\n\nO Sódio (Na) reage de forma violenta em contato com a água. Na tabela periódica, ele pertence à família dos Metais Alcalinos.",
				"Estudos da Tabela Alquímica:\n\nOs elementos da família dos Gases Nobres possuem a camada de valência completa, tornando-os quimicamente muito estáveis.",
				"Estudos da Tabela Alquímica:\n\nA lei dos gases ideais (P * V = n * R * T) mostra que, mantendo a temperatura constante, dobrar a pressão faz o volume cair pela metade.",
				"Estudos da Tabela Alquímica:\n\nReações que liberam calor para o ambiente externo são chamadas de exotérmicas, como no caso da combustão."
			]
		2: # Física
			return [
				"Pergaminho de Física e Mecânica:\n\nA Primeira Lei de Newton (Inércia) diz que um corpo em repouso ou em movimento retilíneo uniforme permanece assim até que uma força resultante atue sobre ele.",
				"Pergaminho de Física e Mecânica:\n\nA Força Peso depende diretamente da massa do objeto e da aceleração da gravidade local (P = m * g).",
				"Pergaminho de Física e Mecânica:\n\nA velocidade média de um objeto em movimento retilíneo é calculada pela variação da posição dividida pelo tempo decorrido.",
				"Pergaminho de Física e Mecânica:\n\nA energia associada ao movimento de um corpo é a Energia Cinética, enquanto a armazenada pela posição é a Energia Potencial."
			]
		_:
			return [
				"Anotações do Mago Pesquisador:\n\nRevise os conceitos fundamentais apresentados nas salas anteriores para superar os desafios do andar.",
				"Anotações do Mago Pesquisador:\n\nCada elemento da masmorra obedece a leis naturais. O conhecimento é a sua maior ferramenta de combate."
			]
