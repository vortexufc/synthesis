import json
with open('data/questions.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

with open('temp_q.txt', 'w', encoding='utf-8') as out:
    for q in data:
        if q.get('andar_id') in [1, 2, 3]: # All questions to rewrite them simpler
            out.write(f"{q['id']} | {q['question']} | Ans: {q['options'][q['answer']]}\n")
