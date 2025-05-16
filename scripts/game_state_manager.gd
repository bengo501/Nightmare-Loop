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
		return
		
	current_state = new_state
	state_changed.emit(current_state)
	
	# Handle state-specific logic
	match current_state:
		GameState.MAIN_MENU:
			handle_main_menu()
		GameState.PLAYING:
			handle_playing()
		GameState.PAUSED:
			handle_paused()
		GameState.GAME_OVER:
			handle_game_over()
		GameState.BATTLE:
			handle_battle()
		GameState.DIALOGUE:
			handle_dialogue()
		GameState.INVENTORY:
			handle_inventory()

# State handlers
func handle_main_menu() -> void:
	# Implement main menu logic
	pass

func handle_playing() -> void:
	# Implement playing state logic
	pass

func handle_paused() -> void:
	# Implement pause state logic
	pass

func handle_game_over() -> void:
	# Implement game over logic
	pass

func handle_battle() -> void:
	# Implement battle state logic
	pass

func handle_dialogue() -> void:
	# Implement dialogue state logic
	pass

func handle_inventory() -> void:
	# Implement inventory state logic
	pass 