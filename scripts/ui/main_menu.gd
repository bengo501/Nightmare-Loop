extends Control

@onready var new_game_button = $MenuContainer/NewGameButton
@onready var load_game_button = $MenuContainer/LoadGameButton
@onready var options_button = $MenuContainer/OptionsButton
@onready var credits_button = $MenuContainer/CreditsButton
@onready var quit_button = $MenuContainer/QuitButton
@onready var menu_container = $MenuContainer

func _ready():
	# Conecta os sinais dos botões
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	options_button.pressed.connect(_on_options_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Verifica se existe save para habilitar o botão de carregar
	load_game_button.disabled = not FileAccess.file_exists("user://savegame.save")

	# Estilização e animação dos botões
	for button in menu_container.get_children():
		if button is Button:
			button.mouse_entered.connect(func(): _animate_button(button, 1.1, Color(1,0.2,0.2))) # hover vermelho pálido
			button.mouse_exited.connect(func(): _animate_button(button, 1.0, Color(0.8,0.8,0.8))) # normal
			button.pressed.connect(func(): _animate_button(button, 0.95, Color(0.5,0,0))) # clique escuro
			# StyleBoxFlat para visual sombrio
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.1, 0, 0, 0.85)
			style.border_color = Color(0.8, 0, 0)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.corner_radius_top_left = 8
			style.corner_radius_top_right = 8
			style.corner_radius_bottom_right = 8
			style.corner_radius_bottom_left = 8
			button.add_theme_stylebox_override("normal", style)
			var style_hover = style.duplicate()
			style_hover.bg_color = Color(0.2, 0, 0, 1)
			button.add_theme_stylebox_override("hover", style_hover)
			var style_pressed = style.duplicate()
			style_pressed.bg_color = Color(0.4, 0, 0, 1)
			button.add_theme_stylebox_override("pressed", style_pressed)
			button.add_theme_color_override("font_color", Color(1, 0.8, 0.8))
			button.add_theme_color_override("font_color_hover", Color(1, 0.4, 0.4))
			button.add_theme_color_override("font_color_pressed", Color(1, 0, 0))
			button.add_theme_constant_override("outline_size", 2)
			button.add_theme_color_override("outline_color", Color(0.2,0,0))

func _animate_button(button, target_scale, color):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(target_scale, target_scale), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", color, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_new_game_pressed():
	# Inicia um novo jogo
	var game_manager = get_node("/root/GameManager")
	var state_manager = get_node("/root/GameStateManager")
	var scene_manager = get_node("/root/SceneManager")
	
	# Reseta o jogo
	game_manager.reset_game()
	
	# Muda o estado para PLAYING
	state_manager.change_state(state_manager.GameState.PLAYING)
	
	# Carrega a cena do mundo
	scene_manager.change_scene("world")

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
