# Changelog

Todas as mudanças notáveis do projeto "Lições Arcanas" serão documentadas neste arquivo.

## [Unreleased]
### Added
- **[BuildTGXP] Questões Locais por Inimigo**: sistema de `questoes_locais: Array` exportável no `EnemyTrigger`. Quando preenchido, substitui o banco Supabase para aquela batalha, permitindo questões hardcoded por inimigo.
- **[BuildTGXP] Questões de Química — Sala01**: `SlimeG_Sala01.tscn` com 5 questões fáceis (símbolo do ouro, estados da matéria, elemento mais abundante, número atômico do C, misturas).
- **[BuildTGXP] Questões de Química — Sala02**: 3 slimes com questões distintas — SlimeP_A (átomo, atmosfera, H₂O), SlimeP_B (O₂, substância pura, pH), SlimeP_C (reação química, metais alcalinos, tabela periódica).
- **[QuizManager] Suporte a `questoes_locais`**: `iniciar_batalha` verifica `enemy_data["questoes_locais"]`; se presente, usa essas questões e ignora o banco para a batalha atual. `reset_questions` também respeita a prioridade local.

### Fixed
- **[Fix-9] Proporções em Tela Cheia (elementos fora do lugar)**: Adicionada a seção `[display]` em `project.godot` com resolução base `1280×720`, `stretch/mode = canvas_items` e `stretch/aspect = keep`. Sem essa configuração, o Godot escalava o viewport livremente ao entrar em fullscreen, deslocando a UI e os inimigos de suas posições originais. Agora o conteúdo é escalado proporcionalmente mantendo o aspect ratio 16:9, com barras pretas opcionais nas bordas.
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
