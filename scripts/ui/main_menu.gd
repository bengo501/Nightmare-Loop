extends Control

# Referências para autoloads
@onready var state_manager = get_node_or_null("/root/GameStateManager")
@onready var scene_manager = get_node_or_null("/root/SceneManager")
@onready var ui_manager = get_node_or_null("/root/UIManager")
@onready var game_manager = get_node_or_null("/root/GameManager")

var fade_rect: ColorRect = null

func _ready():
	# Verifica se os managers foram carregados
	_validate_managers()
	
	if has_node("NewGameButton"):
		$NewGameButton.pressed.connect(_on_new_game_pressed)
	if has_node("OptionsButton"):
		$OptionsButton.pressed.connect(_on_options_pressed)
	if has_node("CreditsButton"):
		$CreditsButton.pressed.connect(_on_credits_pressed)
	if has_node("QuitButton"):
		$QuitButton.pressed.connect(_on_quit_pressed)

func _validate_managers():
	"""Valida se os managers estão disponíveis"""
	var missing_managers = []
	
	if not game_manager:
		missing_managers.append("GameManager")
	if not state_manager:
		missing_managers.append("GameStateManager")
	if not ui_manager:
		missing_managers.append("UIManager")
	if not scene_manager:
		missing_managers.append("SceneManager")
	
	if missing_managers.size() > 0:
		print("[MainMenu] AVISO: Managers não encontrados: ", missing_managers)
	else:
		print("[MainMenu] ✅ Todos os managers carregados!")

func _on_new_game_pressed():
	# Primeiro reseta o jogo
	if game_manager and game_manager.has_method("reset_game"):
		game_manager.reset_game()
	else:
		print("[MainMenu] AVISO: GameManager não disponível para reset")
	
	# Exibe os slides da história antes de iniciar o jogo
	get_tree().change_scene_to_file("res://scenes/ui/story_slides.tscn")

func _show_fade_and_start_game():
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0,0,0,0)
	fade_rect.anchor_right = 1.0
	fade_rect.anchor_bottom = 1.0
	fade_rect.z_index = 1000
	add_child(fade_rect)
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.8)
	tween.tween_callback(Callable(self, "_on_fade_complete"))

func _on_fade_complete():
	queue_free()
	if scene_manager and scene_manager.has_method("change_scene"):
		scene_manager.change_scene("world")
	else:
		print("[MainMenu] AVISO: SceneManager não disponível, mudando cena diretamente")
		get_tree().change_scene_to_file("res://world.tscn")
	
	if state_manager:
		state_manager.change_state(state_manager.GameState.PLAYING)

func _on_options_pressed():
	if ui_manager:
		ui_manager.hide_ui("main_menu")
		ui_manager.show_ui("options_menu")
	else:
		print("[MainMenu] AVISO: UIManager não disponível para mostrar opções")

func _on_credits_pressed():
	if ui_manager:
		ui_manager.show_ui("credits")
	else:
		print("[MainMenu] AVISO: UIManager não disponível para mostrar créditos")

func _on_quit_pressed():
	get_tree().quit() 
