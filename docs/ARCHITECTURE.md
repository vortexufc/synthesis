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

5. **Sistema de Clãs (Arquitetura de Persistência Online)**:
   - **ClanManager Autoload**: Singleton centralizador de regras de negócio de clãs. Atua como controlador de fluxo assíncrono e gerencia o cache em tempo de execução dos clãs e membros.
   - **Persistência de Dados**: O estado e dados de clãs e filiações são armazenados de forma totalmente centralizada online no Supabase (tabelas `Clas` e `MembrosCla`), além do metadado `cla` em `/auth/v1/user`.
   - **Verificação Automática de Sincronia (Autosync)**: Durante a inicialização, o `ClanManager` consulta o Supabase para certificar-se de que o jogador está filiado a um clã válido e sincroniza seu metadado local.
   - **Interface Dinâmica (Dynamic View Pattern)**: `TelaClas.tscn` instancia dinamicamente `SemCla.tscn` ou `MeuCla.tscn` de forma assíncrona após garantir que as informações online foram carregadas no cache do `ClanManager`.
