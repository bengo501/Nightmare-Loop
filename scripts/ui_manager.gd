# ===============================
# UIManager.gd
# ===============================
extends Node

signal ui_opened(ui_name: String)
signal ui_closed(ui_name: String)

# Referências para cenas de UI
var ui_scenes := {
	"main_menu": preload("res://scenes/ui/main_menu.tscn"),
	"pause_menu": preload("res://scenes/ui/pause_menu.tscn"),
	"options_menu": preload("res://scenes/ui/options_menu.tscn"),
	"game_over": preload("res://scenes/ui/game_over.tscn"),
	"battle_ui": preload("res://scenes/ui/BattleUI.tscn"),
	"hud": preload("res://scenes/ui/hud.tscn"),
	"gifts_menu": preload("res://scenes/ui/GiftsMenu.tscn"),
	"credits": preload("res://scenes/ui/credits.tscn"),
	"item_menu": preload("res://scenes/ui/ItemMenu.tscn"),
	"skill_tree": preload("res://scenes/ui/skill_tree.tscn")
}

# Gerenciamento de instâncias
var active_ui := {}

@onready var state_manager = get_node("/root/GameStateManager")
@onready var scene_manager = get_node("/root/SceneManager")

func _ready():
	state_manager.connect("state_changed", _on_state_changed)
	if state_manager.current_state == state_manager.GameState.PLAYING:
		show_ui("hud")

func _on_state_changed(new_state):
	hide_all_ui()
	match new_state:
		state_manager.GameState.MAIN_MENU:
			show_ui("main_menu")
		state_manager.GameState.PLAYING:
			show_ui("hud")
		state_manager.GameState.PAUSED:
			show_ui("pause_menu")
		state_manager.GameState.GAME_OVER:
			show_ui("game_over")
		state_manager.GameState.BATTLE:
			show_ui("battle_ui")
		state_manager.GameState.GIFTS:
			show_ui("gifts_menu")
		state_manager.GameState.INVENTORY:
			show_ui("item_menu")
		state_manager.GameState.SKILL_TREE:
			show_ui("skill_tree")
		state_manager.GameState.CREDITS:
			show_ui("credits")
		state_manager.GameState.OPTIONS:
			show_ui("options_menu")

func show_ui(ui_name: String, data: Dictionary = {}):
	if active_ui.has(ui_name):
		active_ui[ui_name].queue_free()
		active_ui.erase(ui_name)

	if ui_scenes.has(ui_name):
		var instance = ui_scenes[ui_name].instantiate()
		add_child(instance)
		active_ui[ui_name] = instance
		emit_signal("ui_opened", ui_name)

		if instance.has_method("setup"):
			instance.setup(data)

func hide_ui(ui_name: String):
	if active_ui.has(ui_name):
		active_ui[ui_name].queue_free()
		emit_signal("ui_closed", ui_name)
		active_ui.erase(ui_name)

func hide_all_ui():
	for key in active_ui.keys():
		hide_ui(key)

# Chamado por UI interativa para mudar cena
func request_scene_change(scene_name: String):
	scene_manager.change_scene(scene_name)

func request_map_change(map_name: String):
	scene_manager.change_map(map_name)
