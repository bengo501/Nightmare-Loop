extends Node

# Referências aos managers (autoloads)
@onready var game_manager = get_node("/root/GameManager")
@onready var state_manager = get_node("/root/GameStateManager")

# Cenas de UI
var hud_scene = preload("res://scenes/ui/hud.tscn")
var pause_menu_scene = preload("res://scenes/ui/pause_menu.tscn")
var game_over_scene = preload("res://scenes/ui/game_over.tscn")
var skill_tree_scene = preload("res://scenes/ui/skill_tree.tscn")

# Instâncias das UIs
var hud_instance = null
var pause_menu_instance = null
var game_over_instance = null
var skill_tree_instance = null

func _ready():
	print("[UIManager] Inicializando...")
	
	# Conecta sinais do GameStateManager
	state_manager.connect("state_changed", _on_game_state_changed)
	
	# Cria a HUD inicial
	show_ui("hud")

func _on_game_state_changed(new_state: GameStateManager.GameState):
	match new_state:
		GameStateManager.GameState.PLAYING:
			show_ui("hud")
			hide_ui("pause_menu")
			hide_ui("game_over")
			hide_ui("skill_tree")
		GameStateManager.GameState.PAUSED:
			show_ui("pause_menu")
			hide_ui("hud")
		GameStateManager.GameState.GAME_OVER:
			show_ui("game_over")
			hide_ui("hud")
		GameStateManager.GameState.SKILL_TREE:
			show_ui("skill_tree")
			hide_ui("hud")

func show_ui(ui_name: String):
	print("[UIManager] Mostrando UI: %s" % ui_name)
	
	match ui_name:
		"hud":
			if not hud_instance:
				hud_instance = hud_scene.instantiate()
				add_child(hud_instance)
			hud_instance.visible = true
		
		"pause_menu":
			if not pause_menu_instance:
				pause_menu_instance = pause_menu_scene.instantiate()
				add_child(pause_menu_instance)
			pause_menu_instance.visible = true
		
		"game_over":
			if not game_over_instance:
				game_over_instance = game_over_scene.instantiate()
				add_child(game_over_instance)
			game_over_instance.visible = true
		
		"skill_tree":
			if not skill_tree_instance:
				skill_tree_instance = skill_tree_scene.instantiate()
				add_child(skill_tree_instance)
			skill_tree_instance.visible = true

func hide_ui(ui_name: String):
	print("[UIManager] Escondendo UI: %s" % ui_name)
	
	match ui_name:
		"hud":
			if hud_instance:
				hud_instance.visible = false
		
		"pause_menu":
			if pause_menu_instance:
				pause_menu_instance.visible = false
		
		"game_over":
			if game_over_instance:
				game_over_instance.visible = false
		
		"skill_tree":
			if skill_tree_instance:
				skill_tree_instance.visible = false

func update_hud():
	if hud_instance:
		hud_instance.update_display() 