extends "res://scripts/ui/base_menu.gd"

# Referências para autoloads
@onready var game_manager = get_node("/root/GameManager")
@onready var state_manager = get_node("/root/GameStateManager")
@onready var scene_manager = get_node("/root/SceneManager")

func _ready():
	super._ready()
	connect_buttons()

func connect_buttons():
	# Conecta os botões aos seus respectivos handlers
	var restart_button = $MenuContainer/RestartButton
	var main_menu_button = $MenuContainer/MainMenuButton
	var quit_button = $MenuContainer/QuitButton
	
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_restart_pressed():
	# Anima o botão
	animate_button_press($MenuContainer/RestartButton)
	
	# Reseta o jogo
	game_manager.reset_game()
	
	# Muda o estado do jogo
	state_manager.change_state(state_manager.GameState.PLAYING)
	
	# Carrega a cena do mundo
	scene_manager.change_scene("world")
	
	# Anima a saída do menu
	animate_menu_out()

func _on_main_menu_pressed():
	# Anima o botão
	animate_button_press($MenuContainer/MainMenuButton)
	
	# Muda o estado do jogo
	state_manager.change_state(state_manager.GameState.MAIN_MENU)
	
	# Carrega a cena do menu principal
	scene_manager.change_scene("main_menu")
	
	# Anima a saída do menu
	animate_menu_out()

func _on_quit_pressed():
	# Anima o botão
	animate_button_press($MenuContainer/QuitButton)
	
	# Sai do jogo
	get_tree().quit() 