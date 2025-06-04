extends "res://scripts/ui/base_menu.gd"

# Referências para autoloads
@onready var state_manager = get_node("/root/GameStateManager")
@onready var scene_manager = get_node("/root/SceneManager")
@onready var ui_manager = get_node("/root/UIManager")
@onready var game_manager = get_node("/root/GameManager")

func _ready():
	super._ready()
	connect_buttons()

func connect_buttons():
	# Conecta os botões aos seus respectivos handlers
	var resume_button = $MenuContainer/ResumeButton
	var save_button = $MenuContainer/SaveButton
	var restart_button = $MenuContainer/RestartButton
	var options_button = $MenuContainer/OptionsButton
	var main_menu_button = $MenuContainer/MainMenuButton
	var quit_button = $MenuContainer/QuitButton
	
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if options_button:
		options_button.pressed.connect(_on_options_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_resume_pressed():
	print("[PauseMenu] Botão Continuar pressionado")
	# Anima o botão
	animate_button_press($MenuContainer/ResumeButton)
	# Muda o estado do jogo
	state_manager.change_state(state_manager.GameState.PLAYING)
	# Fecha o menu via UIManager
	ui_manager.hide_ui("pause_menu")

func _on_save_pressed():
	print("[PauseMenu] Botão Salvar pressionado")
	# Anima o botão
	animate_button_press($MenuContainer/SaveButton)
	# Salva o jogo
	game_manager.save_game()
	print("[PauseMenu] Jogo salvo com sucesso!")

func _on_restart_pressed():
	print("[PauseMenu] Botão Reiniciar pressionado")
	# Anima o botão
	animate_button_press($MenuContainer/RestartButton)
	# Reseta o jogo
	game_manager.reset_game()
	# Muda o estado do jogo
	state_manager.change_state(state_manager.GameState.PLAYING)
	# Recarrega a cena atual
	scene_manager.change_scene("world")
	# Fecha o menu via UIManager
	ui_manager.hide_ui("pause_menu")
	print("[PauseMenu] Fase reiniciada!")

func _on_options_pressed():
	print("[PauseMenu] Botão Opções pressionado")
	# Anima o botão
	animate_button_press($MenuContainer/OptionsButton)
	# Mostra o menu de opções via UIManager
	ui_manager.show_ui("options_menu")

func _on_main_menu_pressed():
	print("[PauseMenu] Botão Menu Principal pressionado")
	# Anima o botão
	animate_button_press($MenuContainer/MainMenuButton)
	# Muda o estado do jogo
	state_manager.change_state(state_manager.GameState.MAIN_MENU)
	# Carrega a cena do menu principal
	scene_manager.change_scene("main_menu")
	# Fecha o menu via UIManager
	ui_manager.hide_ui("pause_menu")

func _on_quit_pressed():
	print("[PauseMenu] Botão Sair pressionado")
	# Anima o botão
	animate_button_press($MenuContainer/QuitButton)
	# Sai do jogo
	get_tree().quit()

func animate_button_press(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(button, "scale", Vector2(1, 1), 0.1) 
