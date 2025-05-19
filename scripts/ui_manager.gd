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
		
	var ui_scene = load(ui_scenes[ui_name]).instantiate()
	add_child(ui_scene)
	active_menus.append(ui_scene)
	current_ui = ui_scene

func hide_ui(ui_name: String) -> void:
	for menu in active_menus:
		if menu.name == ui_name:
			menu.queue_free()
			active_menus.erase(menu)
			break

func hide_all_ui() -> void:
	for menu in active_menus:
		menu.queue_free()
	active_menus.clear()
	current_ui = null

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
		state_manager.GameState.PAUSED:
			show_ui("pause_menu")
		state_manager.GameState.GAME_OVER:
			show_ui("game_over")
		state_manager.GameState.INVENTORY:
			show_ui("inventory") 
