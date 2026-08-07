import json

with open('data/questions.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

for q in data:
    dica = q.get('dica', '')
    if dica:
        # Pega a resposta correta usando o índice
        resposta_correta = q['options'][q['answer']]
        # Se a dica já não contém "A resposta correta é:", a gente adiciona
        if "A resposta é:" not in dica and "A resposta correta é:" not in dica:
            q['dica'] = f"{dica} A resposta é: {resposta_correta}."

with open('data/questions.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=4, ensure_ascii=False)
