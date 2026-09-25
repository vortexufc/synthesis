# Changelog

Todas as mudanças notáveis do projeto "Lições Arcanas" serão documentadas neste arquivo.

## [Unreleased]
### Added
- **[Level-4] Ambientação e Iluminação do Andar de Física**: Criação do sistema de iluminação e ambientação com temática de **Laboratório Industrial / Eletromagnético** para todo o andar de Física. Inclui:
  - Controlador central `scripts/levels/sala_fisica.gd` anexado a todas as 12 salas de física e ao `template.tscn`.
  - `CanvasModulate` ambiente com tom de laboratório nítido e iluminado (`Color(0.74, 0.78, 0.84)` configurável via `@export`), garantindo excelente visibilidade e diferenciando totalmente as salas de física das masmorras escuras de química/alquimia.
  - Aura elétrica do `Player` com luz branca fria (`Color(0.88, 0.95, 1.0)`).
  - Nova cena reutilizável `scenes/Entidades/LuminariaFisica.tscn` com script `LuminariaFisica.gd`, simulando iluminação industrial/fluorescente com micro-oscilações de voltagem e faíscas ocasionais.
  - Detecção e iluminação automática de terminais/monitores com luz fosforescente verde-esmeralda e efeito scanline de tela.
  - Válvulas de canos com emissão periódica de partículas de vapor de pressão (`CPUParticles2D`) e exaustores industriais.
  - Efeitos luminosos nos colecionáveis: `ItemBateria` com halo dourado elétrico e faíscas estáticas; `ItemChip` com pulsação ciano neon.
  - Sensores ópticos / olhos luminosos nos robôs em patrulha (`Robo_P_Amarelo`, `Robo_P_Ciano`, `Robo_P_Laranja`, `Robo_G`), piscando dinamicamente em sincronia com o estado de alerta.
  - Portais de transição com iluminação temática azul de alta energia e ciano quântico.
  - Gerenciamento automático de inimigos da sala com drop de recompensa/chave ao derrotar todos os robôs.
- **[UI-11] Sistema de Clãs**: Criação de um sistema de clãs completo, permitindo que os jogadores criem, busquem, entrem e saiam de clãs. Inclui o painel principal (`TelaClas.tscn`), a tela de busca (`SemCla.tscn`), o popup de criação (`PopupCriarCla.tscn`), a tela de membros (`MeuCla.tscn`), e os componentes reutilizáveis para cards de clãs e de membros (`CardCla.tscn` e `CardMembro.tscn`). Gerenciado pelo novo singleton `ClanManager.gd` com persistência de dados online centralizada no Supabase (tabelas relacionais `Clas` e `MembrosCla` via chamadas REST assíncronas concorrentes).

- **[Fix-19] Suavização e Animação Orgânica da Logo do Menu Principal**: Reescrita a animação da logo para usar `Tween` contínuo assíncrono (`TRANS_SINE` com `EASE_IN_OUT`), combinando flutuação vertical graciosa, micro-balanço angular sutil e leve respiração de escala, eliminando a sensação de animação travada e os trancos por frame. O nó `Logo` foi atualizado para `texture_filter = 6` (Linear com Mipmaps Anisotrópico) e ativado `msaa_2d = 2` no projeto, eliminando o serrilhado de amostragem em monitores com diferentes resoluções sem recorrer a shaders nem escurecer a textura original.
- **[Fix-18] Correção de Stack underflow em LuminariaFisica.gd (Recursão infinita de setter)**: Corrigido o erro `ERROR: Stack underflow! (Engine Bug) at: exit_function (modules/gdscript/gdscript.h:530)` disparado durante a desserialização e manipulação das luminárias. O setter `@export var orientacao` chamava `atualizar_orientacao()`, que por sua vez reatribuía `orientacao = ...`, criando um loop de chamada recursiva infinito que estourava a pilha da VM do GDScript. A lógica de atualização visual foi isolada em `_aplicar_orientacao()` e os setters foram protegidos com `is_node_ready()` para garantir inicialização segura antes de acessar nós filhos.
- **[Fix-17] Fixação, Visual e Instanciação em Cena das Luminárias de Física**: As luminárias industriais estavam sendo geradas no chão transitável do meio da sala devido a um cálculo de coordenadas pelo centro do piso e usavam uma textura temporária. Foram criados sprites pixel-art dedicados de luminárias industriais blindadas com suporte de fixação para parafusamento na parede (`luminaria_parede.png`, com variações para parede Norte e paredes laterais Oeste/Leste). O script `LuminariaFisica.gd` recebeu suporte a `@tool` e setters reativos para atualizar visualmente no viewport da Godot ao trocar propriedades. Além disso, todas as 12 salas de física (`Sala_Física01.tscn` a `Sala_Física12.tscn`) e o `template.tscn` agora possuem o nó container `Luminarias` instanciado diretamente no arquivo de cena, permitindo que o desenvolvedor selecione, mova com o mouse, duplique ou altere parâmetros individualmente direto pelo editor da Godot.
- **[Fix-16] Crash ao derrotar inimigo em sala_fisica.gd (Casting a freed object)**: Ao derrotar um robô ou coletar um item, a remoção da entidade da SceneTree deixava um ponteiro liberado nas listas de luzes. O cast explícito `as PointLight2D` dentro de `_process()` causava o erro "Trying to cast a freed object". A iteração foi corrigida com loops reversos e validação estrita via `is_instance_valid()`, expurgando nós liberados sem tentar fazer type casting.
- **[Fix-15] Tela de Loading Presa (Loop Infinito)**: Corrigido um bug na `TelaClas.tscn` onde a mensagem "Carregando dados do clã online..." nunca sumia e acumulava requisições. O erro ocorria porque `_atualizar_tela()` acionava `load_clans()`, que ao terminar emitia o sinal `clan_updated`, chamando `_atualizar_tela()` recursivamente. Agora, o processo de leitura separa a flag `_is_loading` para bloquear recarregamentos circulares.
- **[Fix-14] Clãs repetidos nas Sugestões**: Removida a constante `MIN_SUGESTOES` em `ClanManager.get_sugestoes_clas()` que criava clones visuais do mesmo clã caso houvesse poucos clãs reais disponíveis no Supabase, confundindo a listagem na interface de busca.
- **[Fix-13] Erro de 'Nil' nos Cards (Godot 4)**: Corrigido o crash do jogo causado pelo erro de "Invalid assignment on a base object of type 'Nil'" ao preencher `set_info()` do `card_cla.gd` e `ranking_item.gd`. Foi adicionada uma proteção `await ready` para esperar a injeção das variáveis `@onready` logo após a instância da cena ser anexada à SceneTree.
- **[Fix-12] Top 3 de Clãs no Menu Principal (dados reais)**: O painel "Liderança da Semana" do `MainMenu` exibia dados mockados (textos estáticos na cena). Agora o `main_menu.gd` conecta o sinal `clan_list_updated` do `ClanManager` à nova função `_atualizar_leaderboard()`, que lê `ClanManager.get_top_clans()` e preenche os nós `Clan1/2/3` com nome e pontuação reais vindos do Supabase. Clãs ausentes exibem "---" como placeholder.

- **[Move-2] Patrulha Dinâmica nos Slimes Pequenos**: O script `res://scripts/enemy.gd` foi adicionado aos slimes pequenos (`slime_p01.tscn` a `slime_p04.tscn`) com parâmetros customizados de velocidade (`35.0`), vida máxima (`60.0`) e dano (`15.0`). Eles agora patrulham aleatoriamente as salas e param/se ocultam corretamente nas batalhas.
- **[BuildTGXP] Questões Locais por Inimigo**: sistema de `questoes_locais: Array` exportável no `EnemyTrigger`. Quando preenchido, substitui o banco Supabase para aquela batalha, permitindo questões hardcoded por inimigo.
- **[BuildTGXP] Questões de Química — Sala01**: `SlimeG_Sala01.tscn` com 5 questões fáceis (símbolo do ouro, estados da matéria, elemento mais abundante, número atômico do C, misturas).
- **[BuildTGXP] Questões de Química — Sala02**: 3 slimes com questões distintas — SlimeP_A (átomo, atmosfera, H₂O), SlimeP_B (O₂, substância pura, pH), SlimeP_C (reação química, metais alcalinos, tabela periódica).
- **[QuizManager] Suporte a `questoes_locais`**: `iniciar_batalha` verifica `enemy_data["questoes_locais"]`; se presente, usa essas questões e ignora o banco para a batalha atual. `reset_questions` também respeita a prioridade local.

### Fixed
- **[Fix-11] Correção de Sprite frames de Batalha (Inimigo Fixo / Cache na UI)**: Corrigido o bug em que a UI de batalha sempre mostrava o sprite frames do primeiro inimigo carregado (ou o default azul) ao invés do monstro correto. Agora, o `id_inimigo` é passado dinamicamente via `enemy_data` no sinal de colisão do trigger e o `QuizManager.gd` atualiza explicitamente a propriedade `sprite_frames` do nó `AnimatedSprite2D` na UI de batalha a cada início de combate, permitindo que o Slime Grande de Fogo da Sala 01 apareça corretamente com sua textura laranja ao invés da textura azul padrão.
- **[UI-9] Alinhamento Vertical dos Inimigos e Partículas**: Reajustado o posicionamento vertical do inimigo (`SpriteMonstro`), de sua barra de vida (`HealthEnemy`) e dos projéteis/explosões na cena de batalha para corresponder à mesma altura do jogador (mago) no cenário (baseline em Y = 397 e altura dos projéteis em Y = 350).
- **[Fix-10] Proporções em Tela Cheia (elementos fora do lugar)**: Adicionada a seção `[display]` em `project.godot` com resolução base `1280×720`, `stretch/mode = canvas_items` e `stretch/aspect = keep`. Sem essa configuração, o Godot escalava o viewport livremente ao entrar em fullscreen, deslocando a UI e os inimigos de suas posições originais. Agora o conteúdo é escalado proporcionalmente mantendo o aspect ratio 16:9, com barras pretas opcionais nas bordas.


- **[Fix-8] Bug de Câmera da Batalha (Inimigos Subindo/Sumindo)**: Substituição do `queue_free()` diferido por `remove_child()` seguido de `child.free()` imediato no bloco de inicialização do clone do player em `QuizManager.gd`. Isso impede que a `Camera2D` do clone do player entre ativa no `SceneTree` por um único frame, evitando que ela sequestre o viewport e cause o desalinhamento vertical dos inimigos e da interface gráfica de batalha.
- **[BugFix Crítico] Loop de dano infinito ao expirar o timer**: quando `tempo_restante` chegava a 0, `_on_botao_pressionado(-1)` disparava dano. Mas na nova rodada `atualizar_pergunta` reativava `tempo_rodando = true` com `tempo_restante = 0`, causando dano imediato em loop a cada frame — o jogador morria mesmo acertando todas as questões. **Correção**: (1) flag `_processando_resposta` bloqueia re-entrada; (2) `atualizar_pergunta` só reativa o timer se `tempo_restante > 0`; (3) `_process` para o timer antes de chamar o botão; (4) caminho de timeout em `mostrar_resultado` agora tem `await` de 0.5s.


- **[Dev-1] Script `scripts/enemy.gd`**: inimigo com variáveis exportáveis `vida_maxima`, `velocidade`, `dano` e `distancia_patrulha`. Implementa patrulha vai-e-vem em linha reta via `_physics_process`.
- **[Dev-1] Lógica de patrulha**: inimigo inverte direção ao atingir `distancia_patrulha` pixels do ponto de origem. Flip automático do sprite conforme direção.
- **[Dev-1] Integração com EnemyTrigger**: ao player entrar na área, o pai do trigger (inimigo) é notificado via `_on_batalha_iniciada`, pausando a patrulha antes de emitir `iniciar_batalha`.
- **[Dev-1] `andar_id = 1`** adicionado ao `enemy_data` do `EnemyTrigger`. O `QuizManager` lê esse campo e chama `DatabaseManager.puxar_perguntas(andar_id)` dinamicamente, garantindo que o Andar 1 carregue perguntas de Biologia.
- **[Dev-1] Cena `Evil_Wizzard.tscn` promovida** para cena completa: nó raiz `CharacterBody2D` com `enemy.gd`, `CollisionShape2D` (cápsula corporal) e filho `EnemyTrigger` com `Area2D` de detecção.
- **[Trap-1] Mímico Físico**: o baú falso agora possui um `StaticBody2D` ativado dinamicamente após a armadilha disparar, bloqueando a passagem do jogador sobre o baú.
- **[Combat-Fix] Vida Zerada**: corrigido o bug em que o jogador renascia com `0 HP` ao retornar para o Menu Principal pela tela de derrota e tentar jogar novamente. `PlayerStats.resetar_vida()` agora é chamado corretamente.
- Novas constantes `GOLEM_MENOR` e `GOLEM_ANTIGO` em `enemy_trigger.gd` para parametrizar inimigos.
- Mensagem de log de combate (`[Dev-1 / Combat-5] Batalha: X questões / Ys / Andar Z`) ao iniciar a batalha.
- Sinal global `fim_de_jogo(vitoria: bool)` para comunicar o término de uma partida ao invés de print duro no console.
- Cena de Game Over/Vitória (`scenes/ui/game_over.tscn` e respectivo script) com estado visual variável, estatísticas e botões de re-tentativa e menu principal.

### Changed
- Validação do nó `EnemyTrigger` nas salas de teste (`teste_player.tscn`). Ele utiliza as propriedades default `num_questoes = 5` e `duracao_batalha = 300.0` (o que satisfaz `num_questoes >= 1` e `duracao_batalha = 300.0`). Observou-se a ausência do trigger instanciado diretamente em `sala_direita.tscn` e `sala_esquerda.tscn` (apenas suas variantes `00` existem e não possuem o trigger instanciado).
- Adicionado parâmetro de estatísticas reais na tela de Game Over/Vitória, exibindo tempo sobrevivido, precisão e dano causado.
- Atualizado o sinal `batalha_encerrada` para receber parâmetro booleano de vitória, permitindo ao `EnemyTrigger` reativar-se (com `show` e `monitoring`) apenas em caso de derrota, enquanto em vitória ele permanece oculto e inativo.
## [2026-05-12] — Merge Level-3: Planejamento do Andar 2
### Added
- Tileset RF_Catacombs_v1.0: sprites de velas, tochas, espinhos, decorações e mapa principal.
- Tileset 2D Pixel Dungeon Asset Pack v2.0: animações de items e armadilhas (tochas, picos).
- Novas salas: Sala_Inicio00, Salas_Baixo/00/01/02, Salas_Cima/01, Salas_Direita/01, Sala_Esquerda/01.

### Changed
- Camera2D do Player: limites do mapa (limit_right=2048, limit_bottom=1410) e position_smoothing_enabled=true.
- Reorganizacao de salas: ambas as versoes de sala_esquerda.tscn preservadas em novos paths.

### Conflicts Resolved
- scenes/player.tscn: unique_ids do main mantidos + camera limits do Level-3 integrados.
- Rename/rename de scenes/sala_esquerda.tscn: ambas as versoes reorganizadas mantidas.
