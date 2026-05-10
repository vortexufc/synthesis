# Arquitetura - Lições Arcanas

## Padrões Adotados
1. **Autoloads / Singletons**:
   - `GlobalSignals`: Eventos centralizados para comunicação entre cenas.
   - `PlayerStats`: Mantém a fonte única de verdade (Single Source of Truth) para o HP e outros status do jogador.

2. **Cenas Modulares**:
   - Inimigos, como o `EnemyTrigger`, possuem atributos exportados (`num_questoes`, `duracao_batalha`) para que possam ser facilmente configurados no Inspetor de Cenas (ex: Golem Menor vs Golem Antigo) sem duplicar código.

3. **Arquitetura Orientada a Eventos**:
   - Uso intensivo de Signals do Godot para evitar forte acoplamento entre os componentes de UI (HUD, Menus) e a lógica de combate/movimentação.
