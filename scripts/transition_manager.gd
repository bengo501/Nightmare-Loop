extends Node

var player_scene_path: String
var timer: Timer

func setup_player_transition(path: String):
	player_scene_path = path
	print("[TransitionManager] Configurando transição com path: ", player_scene_path)
	
	# Cria um timer para aguardar a cena carregar
	timer = Timer.new()
	timer.wait_time = 0.1  # 100ms
	timer.one_shot = true
	timer.timeout.connect(_create_player)
	add_child(timer)
	timer.start()

func _create_player():
	print("[TransitionManager] Criando player na nova cena...")
	
	# Verifica se a cena atual é válida
	var current_scene = get_tree().current_scene
	if not current_scene:
		print("[TransitionManager] ❌ Cena atual não encontrada, tentando novamente...")
		timer.start()  # Tenta novamente
		return
	
	# Verifica se já existe um player na cena
	var existing_player = get_tree().get_first_node_in_group("player")
	if existing_player:
		print("[TransitionManager] ✅ Player já existe na cena!")
		_cleanup()
		return
	
	# Carrega e instancia o player
	var player_scene = load(player_scene_path)
	if not player_scene:
		print("[TransitionManager] ❌ Não foi possível carregar a cena do player!")
		_cleanup()
		return
	
	var new_player = player_scene.instantiate()
	if not new_player:
		print("[TransitionManager] ❌ Não foi possível instanciar o player!")
		_cleanup()
		return
	
	# Adiciona o player à cena
	current_scene.add_child(new_player)
	
	# Posiciona no spawn point
	var spawn_point = _find_spawn_point(current_scene)
	if spawn_point:
		new_player.global_position = spawn_point.global_position
		print("[TransitionManager] 📍 Player posicionado no spawn: ", spawn_point.global_position)
	else:
		new_player.global_position = Vector3(-12.8871, 1, -27.3619)
		print("[TransitionManager] 📍 Player posicionado na posição padrão")
	
	# Garante que o player está no grupo correto
	new_player.add_to_group("player")
	
	print("[TransitionManager] ✅ Player criado e posicionado com sucesso!")
	_cleanup()

func _find_spawn_point(scene: Node) -> Node3D:
	"""
	Procura recursivamente por um ponto de spawn na cena
	"""
	# Procura por nomes comuns de spawn points
	var spawn_names = ["PontoNascimento", "SpawnPoint", "PlayerSpawn", "Spawn"]
	
	for spawn_name in spawn_names:
		var spawn_point = _find_node_by_name(scene, spawn_name)
		if spawn_point and spawn_point is Node3D:
			return spawn_point
	
	return null

func _find_node_by_name(parent: Node, node_name: String) -> Node:
	"""
	Busca recursivamente por um nó com o nome especificado
	"""
	if parent.name == node_name:
		return parent
	
	for child in parent.get_children():
		var result = _find_node_by_name(child, node_name)
		if result:
			return result
	
	return null

func _cleanup():
	print("[TransitionManager] Limpando transition manager...")
	queue_free() 