extends Node

# chaves do nosso banco no supabase
var supabase_url: String = "https://uszmgqludyymspsarciw.supabase.co"
var supabase_key: String = "sb_publishable_mpz-s86wXECtwvBd0TnYoQ_qWQauy2S"

# no q cuida das requisições
var http_request: HTTPRequest

func _ready() -> void:
    # cria e add o http na cena
    http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(_on_request_completed)
    
    print("banco carregado!")

# funcao pra montar o header e mandar o get/post...
# endpoint tipo: "/rest/v1/alunos"
func make_request(endpoint: String, method: HTTPClient.Method, data: Dictionary = {}) -> void:
    var url: String = supabase_url + endpoint
    
    # headers q o supabase pede
    var headers: PackedStringArray = [
        "apikey: " + supabase_key,
        "Authorization: Bearer " + supabase_key,
        "Content-Type: application/json",
        "Prefer: return=representation"
    ]
    
    var body: String = ""
    # converte pra json se tiver data
    if not data.is_empty():
        body = JSON.stringify(data)

    # manda a req asincrona
    var error = http_request.request(url, headers, method, body)
    
    if error != OK:
        push_error("deu ruim na req pra: " + url)

# quando o supabase responde cai aqui
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
    if response_code >= 200 and response_code < 300:
        # deu bom
        var json: JSON = JSON.new()
        var error = json.parse(body.get_string_from_utf8())
        
        if error == OK:
            print("resposta do banco chegou: ", json.data)
            # depois criamos o sinal aqui do teste
        else:
            push_error("erro no parse do json")
    else:
        # qndo da erro 400+
        push_error("erro http: " + str(response_code) + " | " + body.get_string_from_utf8())
