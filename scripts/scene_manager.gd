extends Node

signal map_changed(map_path: String)

# Dictionary to store scene paths
var scenes = {
	"main_menu": "res://scenes/main_menu.tscn",
	"world": "res://scenes/world.tscn",
	"battle": "res://battle_scene.tscn",
	"options": "res://scenes/options_menu.tscn"
}

# Current scene reference
var current_scene = null

# Dicionário com os caminhos dos mapas
var maps = {
	"main": "res://scenes/maps/main_map.tscn",
	"dungeon": "res://scenes/maps/dungeon_map.tscn",
	"boss": "res://scenes/maps/boss_map.tscn"
}

# Mapa atual
var current_map_name: String = "main"

func _ready():
	# Initialize with the current scene
	current_scene = get_tree().current_scene

# Function to change scenes
func change_scene(scene_name: String, transition_type: String = "fade") -> void:
	if not scenes.has(scene_name):
		push_error("Scene not found: " + scene_name)
		return
		
	# Handle different transition types
	match transition_type:
		"fade":
			await fade_transition()
		"instant":
			pass
		"slide":
			await slide_transition()
	
	# Change the scene
	var new_scene = load(scenes[scene_name]).instantiate()
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene
	
	if current_scene:
		current_scene.queue_free()
	
	current_scene = new_scene

# Transition effects
func fade_transition() -> void:
	# Implement fade transition logic here
	pass

func slide_transition() -> void:
	# Implement slide transition logic here
	pass

func change_map(map_name: String):
	if maps.has(map_name):
		current_map_name = map_name
		map_changed.emit(maps[map_name])
	else:
		push_error("Mapa não encontrado: " + map_name)

func get_current_map() -> String:
	return current_map_name

func get_map_path(map_name: String) -> String:
	return maps.get(map_name, "") 