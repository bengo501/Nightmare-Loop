extends Control

@onready var new_game_button = $MenuContainer/NewGameButton
@onready var load_game_button = $MenuContainer/LoadGameButton
@onready var options_button = $MenuContainer/OptionsButton
@onready var credits_button = $MenuContainer/CreditsButton
@onready var quit_button = $MenuContainer/QuitButton

func _ready():
	# Conecta os sinais dos botões
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	options_button.pressed.connect(_on_options_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Verifica se existe save para habilitar o botão de carregar
	load_game_button.disabled = not FileAccess.file_exists("user://savegame.save")

func _on_new_game_pressed():
	# Inicia um novo jogo
	get_node("/root/GameManager").reset_game()
	get_node("/root/SceneManager").change_scene("world")

func _on_load_game_pressed():
	# Carrega o jogo salvo
	get_node("/root/GameManager").load_game()
	get_node("/root/SceneManager").change_scene("world")

func _on_options_pressed():
	# Mostra o menu de opções
	get_node("/root/UIManager").show_ui("options_menu")

func _on_credits_pressed():
	# Mostra os créditos
	get_node("/root/UIManager").show_ui("credits")

func _on_quit_pressed():
	# Sai do jogo
	get_tree().quit() 