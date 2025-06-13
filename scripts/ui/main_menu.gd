extends Control

# Referências para autoloads
@onready var state_manager = get_node("/root/GameStateManager")
@onready var scene_manager = get_node("/root/SceneManager")
@onready var ui_manager = get_node("/root/UIManager")
@onready var game_manager = get_node("/root/GameManager")

func _ready():
	$NewGameButton.pressed.connect(_on_new_game_pressed)
	$OptionsButton.pressed.connect(_on_options_pressed)
	$CreditsButton.pressed.connect(_on_credits_pressed)
	$QuitButton.pressed.connect(_on_quit_pressed)

func _on_new_game_pressed():
	# Primeiro reseta o jogo
	game_manager.reset_game()
	
	# Esconde o menu atual
	queue_free()
	
	# Muda a cena
	scene_manager.change_scene("world")
	
	# Muda o estado para PLAYING
	state_manager.change_state(state_manager.GameState.PLAYING)

func _on_options_pressed():
	ui_manager.hide_ui("main_menu")
	ui_manager.show_ui("options_menu")

func _on_credits_pressed():
	ui_manager.show_ui("credits")

func _on_quit_pressed():
	get_tree().quit() 
