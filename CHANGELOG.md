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
