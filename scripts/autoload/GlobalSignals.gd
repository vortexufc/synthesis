extends Node

@warning_ignore("unused_signal")
# [Combat-4] EnemyData: { "num_questoes": int, "duracao_batalha": float }
signal iniciar_batalha(enemy_data: Dictionary)
@warning_ignore("unused_signal")
signal batalha_encerrada
@warning_ignore("unused_signal")
signal mimico_ativado(player: Node) # [Trap-1] Emitido ao interagir com o Bau Falso
@warning_ignore("unused_signal")
signal fim_de_jogo(vitoria: bool)
