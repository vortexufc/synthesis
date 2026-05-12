# Changelog

Todas as mudanças notáveis do projeto "Lições Arcanas" serão documentadas neste arquivo.

## [Unreleased]
### Added
- Novas constantes `GOLEM_MENOR` e `GOLEM_ANTIGO` em `enemy_trigger.gd` para parametrizar inimigos.
- Mensagem de log de combate (`[Combat-5] Batalha: X questões / Ys ao iniciar batalha.`) ao iniciar a batalha.
- Sinal global `fim_de_jogo(vitoria: bool)` para comunicar o término de uma partida ao invés de print duro no console.
- Cena de Game Over/Vitória (`scenes/ui/game_over.tscn` e respectivo script) com estado visual variável, estatísticas e botões de re-tentativa e menu principal.

### Changed
- Validação do nó `EnemyTrigger` nas salas de teste (`teste_player.tscn`). Ele utiliza as propriedades default `num_questoes = 5` e `duracao_batalha = 300.0` (o que satisfaz `num_questoes >= 1` e `duracao_batalha = 300.0`). Observou-se a ausência do trigger instanciado diretamente em `sala_direita.tscn` e `sala_esquerda.tscn` (apenas suas variantes `00` existem e não possuem o trigger instanciado).

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
