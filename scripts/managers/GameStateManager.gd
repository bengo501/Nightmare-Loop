extends Node

# Estados possíveis do jogo
enum GameState {
	PLAYING,    # Jogando normalmente
	PAUSED,     # Jogo pausado
	GAME_OVER,  # Game over
	MENU,       # Menu principal
	DIALOGUE,   # Em diálogo
	BATTLE,     # Em batalha
	SKILL_TREE  # Menu de habilidades
}

# Estado atual do jogo
var current_state: GameState = GameState.PLAYING

# Sinal para quando o estado mudar
signal state_changed(new_state: GameState)

func _ready():
	print("[GameStateManager] Inicializando...")
	change_state(GameState.PLAYING)

func change_state(new_state: GameState):
	if new_state != current_state:
		print("[GameStateManager] Mudando estado de %s para %s" % [current_state, new_state])
		current_state = new_state
		state_changed.emit(new_state)
		
		# Aplica efeitos do estado
		match new_state:
			GameState.PLAYING:
				get_tree().paused = false
			GameState.PAUSED:
				get_tree().paused = true
			GameState.GAME_OVER:
				get_tree().paused = true
			GameState.MENU:
				get_tree().paused = true
			GameState.DIALOGUE:
				get_tree().paused = true
			GameState.BATTLE:
				get_tree().paused = false  # Não pausa durante a batalha
			GameState.SKILL_TREE:
				get_tree().paused = true 