extends Node

# OTIMIZAÇÃO: Sistema de cache global para referências do player
# Evita que múltiplos scripts fiquem fazendo get_tree().get_nodes_in_group("player")

var cached_player: Node3D = null
var cached_camera: Camera3D = null
var last_validation_time: float = 0.0
var validation_interval: float = 2.0  # Valida cache a cada 2 segundos

signal player_reference_changed(new_player: Node3D)

func _ready():
	print("[PlayerReferenceManager] Sistema de cache de player inicializado")
	# Busca inicial do player
	_find_and_cache_player()

func get_player() -> Node3D:
	"""Retorna referência cacheada do player, validando se necessário"""
	
	var current_time = Time.get_time_dict_from_system().second
	
	# Valida cache periodicamente
	if current_time - last_validation_time > validation_interval:
		last_validation_time = current_time
		_validate_cache()
	
	# Se cache é inválido, tenta encontrar novamente
	if not cached_player or not is_instance_valid(cached_player):
		_find_and_cache_player()
	
	return cached_player

func get_player_camera() -> Camera3D:
	"""Retorna referência cacheada da câmera do player"""
	
	# Garante que temos o player primeiro
	var player = get_player()
	if not player:
		return null
	
	# Valida cache da câmera
	if not cached_camera or not is_instance_valid(cached_camera):
		_find_and_cache_camera(player)
	
	return cached_camera

func _find_and_cache_player():
	"""Encontra e cacheia o player"""
	
	var old_player = cached_player
	cached_player = null
	
	# Tenta diferentes caminhos comuns
	var possible_paths = [
		"/root/World/Player",
		"/root/Map2/Player",
		"/root/*/Player"
	]
	
	for path in possible_paths:
		var player = get_node_or_null(path)
		if player and player.is_in_group("player"):
			cached_player = player
			break
	
	# Último recurso: busca por grupo
	if not cached_player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			cached_player = players[0]
	
	# Emite sinal se mudou
	if cached_player != old_player:
		player_reference_changed.emit(cached_player)
		if cached_player:
			print("[PlayerReferenceManager] Player cacheado: ", cached_player.name)
		else:
			print("[PlayerReferenceManager] ⚠️ Player não encontrado")
	
	# Limpa cache da câmera quando player muda
	if cached_player != old_player:
		cached_camera = null

func _find_and_cache_camera(player: Node3D):
	"""Encontra e cacheia a câmera do player"""
	
	if not player:
		return
	
	# Tenta encontrar diferentes tipos de câmera
	var camera_paths = [
		"ThirdPersonCamera",
		"FirstPersonCamera",
		"Camera3D"
	]
	
	for path in camera_paths:
		var camera = player.get_node_or_null(path)
		if camera and camera is Camera3D:
			cached_camera = camera
			print("[PlayerReferenceManager] Câmera cacheada: ", camera.name)
			return
	
	# Último recurso: câmera ativa do viewport
	cached_camera = get_viewport().get_camera_3d()
	if cached_camera:
		print("[PlayerReferenceManager] Câmera do viewport cacheada")

func _validate_cache():
	"""Valida se as referências cacheadas ainda são válidas"""
	
	if cached_player and not is_instance_valid(cached_player):
		print("[PlayerReferenceManager] Cache do player invalidado")
		cached_player = null
		cached_camera = null
	
	if cached_camera and not is_instance_valid(cached_camera):
		print("[PlayerReferenceManager] Cache da câmera invalidado")
		cached_camera = null

func force_refresh():
	"""Força atualização do cache"""
	cached_player = null
	cached_camera = null
	_find_and_cache_player()

func register_player(player: Node3D):
	"""Permite registrar player diretamente (útil para otimização)"""
	if player and player.is_in_group("player"):
		cached_player = player
		cached_camera = null  # Força busca da câmera
		player_reference_changed.emit(cached_player)
		print("[PlayerReferenceManager] Player registrado diretamente: ", player.name) 