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
	print("[MainMenu] Iniciando novo jogo...")
	
	# Primeiro reseta o jogo
	if game_manager and game_manager.has_method("reset_game"):
		game_manager.reset_game()
	else:
		print("[MainMenu] AVISO: GameManager não disponível para reset")
	
	# Cria overlay para fade out
	var fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.anchors_preset = Control.PRESET_FULL_RECT
	fade_overlay.color = Color(0, 0, 0, 0)
	fade_overlay.z_index = 100
	add_child(fade_overlay)
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 1.0)
	
	await tween.finished
	
	# Remove a cena atual antes de mudar
	queue_free()
	
	# Muda para os slides da história usando o SceneManager
	if scene_manager:
		scene_manager.change_scene("story_slides")
	else:
		push_error("[MainMenu] SceneManager não encontrado!")

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
