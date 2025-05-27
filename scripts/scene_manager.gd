# ===============================
# SceneManager.gd
# ===============================
extends Node

signal map_changed(map_path: String)
signal scene_changed(scene_path: String)

var scenes = {
	"main_menu": "res://scenes/ui/main_menu.tscn",
	"world": "res://scenes/world.tscn",
	"battle": "res://battle_scene.tscn",
	"options_menu": "res://scenes/ui/options_menu.tscn",
	"pause_menu": "res://scenes/ui/pause_menu.tscn",
	"hud": "res://scenes/ui/hud.tscn",
	"game_over": "res://scenes/ui/game_over.tscn",
	"credits": "res://scenes/ui/credits.tscn"
}

var maps = {
	"main": "res://scenes/maps/main_map.tscn",
	"dungeon": "res://scenes/maps/dungeon_map.tscn",
	"lobby": "res://scenes/maps/lobby.tscn"
}

var current_scene = null
var current_map_name: String = "main"

func _ready():
	current_scene = get_tree().current_scene

func change_scene(scene_name: String):
	if scenes.has(scene_name):
		var path = scenes[scene_name]
		get_tree().change_scene_to_file(path)
		emit_signal("scene_changed", path)
	else:
		push_error("Cena não encontrada: " + scene_name)

func change_map(map_name: String):
	if maps.has(map_name):
		current_map_name = map_name
		var path = maps[map_name]
		map_changed.emit(path)
	else:
		push_error("Mapa não encontrado: " + map_name)

func get_current_map_path() -> String:
	return maps.get(current_map_name, "")

func get_current_map_name() -> String:
	return current_map_name
