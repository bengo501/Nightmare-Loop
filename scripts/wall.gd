extends CSGBox3D

@export var fade_duration := 0.4
@export var debug_mode := false
@export var dither_intensity := 0.6  # Intensidade do dither (0.0 = mais sutil, 1.0 = mais agressivo)

var player_ref: Node3D = null
var camera_ref: Camera3D = null
var fade_amount: float = 0.0
var fade_target: float = 0.0

# OTIMIZAÇÃO: Cache e timer para reduzir consultas frequentes
var player_search_timer: float = 0.0
var player_search_interval: float = 1.0  # Busca player a cada 1 segundo se não encontrado
var last_physics_update: float = 0.0
var physics_update_interval: float = 0.016  # ~60 FPS, mas controlado

func _ready():
	# Torna o material único para cada parede
	if material and material is ShaderMaterial:
		material = material.duplicate()
		# Configura a intensidade do dither
		var mat := material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("dither_intensity", dither_intensity)
		if debug_mode:
			print("[WallTransparency] Material duplicado para parede: ", name)
	
	# Procura pelo player e câmera de forma mais robusta
	_find_player_and_camera()

func _find_player_and_camera():
	"""Encontra o player e câmera na cena de forma robusta"""
	
	# OTIMIZAÇÃO: Só busca se ainda não encontrou
	if player_ref and is_instance_valid(player_ref):
		return
	
	# Procura pelo player em diferentes locais possíveis
	var possible_player_paths = [
		"../../Player",
		"../Player", 
		"Player",
		"/root/*/Player"
	]
	
	for path in possible_player_paths:
		player_ref = get_node_or_null(path)
		if player_ref:
			if debug_mode:
				print("[WallTransparency] Player encontrado: ", player_ref.name)
			break
	
	# Se não encontrou pelos paths, tenta pelo grupo (APENAS UMA VEZ)
	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
	
	# Procura pela câmera
	if player_ref:
		# Primeiro tenta encontrar a câmera no player
		camera_ref = player_ref.get_node_or_null("ThirdPersonCamera")
		if not camera_ref:
			camera_ref = player_ref.get_node_or_null("FirstPersonCamera")
		if not camera_ref:
			# Último recurso: procura por qualquer Camera3D
			camera_ref = get_viewport().get_camera_3d()
	
	if debug_mode:
		if player_ref:
			print("[WallTransparency] Player: ", player_ref.name)
		else:
			print("[WallTransparency] ❌ Player não encontrado!")
		
		if camera_ref:
			print("[WallTransparency] Camera: ", camera_ref.name)
		else:
			print("[WallTransparency] ❌ Camera não encontrada!")

func _physics_process(delta):
	# OTIMIZAÇÃO: Controla frequência de atualização
	last_physics_update += delta
	if last_physics_update < physics_update_interval:
		return
	last_physics_update = 0.0
	
	# OTIMIZAÇÃO: Verifica validade das referências primeiro
	if not player_ref or not is_instance_valid(player_ref):
		player_search_timer += delta
		if player_search_timer >= player_search_interval:
			player_search_timer = 0.0
			_find_player_and_camera()
		return
	
	if not camera_ref or not is_instance_valid(camera_ref):
		# Tenta encontrar a câmera novamente se o player existe
		if player_ref:
			camera_ref = player_ref.get_node_or_null("ThirdPersonCamera")
			if not camera_ref:
				camera_ref = player_ref.get_node_or_null("FirstPersonCamera")
		return
	
	# Verifica se há uma parede entre o player e a câmera
	_check_wall_occlusion()
	
	# Transição suave de fade
	fade_amount = lerp(fade_amount, fade_target, delta / fade_duration)
	
	# Atualiza o shader
	_update_shader_transparency()

func _check_wall_occlusion():
	"""Verifica se esta parede está bloqueando a visão entre player e câmera"""
	
	var from = player_ref.global_transform.origin
	var to = camera_ref.global_transform.origin
	
	var space_state = get_world_3d().direct_space_state
	var ray_params := PhysicsRayQueryParameters3D.create(from, to)
	ray_params.exclude = [player_ref]
	ray_params.collision_mask = 1  # Camada de paredes
	
	var result = space_state.intersect_ray(ray_params)
	
	if result and result.collider:
		if debug_mode:
			print("[WallTransparency] Ray colidiu com: ", result.collider.name)
		
		# Verifica se o colisor é esta parede ou parte dela
		if result.collider == self or self.is_ancestor_of(result.collider) or result.collider.is_ancestor_of(self):
			fade_target = 1.0  # Torna transparente
			if debug_mode:
				print("[WallTransparency] Esta parede está bloqueando a visão!")
		else:
			fade_target = 0.0  # Mantém opaco
	else:
		fade_target = 0.0  # Sem obstrução, mantém opaco

func _update_shader_transparency():
	"""Atualiza o parâmetro de transparência no shader"""
	
	var mat := material as ShaderMaterial
	if mat and mat.shader:
		mat.set_shader_parameter("fade_amount", fade_amount)
		mat.set_shader_parameter("dither_intensity", dither_intensity)
		
		if debug_mode and fade_amount > 0.1:
			print("[WallTransparency] fade_amount: ", fade_amount, " dither_intensity: ", dither_intensity)
	else:
		if debug_mode:
			print("[WallTransparency] ⚠️ Material não é ShaderMaterial ou shader é nulo")

# Função para ativar/desativar debug
func set_debug_mode(enabled: bool):
	debug_mode = enabled

# Função para forçar busca de player/camera
func refresh_references():
	player_ref = null
	camera_ref = null
	_find_player_and_camera()

# OTIMIZAÇÃO: Função para definir referência diretamente (evita buscas)
func set_player_reference(player: Node3D):
	player_ref = player
	if player_ref:
		camera_ref = player_ref.get_node_or_null("ThirdPersonCamera")
		if not camera_ref:
			camera_ref = player_ref.get_node_or_null("FirstPersonCamera")
