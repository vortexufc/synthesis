# Arquitetura - Lições Arcanas

## Padrões Adotados
1. **Autoloads / Singletons**:
   - `GlobalSignals`: Eventos centralizados para comunicação entre cenas.
   - `PlayerStats`: Mantém a fonte única de verdade (Single Source of Truth) para o HP e outros status do jogador.

2. **Cenas Modulares**:
   - Inimigos, como o `EnemyTrigger`, possuem atributos exportados (`num_questoes`, `duracao_batalha`) para que possam ser facilmente configurados no Inspetor de Cenas (ex: Golem Menor vs Golem Antigo) sem duplicar código.

3. **Arquitetura Orientada a Eventos**:
   - Uso intensivo de Signals do Godot para evitar forte acoplamento entre os componentes de UI (HUD, Menus) e a lógica de combate/movimentação.

4. **Instanciação e Limpeza de Manequins de UI**:
   - Ao instanciar cenas de entidades complexas como clones visuais para a interface (ex: clone do `Player` na batalha), componentes desnecessários para a interface (como `Camera2D`, `CollisionShape2D` e `AudioStreamPlayer2D`) devem ser removidos **imediatamente** via `remove_child(child)` seguido de `child.free()`, antes do nó pai ser inserido no `SceneTree`.
   - O uso de `queue_free()` deve ser evitado nesse cenário de higienização de clones, pois sua remoção diferida permite que sub-nós (como `Camera2D`) entrem ativos na Scene Tree por um frame, provocando sequestro de Viewport, deslocamento vertical indesejado de inimigos/UI e glitches visuais.

5. **Sistema de Clãs (Arquitetura Híbrida de Persistência)**:
   - **ClanManager Autoload**: Singleton centralizador de regras de negócio de clãs. Atua como controlador de fluxo e cache do banco de dados local.
   - **Persistência de Dados**: O estado de filiação do jogador é salvo no Supabase (coluna metadata `cla` em `/auth/v1/user`), enquanto a base global de clãs e integrantes é armazenada em formato JSON local em `user://clans.json` para suportar partidas off-line e emulação de ambiente multi-player local.
   - **Verificação Automática de Sincronia (Autosync)**: Durante a inicialização, o `ClanManager` varre os integrantes do clã armazenado localmente para garantir que o jogador ainda faz parte da guilda. Caso tenha sido expulso ou o clã desfeito por outro jogador, o estado local é corrigido automaticamente para "Nenhum".
   - **Interface Dinâmica (Dynamic View Pattern)**: `TelaClas.tscn` instacia dinamicamente `SemCla.tscn` ou `MeuCla.tscn` sob demanda com base no status do jogador, garantindo desacoplamento de telas e facilidade de manutenção.
