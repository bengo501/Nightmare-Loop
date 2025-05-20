extends Control

@onready var resume_button = $MenuContainer/ResumeButton
@onready var save_button = $MenuContainer/SaveButton
@onready var options_button = $MenuContainer/OptionsButton
@onready var main_menu_button = $MenuContainer/MainMenuButton
@onready var quit_button = $MenuContainer/QuitButton
@onready var background = $Background
@onready var menu_container = $MenuContainer

var tween: Tween
var button_hover_tweens = {}

func _ready():
	# Conecta os sinais dos botões
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	options_button.pressed.connect(_on_options_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Estilização dos botões
	var menu_buttons = [resume_button, save_button, options_button, main_menu_button, quit_button]
	for button in menu_buttons:
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
		
		# Conecta os sinais de hover
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
		button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
	
	# Processa input mesmo quando o jogo está pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Inicializa o menu com opacidade 0
	background.modulate.a = 0
	menu_container.modulate.a = 0
	menu_container.scale = Vector2(0.8, 0.8)
	
	# Prepara os botões para a animação
	for button in menu_buttons:
		button.modulate.a = 0
		button.position.x = -200  # Posição inicial fora da tela
	
	# Anima a entrada do menu
	animate_menu_in()

func _on_button_mouse_entered(button: Button):
	if button_hover_tweens.has(button):
		button_hover_tweens[button].kill()
	
	button_hover_tweens[button] = create_tween()
	button_hover_tweens[button].tween_property(button, "scale", Vector2(1.1, 1.1), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	button_hover_tweens[button].parallel().tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.2)

func _on_button_mouse_exited(button: Button):
	if button_hover_tweens.has(button):
		button_hover_tweens[button].kill()
	
	button_hover_tweens[button] = create_tween()
	button_hover_tweens[button].tween_property(button, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	button_hover_tweens[button].parallel().tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func animate_menu_in():
	# Anima o background
	tween = create_tween()
	tween.tween_property(background, "modulate:a", 0.5, 0.3)
	
	# Anima o container do menu
	tween.parallel().tween_property(menu_container, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(menu_container, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Anima os botões sequencialmente
	var menu_buttons = [resume_button, save_button, options_button, main_menu_button, quit_button]
	for i in range(menu_buttons.size()):
		var button = menu_buttons[i]
		var target_x = button.position.x + 200  # Posição final
		
		tween = create_tween()
		tween.tween_property(button, "modulate:a", 1.0, 0.2).set_delay(0.1 * i)
		tween.parallel().tween_property(button, "position:x", target_x, 0.3).set_delay(0.1 * i).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func animate_menu_out():
	tween = create_tween()
	tween.tween_property(background, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(menu_container, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(menu_container, "scale", Vector2(0.8, 0.8), 0.2)
	
	# Anima os botões saindo para a esquerda
	var menu_buttons = [resume_button, save_button, options_button, main_menu_button, quit_button]
	for i in range(menu_buttons.size()):
		var button = menu_buttons[i]
		tween.parallel().tween_property(button, "position:x", button.position.x - 200, 0.2).set_delay(0.05 * i)
	
	await tween.finished
	queue_free()

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # Tecla ESC
		_on_resume_pressed()

func _on_resume_pressed():
	# Despausa o jogo
	get_tree().paused = false
	get_node("/root/GameStateManager").change_state(get_node("/root/GameStateManager").GameState.PLAYING)
	animate_menu_out()

func _on_save_pressed():
	# Salva o jogo
	get_node("/root/GameManager").save_game()
	animate_button_press(save_button)

func _on_options_pressed():
	# Mostra o menu de opções
	get_node("/root/UIManager").show_ui("options_menu")
	animate_button_press(options_button)

func _on_main_menu_pressed():
	# Volta para o menu principal
	get_tree().paused = false
	get_node("/root/SceneManager").change_scene("main_menu")
	animate_button_press(main_menu_button)

func _on_quit_pressed():
	# Sai do jogo
	animate_button_press(quit_button)
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func animate_button_press(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(button, "scale", Vector2(1, 1), 0.1) 
