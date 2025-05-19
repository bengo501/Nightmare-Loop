extends Control

@onready var resume_button = $MenuContainer/ResumeButton
@onready var save_button = $MenuContainer/SaveButton
@onready var options_button = $MenuContainer/OptionsButton
@onready var main_menu_button = $MenuContainer/MainMenuButton
@onready var quit_button = $MenuContainer/QuitButton

func _ready():
	# Conecta os sinais dos botões
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	options_button.pressed.connect(_on_options_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Processa input mesmo quando o jogo está pausado
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # Tecla ESC
		_on_resume_pressed()

func _on_resume_pressed():
	# Despausa o jogo
	get_tree().paused = false
	get_node("/root/GameStateManager").change_state(get_node("/root/GameStateManager").GameState.PLAYING)
	queue_free()

func _on_save_pressed():
	# Salva o jogo
	get_node("/root/GameManager").save_game()

func _on_options_pressed():
	# Mostra o menu de opções
	get_node("/root/UIManager").show_ui("options_menu")

func _on_main_menu_pressed():
	# Volta para o menu principal
	get_tree().paused = false
	get_node("/root/SceneManager").change_scene("main_menu")

func _on_quit_pressed():
	# Sai do jogo
	get_tree().quit() 