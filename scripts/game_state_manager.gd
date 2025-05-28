extends Node

# Game states enum
enum GameState {
	MAIN_MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	BATTLE,
	DIALOGUE,
	INVENTORY
}

# Current game state
var current_state: GameState = GameState.MAIN_MENU

# Signal for state changes
signal state_changed(new_state: GameState)

# Function to change game state
func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		print("[GameStateManager] Tentativa de mudar para o mesmo estado: ", new_state)
		return
		
	print("\n[GameStateManager] ====== MUDANDO ESTADO ======")
	print("[GameStateManager] Estado atual: ", current_state)
	print("[GameStateManager] Novo estado: ", new_state)
	
	current_state = new_state
	state_changed.emit(current_state)
	
	# Handle state-specific logic
	match current_state:
		GameState.MAIN_MENU:
			print("[GameStateManager] Executando lógica do estado MAIN_MENU")
			handle_main_menu()
		GameState.PLAYING:
			print("[GameStateManager] Executando lógica do estado PLAYING")
			handle_playing()
		GameState.PAUSED:
			print("[GameStateManager] Executando lógica do estado PAUSED")
			handle_paused()
		GameState.GAME_OVER:
			print("[GameStateManager] Executando lógica do estado GAME_OVER")
			handle_game_over()
		GameState.BATTLE:
			print("[GameStateManager] Executando lógica do estado BATTLE")
			handle_battle()
		GameState.DIALOGUE:
			print("[GameStateManager] Executando lógica do estado DIALOGUE")
			handle_dialogue()
		GameState.INVENTORY:
			print("[GameStateManager] Executando lógica do estado INVENTORY")
			handle_inventory()
	
	print("[GameStateManager] Estado alterado com sucesso para: ", current_state)
	print("[GameStateManager] ====== FIM DA MUDANÇA DE ESTADO ======\n")

# State handlers
func handle_main_menu() -> void:
	# Pausa o jogo quando no menu principal
	get_tree().paused = true

func handle_playing() -> void:
	# Despausa o jogo quando jogando
	get_tree().paused = false

func handle_paused() -> void:
	# Pausa o jogo
	get_tree().paused = true

func handle_game_over() -> void:
	# Pausa o jogo quando game over
	get_tree().paused = true

func handle_battle() -> void:
	# Pausa o jogo durante batalha
	get_tree().paused = true

func handle_dialogue() -> void:
	# Pausa o jogo durante diálogo
	get_tree().paused = true

func handle_inventory() -> void:
	# Pausa o jogo durante inventário
	get_tree().paused = true 
