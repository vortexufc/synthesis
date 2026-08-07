import urllib.request, json, time, urllib.error

key = "sk-ZJU1r5DAVqS1IKwzMlMMxMnMZV9PKwXdoOF8vjrlEd0aNJfHIihpOi9iMNf6kdTQ"
url = "https://opencode.ai/zen/v1/chat/completions"

models = [
    "deepseek-v4-flash-free",
    "mimo-v2.5-free",
    "ling-3.0-flash-free",
    "nemotron-3-ultra-free",
    "north-mini-code-free",
    "laguna-s-2.1-free",
    "longcat-2.0-free"
]

for model in models:
    data = json.dumps({
        "model": model,
        "messages": [{"role": "user", "content": "Olá, me dê uma dica sobre água em 1 frase."}],
        "max_tokens": 100
    }).encode('utf-8')

    req = urllib.request.Request(url, data=data, headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {key}",
        "User-Agent": "Mozilla/5.0"
    })

    try:
        with urllib.request.urlopen(req, timeout=5) as response:
            print(f"[{model}] OK")
    except Exception as e:
        pass
