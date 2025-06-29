extends CanvasLayer

# Referências para autoloads
@onready var state_manager = get_node_or_null("/root/GameStateManager")
@onready var scene_manager = get_node_or_null("/root/SceneManager")
@onready var ui_manager = get_node_or_null("/root/UIManager")
@onready var game_manager = get_node_or_null("/root/GameManager")

func _ready():
	connect_buttons()

func connect_buttons():
	# Conecta apenas os 3 botões necessários
	var resume_button = $MenuContainer/ResumeButton
	var main_menu_button = $MenuContainer/MainMenuButton
	var quit_button = $MenuContainer/QuitButton
	
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_resume_pressed():
	print("[PauseMenu] Botão Continuar pressionado")
	# Anima o botão
	animate_button_press($MenuContainer/ResumeButton)
	
	# Comunica com o controlador da cena atual para despausar
	_unpause_current_scene()
	
	# Fecha o menu via UIManager
	ui_manager.hide_ui("pause_menu")

func _on_main_menu_pressed():
	print("[PauseMenu] Botão Menu Principal pressionado")
	# Anima o botão
	animate_button_press($MenuContainer/MainMenuButton)
	# Despausa o jogo primeiro
	get_tree().paused = false
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

func _unpause_current_scene():
	"""Comunica com o controlador da cena atual para despausar corretamente"""
	print("[PauseMenu] Despausando cena atual...")
	
	var current_scene = get_tree().current_scene
	if not current_scene:
		print("[PauseMenu] ERRO: Cena atual não encontrada!")
		return
	
	# Verifica se é o world.tscn
	if current_scene.scene_file_path == "res://scenes/world.tscn" or current_scene.name == "World":
		print("[PauseMenu] Despausando world.tscn...")
		if current_scene.has_method("toggle_pause"):
			current_scene.toggle_pause()  # Chama o toggle que vai despausar
		else:
			# Fallback manual
			current_scene.is_paused = false
			get_tree().paused = false
			state_manager.change_state(state_manager.GameState.PLAYING)
	
	# Verifica se é o map_2.tscn
	elif current_scene.scene_file_path == "res://map_2.tscn" or current_scene.name == "Map2":
		print("[PauseMenu] Despausando map_2.tscn...")
		# Procura pelo Map2Controller
		var map2_controller = current_scene.get_node_or_null("Map2Controller")
		if not map2_controller:
			# Procura por qualquer nó que tenha o método unpause_game
			for child in current_scene.get_children():
				if child.has_method("unpause_game"):
					map2_controller = child
					break
		
		if map2_controller and map2_controller.has_method("unpause_game"):
			map2_controller.unpause_game()
		else:
			# Fallback manual
			get_tree().paused = false
			state_manager.change_state(state_manager.GameState.PLAYING)
	
	# Fallback geral para qualquer outra cena
	else:
		print("[PauseMenu] Despausando cena genérica...")
		get_tree().paused = false
		state_manager.change_state(state_manager.GameState.PLAYING)

func animate_button_press(button: Button):
	"""Animação simples de pressionar botão"""
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(button, "scale", Vector2(1, 1), 0.1) 
