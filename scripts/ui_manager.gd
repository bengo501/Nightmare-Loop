extends Node

# UI scenes dictionary
var ui_scenes = {
	"main_menu": "res://scenes/ui/main_menu.tscn",
	"pause_menu": "res://scenes/ui/pause_menu.tscn",
	"options_menu": "res://scenes/ui/options_menu.tscn",
	"hud": "res://scenes/ui/hud.tscn",
	"game_over": "res://scenes/ui/game_over.tscn",
	"inventory": "res://scenes/ui/inventory.tscn",
	"credits": "res://scenes/ui/credits.tscn"
}

# Current UI elements
var current_ui = null
var active_menus = []
var hud_instance = null
var options_menu_instance = null

# References to other managers
@onready var game_manager = get_node("/root/GameManager")
@onready var state_manager = get_node("/root/GameStateManager")

func _ready():
	# Connect to game manager signals
	game_manager.health_changed.connect(_on_health_changed)
	game_manager.score_changed.connect(_on_score_changed)
	game_manager.level_up.connect(_on_level_up)
	game_manager.game_over.connect(_on_game_over)
	
	# Connect to state manager signals
	state_manager.state_changed.connect(_on_game_state_changed)

# UI control functions
func show_ui(ui_name: String) -> void:
	if not ui_scenes.has(ui_name):
		push_error("UI scene not found: " + ui_name)
		return
	
	# Se já existe uma instância do menu de opções, apenas torna visível
	if ui_name == "options_menu" and options_menu_instance:
		options_menu_instance.show()
		return
		
	var ui_scene = load(ui_scenes[ui_name]).instantiate()
	add_child(ui_scene)
	active_menus.append(ui_scene)
	current_ui = ui_scene
	
	# Guarda referência do menu de opções
	if ui_name == "options_menu":
		options_menu_instance = ui_scene
	
	# Se for o menu de pause, esconde a HUD
	if ui_name == "pause_menu" and hud_instance:
		hud_instance.visible = false
	
	# Se for a tela de game over, esconde a HUD e conecta os botões
	if ui_name == "game_over":
		if hud_instance:
			hud_instance.visible = false
		if ui_scene.has_node("MenuContainer/RestartButton"):
			ui_scene.get_node("MenuContainer/RestartButton").pressed.connect(_on_game_over_restart)
		if ui_scene.has_node("MenuContainer/MainMenuButton"):
			ui_scene.get_node("MenuContainer/MainMenuButton").pressed.connect(_on_game_over_main_menu)
		if ui_scene.has_node("MenuContainer/QuitButton"):
			ui_scene.get_node("MenuContainer/QuitButton").pressed.connect(_on_game_over_quit)

func hide_ui(ui_name: String) -> void:
	# Se for o menu de opções e ele existe, apenas esconde
	if ui_name == "options_menu" and options_menu_instance:
		options_menu_instance.hide()
		return
	for menu in active_menus:
		if menu.name.to_lower() == ui_name.to_lower():
			menu.queue_free()
			active_menus.erase(menu)
			# Se for o menu de pause, mostra a HUD novamente
			if ui_name == "pause_menu" and hud_instance:
				hud_instance.visible = true
			break

func hide_all_ui() -> void:
	for menu in active_menus:
		menu.queue_free()
	active_menus.clear()
	current_ui = null
	options_menu_instance = null

# Signal handlers
func _on_health_changed(new_health: int) -> void:
	if current_ui and current_ui.has_method("update_health"):
		current_ui.update_health(new_health)

func _on_score_changed(new_score: int) -> void:
	if current_ui and current_ui.has_method("update_score"):
		current_ui.update_score(new_score)

func _on_level_up(new_level: int) -> void:
	if current_ui and current_ui.has_method("update_level"):
		current_ui.update_level(new_level)

func _on_game_over() -> void:
	show_ui("game_over")

func _on_game_state_changed(new_state: int) -> void:
	match new_state:
		state_manager.GameState.MAIN_MENU:
			hide_all_ui()
			show_ui("main_menu")
		state_manager.GameState.PLAYING:
			hide_all_ui()
			show_ui("hud")
			hud_instance = current_ui  # Guarda referência da HUD
		state_manager.GameState.PAUSED:
			show_ui("pause_menu")
		state_manager.GameState.GAME_OVER:
			show_ui("game_over")
		state_manager.GameState.INVENTORY:
			show_ui("inventory") 

# Funções dos botões da tela de game over
func _on_game_over_restart():
	get_node("/root/SceneManager").change_scene("world")
	get_node("/root/GameStateManager").change_state(get_node("/root/GameStateManager").GameState.PLAYING)
	hide_ui("game_over")

func _on_game_over_main_menu():
	get_node("/root/SceneManager").change_scene("main_menu")
	get_node("/root/GameStateManager").change_state(get_node("/root/GameStateManager").GameState.MAIN_MENU)
	hide_ui("game_over")

func _on_game_over_quit():
	get_tree().quit() 
