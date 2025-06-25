# ===============================
# SceneManager.gd
# ===============================
extends Node

signal map_changed(map_path: String)
signal scene_changed(scene_path: String)

var scenes = {
	"main_menu": "res://scenes/ui/main_menu.tscn",
	"world": "res://scenes/world.tscn",
	"map_2": "res://map_2.tscn",
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
	print("\n[SceneManager] ====== MUDANDO CENA ======")
	print("[SceneManager] Cena atual: ", get_tree().current_scene.name if get_tree().current_scene else "Nenhuma")
	print("[SceneManager] Tentando mudar para cena: ", scene_name)
	
	if scenes.has(scene_name):
		var path = scenes[scene_name]
		print("[SceneManager] Caminho da cena: ", path)
		
		# Verifica se o arquivo existe
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			file.close()
			print("[SceneManager] Arquivo da cena encontrado!")
		else:
			push_error("[SceneManager] Erro: Arquivo da cena não encontrado: " + path)
			return
		
		print("[SceneManager] Trocando para a cena: " + scene_name + " (" + path + ")")
		
		# Carrega a cena
		var scene_resource = load(path)
		if scene_resource == null:
			push_error("[SceneManager] Erro: Não foi possível carregar a cena: " + path)
			return
			
		# Limpa a cena atual
		if get_tree().current_scene:
			get_tree().current_scene.queue_free()
		
		# Instancia e adiciona a nova cena
		var new_scene = scene_resource.instantiate()
		if new_scene == null:
			push_error("[SceneManager] Erro: Não foi possível instanciar a cena: " + path)
			return
			
		get_tree().root.add_child(new_scene)
		get_tree().current_scene = new_scene
		
		emit_signal("scene_changed", path)
		print("[SceneManager] Cena alterada com sucesso!")
	else:
		push_error("[SceneManager] Cena não encontrada: " + scene_name)
	
	print("[SceneManager] ====== FIM DA MUDANÇA DE CENA ======\n")

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

func change_scene_with_fade(scene_name: String, fade_duration: float = 1.0):
	"""
	Muda de cena com efeito de fade out/in
	"""
	print("[SceneManager] Iniciando transição com fade para: ", scene_name)
	
	# Cria overlay de fade
	var fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.anchors_preset = Control.PRESET_FULL_RECT
	fade_overlay.color = Color(0, 0, 0, 0)
	fade_overlay.z_index = 1000
	
	# Adiciona à cena atual
	get_tree().current_scene.add_child(fade_overlay)
	
	# Fade out
	var tween = get_tree().create_tween()
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), fade_duration)
	
	await tween.finished
	
	# Muda a cena
	change_scene(scene_name)
	
	# Posiciona o player no spawn point se necessário
	await get_tree().process_frame  # Aguarda um frame para garantir que a cena foi carregada
	position_player_at_spawn()
	
	print("[SceneManager] Transição com fade concluída")

func position_player_at_spawn():
	"""
	Posiciona o player no ponto de spawn da cena atual
	"""
	print("[SceneManager] Tentando posicionar player no spawn point...")
	
	var current_scene_node = get_tree().current_scene
	if not current_scene_node:
		print("[SceneManager] Erro: Nenhuma cena atual encontrada")
		return
	
	# Procura pelo nodo PontoNascimento
	var spawn_point = find_node_by_name(current_scene_node, "PontoNascimento")
	if not spawn_point:
		print("[SceneManager] Aviso: Nodo 'PontoNascimento' não encontrado na cena")
		return
	
	# Procura pelo player
	var player = find_node_by_name(current_scene_node, "Player")
	if not player:
		# Tenta procurar por outros nomes possíveis do player
		player = find_node_by_name(current_scene_node, "player")
		if not player:
			player = find_node_by_name(current_scene_node, "PlayerCharacter")
	
	if not player:
		print("[SceneManager] Aviso: Player não encontrado na cena")
		return
	
	# Posiciona o player
	if player is CharacterBody3D or player is RigidBody3D or player is Node3D:
		var spawn_position = spawn_point.global_transform.origin
		player.global_transform.origin = spawn_position
		print("[SceneManager] Player posicionado em: ", spawn_position)
		
		# Se o player tem um CharacterBody3D, reseta a velocidade
		if player is CharacterBody3D:
			player.velocity = Vector3.ZERO
	else:
		print("[SceneManager] Erro: Player não é um tipo de nodo posicionável")

func find_node_by_name(parent: Node, node_name: String) -> Node:
	"""
	Busca recursivamente por um nodo com o nome especificado
	"""
	if parent.name == node_name:
		return parent
	
	for child in parent.get_children():
		var result = find_node_by_name(child, node_name)
		if result:
			return result
	
	return null
