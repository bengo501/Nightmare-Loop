extends "res://scripts/ui/base_menu.gd"

# Referências para autoloads
@onready var state_manager = get_node("/root/GameStateManager")
@onready var scene_manager = get_node("/root/SceneManager")
@onready var ui_manager = get_node("/root/UIManager")

func _ready():
	super._ready()
	connect_buttons()

func connect_buttons():
	# Conecta os botões aos seus respectivos handlers
	var resume_button = $MenuContainer/ResumeButton
	var options_button = $MenuContainer/OptionsButton
	var main_menu_button = $MenuContainer/MainMenuButton
	var quit_button = $MenuContainer/QuitButton
	
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
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

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # Tecla ESC
		_on_resume_pressed()

func animate_button_press(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(button, "scale", Vector2(1, 1), 0.1) 
