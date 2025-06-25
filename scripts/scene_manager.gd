# ===============================
# SceneManager.gd
# ===============================
extends Node

signal map_changed(map_path: String)
signal scene_changed(scene_path: String)

# Variável para controlar se está em processo de mudança
var is_changing_scene: bool = false

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
		if get_tree().current_scene and is_instance_valid(get_tree().current_scene) and not get_tree().current_scene.is_queued_for_deletion():
			get_tree().current_scene.queue_free()
			print("[SceneManager] Cena atual removida com segurança")
		else:
			print("[SceneManager] Cena atual já foi liberada ou é inválida")
		
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

func change_hub_with_fade(hub_name: String, fade_duration: float = 2.0):
	print("[SceneManager] Iniciando troca de hub para: ", hub_name)
	
	# Verifica se já está em processo de mudança para evitar chamadas duplas
	if is_changing_scene:
		print("[SceneManager] AVISO: Já está em processo de mudança de cena, cancelando")
		return
	
	if get_tree().paused:
		print("[SceneManager] AVISO: Jogo já está pausado, forçando despause antes de continuar")
		get_tree().paused = false
	
	# Marca que está em processo de mudança
	is_changing_scene = true
	
	# Cria timer de timeout para evitar travamentos permanentes
	var timeout_timer = get_tree().create_timer(10.0)  # 10 segundos de timeout
	timeout_timer.timeout.connect(_on_change_timeout)
	
	# Limpa referências inválidas do UIManager
	if UIManager and UIManager.has_method("cleanup_invalid_references"):
		UIManager.cleanup_invalid_references()
	
	# Esconde a HUD primeiro
	if UIManager and UIManager.has_method("hide_ui"):
		UIManager.hide_ui("hud")
	
	# Verifica se a cena de destino existe
	if not scenes.has(hub_name):
		print("[SceneManager] ERRO: Hub não encontrado: ", hub_name)
		_reset_change_state()
		return
	
	# Preserva o player atual ANTES de pausar
	var player = find_player()
	if not player:
		print("[SceneManager] ERRO: Player não encontrado!")
		_reset_change_state()
		return
	
	print("[SceneManager] Player encontrado: ", player.name)
	
	# Agora pausa o jogo
	get_tree().paused = true
	print("[SceneManager] Jogo pausado")
	
	# Continua com o resto da função...
	await _execute_hub_change(hub_name, fade_duration, player)
	
	# Limpa o estado no final
	_reset_change_state()

func _execute_hub_change(hub_name: String, fade_duration: float, player: Node):
	"""
	Executa a mudança de hub de forma assíncrona
	"""
	# Cria overlay de fade
	var fade_overlay = ColorRect.new()
	fade_overlay.name = "HubFadeOverlay"
	fade_overlay.anchors_preset = Control.PRESET_FULL_RECT
	fade_overlay.color = Color(0, 0, 0, 0)
	fade_overlay.z_index = 1000
	fade_overlay.process_mode = Node.PROCESS_MODE_ALWAYS  # Funciona mesmo pausado
	
	# Adiciona à cena atual
	get_tree().current_scene.add_child(fade_overlay)
	
	# Inicia o fade in (escurecer tela)
	var tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)  # Funciona mesmo pausado
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), fade_duration / 2.0)
	
	# Aguarda o tween terminar
	await tween.finished
	
	print("[SceneManager] Fade in concluído, iniciando mudança de cena")
	
	# Remove o player da cena atual temporariamente
	var player_parent = player.get_parent()
	player_parent.remove_child(player)
	print("[SceneManager] Player removido temporariamente da cena")
	
	# Muda para o novo hub
	var scene_path = scenes[hub_name]
	print("[SceneManager] Carregando nova cena: ", scene_path)
	get_tree().change_scene_to_file(scene_path)
	
	# Aguarda alguns frames para garantir que a cena foi carregada
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("[SceneManager] Nova cena carregada")
	
	# Adiciona o player à nova cena
	var new_scene = get_tree().current_scene
	if new_scene:
		new_scene.add_child(player)
		print("[SceneManager] Player adicionado à nova cena")
		
		# Posiciona o player no ponto de nascimento
		position_player_at_spawn()
		
		# Reativa o player
		if player.has_method("reactivate_player"):
			player.reactivate_player()
			print("[SceneManager] Player reativado")
		
		# Aguarda mais alguns frames
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Reativa o jogo ANTES do fade out
		get_tree().paused = false
		print("[SceneManager] Jogo despausado")
		
		# Atualiza o estado do jogo
		if GameStateManager:
			print("[SceneManager] GameStateManager encontrado, mudando estado para PLAYING")
			# Usa o valor direto do enum PLAYING (que é 1)
			GameStateManager.change_state(1)  # GameState.PLAYING = 1
		else:
			print("[SceneManager] ERRO: GameStateManager não disponível, forçando despause manual")
			# Fallback: força despause manual
			get_tree().paused = false
		
		# Mostra a HUD novamente
		if UIManager and UIManager.has_method("show_ui"):
			UIManager.show_ui("hud")
		
		# Cria novo fade overlay na nova cena
		var new_fade_overlay = ColorRect.new()
		new_fade_overlay.name = "HubFadeOverlay2"
		new_fade_overlay.anchors_preset = Control.PRESET_FULL_RECT
		new_fade_overlay.color = Color(0, 0, 0, 1)
		new_fade_overlay.z_index = 1000
		
		new_scene.add_child(new_fade_overlay)
		
		# Fade out (clarear tela)
		var fade_out_tween = get_tree().create_tween()
		fade_out_tween.tween_property(new_fade_overlay, "color", Color(0, 0, 0, 0), fade_duration / 2.0)
		
		await fade_out_tween.finished
		
		# Remove o overlay
		if new_fade_overlay and is_instance_valid(new_fade_overlay):
			new_fade_overlay.queue_free()
		
		print("[SceneManager] Troca de hub concluída com sucesso!")
	else:
		print("[SceneManager] ERRO: Nova cena não encontrada!")
		get_tree().paused = false

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

func find_player() -> Node:
	"""
	Encontra o player na cena atual
	"""
	var current_scene_node = get_tree().current_scene
	if not current_scene_node:
		print("[SceneManager] Erro: Nenhuma cena atual encontrada")
		return null
	
	# Procura pelo player com diferentes nomes possíveis
	var player = find_node_by_name(current_scene_node, "Player")
	if not player:
		player = find_node_by_name(current_scene_node, "player")
		if not player:
			player = find_node_by_name(current_scene_node, "PlayerCharacter")
	
	return player

func _on_change_timeout():
	print("[SceneManager] Timeout: Forçando despause e resetando estado")
	get_tree().paused = false
	_reset_change_state()

func _reset_change_state():
	is_changing_scene = false
	print("[SceneManager] Estado de mudança resetado")
