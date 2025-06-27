extends CharacterBody3D
class_name GhostBase

enum GriefStage {
	DENIAL,     # Negação - Verde
	ANGER,      # Raiva - Cinza
	BARGAINING, # Barganha - Azul
	DEPRESSION, # Depressão - Roxo
	ACCEPTANCE  # Aceitação - Amarelo
}

@export var grief_stage: GriefStage = GriefStage.DENIAL
@export var max_health: float = 100.0
@export var speed: float = 3.0
@export var attack_range: float = 1.5
@export var attack_damage: float = 20.0
@export var attack_cooldown: float = 1.0
@export var path_update_interval: float = 0.2
@export var rotation_speed: float = 10.0

# Propriedades de detecção visual
@export var vision_range: float = 15.0  # Aumentado para mais agressividade
@export var vision_angle: float = 120.0  # Ângulo de visão mais amplo
@export var lose_sight_time: float = 2.0  # Reduzido para manter perseguição mais tempo

# Propriedades de movimento e patrulhamento
@export var wander_radius: float = 15.0  # Área de patrulha maior
@export var wander_chance: float = 0.5  # Mais movimento ativo
@export var idle_time_min: float = 1.0  # Menos tempo parado
@export var idle_time_max: float = 3.0  # Menos tempo parado
@export var patrol_radius: float = 20.0  # Raio de patrulhamento
@export var patrol_points_count: int = 6  # Número de pontos de patrulha
@export var aggressive_chase_distance: float = 20.0  # Distância para perseguição agressiva

# Propriedades específicas por estágio
var stage_properties = {
	GriefStage.DENIAL: {
		"color": Vector4(0.2, 1.0, 0.2, 0.7),
		"texture": "res://assets/textures/greenGhost.png",
		"speed_multiplier": 1.0,
		"health_multiplier": 1.0,
		"special_ability": "phase_through",
		"scale": Vector3(0.6, 0.6, 0.6),
		"vision_range": 10.0,
		"aggression": 0.7
	},
	GriefStage.ANGER: {
		"color": Vector4(0.7, 0.7, 0.7, 0.8),
		"texture": "res://assets/textures/greyGhost.png",
		"speed_multiplier": 1.5,
		"health_multiplier": 1.2,
		"special_ability": "rage_attack",
		"scale": Vector3(0.7, 0.7, 0.7),
		"vision_range": 15.0,
		"aggression": 1.5
	},
	GriefStage.BARGAINING: {
		"color": Vector4(0.2, 0.2, 1.0, 0.6),
		"texture": "res://assets/textures/blueGhost.png",
		"speed_multiplier": 0.8,
		"health_multiplier": 1.5,
		"special_ability": "heal_others",
		"scale": Vector3(0.8, 0.8, 0.8),
		"vision_range": 8.0,
		"aggression": 0.5
	},
	GriefStage.DEPRESSION: {
		"color": Vector4(0.6, 0.2, 0.8, 0.5),
		"texture": "res://assets/textures/purpleGhost.png",
		"speed_multiplier": 0.6,
		"health_multiplier": 2.0,
		"special_ability": "drain_energy",
		"scale": Vector3(0.9, 0.9, 0.9),
		"vision_range": 6.0,
		"aggression": 0.3
	},
	GriefStage.ACCEPTANCE: {
		"color": Vector4(1.0, 1.0, 0.2, 0.9),
		"texture": "res://assets/textures/yellowGhost.png",
		"speed_multiplier": 1.2,
		"health_multiplier": 0.8,
		"special_ability": "peaceful_death",
		"scale": Vector3(0.5, 0.5, 0.5),
		"vision_range": 12.0,
		"aggression": 1.0
	}
}

# Estados de movimento
enum MovementState {
	PATROLLING,     # Patrulhando área
	INVESTIGATING,  # Investigando último local conhecido do player
	CHASING_PLAYER, # Perseguindo player ativo
	ATTACKING,      # Atacando player
	SEARCHING,      # Procurando player perdido
	IDLE
}

var current_health: float
var can_attack: bool = true
var player_ref: Node3D
var path_update_timer: float = 0.0
var is_dying: bool = false
var movement_state: MovementState = MovementState.PATROLLING

# Variáveis de IA
var player_spotted: bool = false
var last_known_player_position: Vector3
var time_since_lost_sight: float = 0.0
var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0
var wander_target: Vector3
var idle_timer: float = 0.0
var spawn_position: Vector3

# Detecção visual
var vision_area: Area3D
var vision_collision: CollisionShape3D
var vision_shape: SphereShape3D

@onready var navigation_agent = $NavigationAgent3D
@onready var attack_area = $AttackArea
@onready var billboard = $Billboard
@onready var sprite = $Billboard/Sprite3D
@onready var ghost_cylinder = $GhostCylinder
@onready var collision_shape = $CollisionShape3D

# Cena da label de dano
var damage_label_scene = preload("res://scenes/ui/DamageLabel.tscn")

signal ghost_defeated
signal player_spotted_signal
signal player_lost_signal

func _ready():
	_setup_stage_properties()
	current_health = max_health
	spawn_position = global_position
	print("[Ghost] Fantasma do estágio ", GriefStage.keys()[grief_stage], " inicializado")
	add_to_group("ghosts")
	add_to_group("enemy")
	
	_setup_navigation()
	_setup_vision_detection()
	_find_player()
	_connect_ghost_signal()
	_setup_ghost_appearance()
	_setup_patrol_points()
	_start_patrolling()
	
	# Corrige a altura inicial para ficar alinhado com o NavigationMesh
	await get_tree().process_frame
	_correct_initial_height()

func _correct_initial_height():
	"""Corrige a altura inicial do fantasma para ficar alinhado com o NavigationMesh"""
	if get_world_3d() == null:
		print("⚠️ [Ghost] World3D não disponível para correção de altura")
		return
	
	var navigation_map = get_world_3d().navigation_map
	var nav_position = NavigationServer3D.map_get_closest_point(navigation_map, global_position)
	var target_height = nav_position.y
	
	# Se não conseguir obter a altura da navegação, usa 1.5 como fallback
	if target_height == 0.0 or is_nan(target_height):
		target_height = 1.5
		print("⚠️ [Ghost] Usando altura fallback: ", target_height)
	
	# Atualiza a posição inicial e o spawn_position
	var old_height = global_position.y
	global_position.y = target_height
	spawn_position.y = target_height
	
	print("🔧 [Ghost] Altura inicial corrigida de ", old_height, " para ", target_height)

func _setup_stage_properties():
	if not stage_properties.has(grief_stage):
		print("❌ [Ghost] Erro: Estágio de luto não encontrado: ", grief_stage)
		return
	
	var props = stage_properties[grief_stage]
	
	# Verifica se props é um Dictionary
	if typeof(props) != TYPE_DICTIONARY:
		print("❌ [Ghost] ERRO: props não é um Dictionary!")
		return
	
	# Verifica se as chaves essenciais existem
	if not props.has("vision_range"):
		print("❌ [Ghost] Erro: vision_range não encontrado em props")
		return
	
	# Aplica multiplicadores com verificação de tipo
	var speed_mult = props["speed_multiplier"]
	var health_mult = props["health_multiplier"]
	var vision_val = props["vision_range"]
	var scale_val = props["scale"]
	
	speed *= speed_mult
	max_health *= health_mult
	
	# Garante que vision_range seja sempre um float
	if typeof(vision_val) == TYPE_FLOAT or typeof(vision_val) == TYPE_INT:
		vision_range = float(vision_val)
	else:
		print("❌ [Ghost] Erro: vision_val não é numérico: ", vision_val)
		vision_range = 12.0  # Valor padrão
	
	# Aplica escala
	scale = scale_val
	
	print("✅ [Ghost] Fantasma ", GriefStage.keys()[grief_stage], " configurado - Vision: ", vision_range)

func _get_aggression_level() -> float:
	"""Retorna o nível de agressividade do fantasma com verificação de segurança"""
	if not stage_properties.has(grief_stage):
		print("⚠️ [Ghost] Estágio não encontrado, usando agressividade padrão")
		return 1.0
	
	var props = stage_properties[grief_stage]
	if not props.has("aggression"):
		print("⚠️ [Ghost] Propriedade 'aggression' não encontrada, usando padrão")
		return 1.0
	
	return props["aggression"]

func _get_special_ability() -> String:
	"""Retorna a habilidade especial do fantasma com verificação de segurança"""
	if not stage_properties.has(grief_stage):
		print("⚠️ [Ghost] Estágio não encontrado, usando habilidade padrão")
		return "phase_through"
	
	var props = stage_properties[grief_stage]
	if not props.has("special_ability"):
		print("⚠️ [Ghost] Propriedade 'special_ability' não encontrada, usando padrão")
		return "phase_through"
	
	return props["special_ability"]

func _setup_vision_detection():
	# Garantia de que vision_range é numérico
	if typeof(vision_range) != TYPE_FLOAT and typeof(vision_range) != TYPE_INT:
		print("❌ [Ghost] ERRO: vision_range não é numérico!")
		vision_range = 12.0  # Valor de fallback
	
	# Cria Area3D para detecção visual
	vision_area = Area3D.new()
	vision_area.name = "VisionArea"
	add_child(vision_area)
	
	# Cria forma esférica para detecção
	vision_shape = SphereShape3D.new()
	vision_shape.radius = float(vision_range)  # Força conversão para float
	
	vision_collision = CollisionShape3D.new()
	vision_collision.shape = vision_shape
	vision_collision.name = "VisionCollision"
	vision_area.add_child(vision_collision)
	
	# Conecta sinais
	vision_area.body_entered.connect(_on_vision_body_entered)
	vision_area.body_exited.connect(_on_vision_body_exited)
	
	# Configura layers de detecção
	vision_area.collision_layer = 0
	vision_area.collision_mask = 2  # Layer do player

func _setup_patrol_points():
	"""Configura pontos de patrulha inteligentes ao redor da posição inicial"""
	patrol_points.clear()
	
	var navigation_map = get_world_3d().navigation_map if get_world_3d() else null
	
	# Cria múltiplos anéis de patrulha para cobertura mais ampla
	var patterns = [
		{"radius": patrol_radius * 0.3, "points": 3},  # Anel interno
		{"radius": patrol_radius * 0.6, "points": 4},  # Anel médio
		{"radius": patrol_radius * 1.0, "points": 5}   # Anel externo
	]
	
	for pattern in patterns:
		_add_circular_patrol_points(pattern.radius, pattern.points, navigation_map)
	
	# Adiciona pontos estratégicos em direções cardinais
	_add_cardinal_patrol_points(navigation_map)
	
	# Garante que há pelo menos alguns pontos básicos
	if patrol_points.size() == 0:
		_add_emergency_patrol_points(navigation_map)
	
	# Embaralha os pontos para patrulhamento mais imprevisível
	patrol_points.shuffle()
	
	print("👻 [Ghost] ", patrol_points.size(), " pontos de patrulha configurados para maior cobertura")

func _add_circular_patrol_points(radius: float, num_points: int, navigation_map):
	"""Adiciona pontos de patrulha em círculo com variação"""
	for i in range(num_points):
		var angle = (i * 2.0 * PI) / num_points + randf_range(-0.3, 0.3)  # Variação angular
		var actual_radius = radius + randf_range(-radius * 0.2, radius * 0.2)  # Variação no raio
		
		var point = spawn_position + Vector3(
			cos(angle) * actual_radius,
			0,
			sin(angle) * actual_radius
		)
		
		_validate_and_add_patrol_point(point, navigation_map)

func _add_cardinal_patrol_points(navigation_map):
	"""Adiciona pontos de patrulha nas direções cardinais"""
	var directions = [
		Vector3.FORWARD * patrol_radius * 0.8,
		Vector3.BACK * patrol_radius * 0.8,
		Vector3.LEFT * patrol_radius * 0.8,
		Vector3.RIGHT * patrol_radius * 0.8
	]
	
	for direction in directions:
		var point = spawn_position + direction
		_validate_and_add_patrol_point(point, navigation_map)

func _add_emergency_patrol_points(navigation_map):
	"""Adiciona pontos de patrulha de emergência se nenhum foi criado"""
	var emergency_points = [
		spawn_position + Vector3(8, 0, 0),
		spawn_position + Vector3(-8, 0, 0),
		spawn_position + Vector3(0, 0, 8),
		spawn_position + Vector3(0, 0, -8)
	]
	
	for point in emergency_points:
		_validate_and_add_patrol_point(point, navigation_map)

func _validate_and_add_patrol_point(point: Vector3, navigation_map):
	"""Valida e adiciona um ponto de patrulha com altura correta"""
	# Usa o NavigationMesh para obter a altura correta
	if navigation_map:
		var nav_position = NavigationServer3D.map_get_closest_point(navigation_map, point)
		if nav_position.y != 0.0 and not is_nan(nav_position.y):
			point.y = nav_position.y
		else:
			point.y = spawn_position.y
	else:
		point.y = spawn_position.y
	
	# Verifica se o ponto não está muito próximo de outros pontos
	var min_distance = 4.0
	var too_close = false
	for existing_point in patrol_points:
		if point.distance_to(existing_point) < min_distance:
			too_close = true
			break
	
	if not too_close:
		patrol_points.append(point)

func _start_patrolling():
	movement_state = MovementState.PATROLLING
	current_patrol_index = 0
	if patrol_points.size() > 0:
		navigation_agent.target_position = patrol_points[current_patrol_index]
		print("👻 [Ghost] Patrulhamento iniciado - Target: ", patrol_points[current_patrol_index])
	else:
		print("👻 [Ghost] ❌ ERRO: Nenhum ponto de patrulha definido!")
		# Cria pontos de patrulha de emergência
		_setup_patrol_points()
		if patrol_points.size() > 0:
			navigation_agent.target_position = patrol_points[current_patrol_index]
			print("👻 [Ghost] Pontos de patrulha de emergência criados - Target: ", patrol_points[current_patrol_index])

func _setup_ghost_appearance():
	if not stage_properties.has(grief_stage):
		print("❌ [Ghost] Erro: Estágio de luto não encontrado para aparência: ", grief_stage)
		return
	
	var props = stage_properties[grief_stage]
	
	# Configura o cilindro com shader
	if ghost_cylinder:
		var shader_material = ShaderMaterial.new()
		shader_material.shader = preload("res://shaders/ghost.gdshader")
		shader_material.set_shader_parameter("ghost_color", props["color"])
		shader_material.set_shader_parameter("fuwafuwa_speed", 2.0)
		shader_material.set_shader_parameter("fuwafuwa_size", 0.03)
		shader_material.set_shader_parameter("outline_ratio", 2.0)
		shader_material.set_shader_parameter("noise_speed", 1.5)
		shader_material.set_shader_parameter("noise_scale", 1.5)
		ghost_cylinder.material = shader_material
	
	# Configura a textura do sprite billboard interno
	if sprite and ResourceLoader.exists(props["texture"]):
		var texture = load(props["texture"])
		sprite.texture = texture
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		var color = props["color"]
		sprite.modulate = Color(color.x, color.y, color.z, color.w * 0.8)
		sprite.position = Vector3(0, 0, 0)
		sprite.scale = Vector3(0.8, 0.8, 0.8)

func _setup_navigation():
	# Aguarda um frame para o NavigationServer estar pronto
	await get_tree().process_frame
	await get_tree().process_frame  # Frame extra para garantir
	
	if not navigation_agent:
		print("❌ [Ghost] NavigationAgent3D não encontrado!")
		return
	
	# Configurações básicas de navegação
	navigation_agent.path_desired_distance = 1.0
	navigation_agent.target_desired_distance = 2.0
	navigation_agent.path_max_distance = 50.0
	navigation_agent.avoidance_enabled = false  # Desabilitado para simplicidade
	navigation_agent.radius = 0.5
	navigation_agent.height = 2.0
	navigation_agent.max_speed = speed
	
	# Conecta sinais de navegação
	if not navigation_agent.navigation_finished.is_connected(_on_navigation_finished):
		navigation_agent.navigation_finished.connect(_on_navigation_finished)
	
	print("🧭 [Ghost] NavigationAgent3D configurado - Speed: ", speed, " Max Speed: ", navigation_agent.max_speed)
	print("🧭 [Ghost] Navigation Map: ", NavigationServer3D.map_get_closest_point_owner(get_world_3d().navigation_map, global_position))
	
	# Força uma atualização da navegação
	NavigationServer3D.map_force_update(get_world_3d().navigation_map)

func _find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
		print("[Ghost] Player encontrado: ", player_ref.name)
	else:
		print("⚠️ [Ghost] Jogador não encontrado.")

func _physics_process(delta):
	if is_dying:
		return
		
	if not player_ref:
		_find_player()
		return
	
	# Atualiza detecção visual
	_update_vision_detection(delta)
	
	# Atualiza o caminho periodicamente
	path_update_timer += delta
	if path_update_timer >= path_update_interval:
		path_update_timer = 0.0
		_update_ai_state()
	
	# Executa movimento baseado no estado
	_handle_movement(delta)
	
	# Rotaciona o billboard para sempre olhar para o player
	if billboard and player_ref:
		billboard.look_at(player_ref.global_position, Vector3.UP)

func _update_vision_detection(delta):
	if not player_ref:
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	# Verifica se o player está dentro do alcance de visão
	if distance_to_player <= vision_range:
		# Verifica ângulo de visão
		var direction_to_player = (player_ref.global_position - global_position).normalized()
		var forward_direction = -global_transform.basis.z.normalized()
		var angle_to_player = rad_to_deg(forward_direction.angle_to(direction_to_player))
		
		if angle_to_player <= vision_angle / 2.0:
			# Verifica se há obstáculos entre o fantasma e o player
			if _has_line_of_sight_to_player():
				if not player_spotted:
					_spot_player()
				time_since_lost_sight = 0.0
			else:
				_update_lost_sight_timer(delta)
		else:
			_update_lost_sight_timer(delta)
	else:
		_update_lost_sight_timer(delta)

func _has_line_of_sight_to_player() -> bool:
	if not player_ref:
		return false
	
	var space_state = get_world_3d().direct_space_state
	var from = global_position + Vector3(0, 1, 0)  # Um pouco acima do centro
	var to = player_ref.global_position + Vector3(0, 1, 0)
	
	var ray_params = PhysicsRayQueryParameters3D.create(from, to)
	ray_params.exclude = [self]
	ray_params.collision_mask = 1  # Layer de paredes
	
	var result = space_state.intersect_ray(ray_params)
	return result.is_empty()  # Se não colidiu com nada, tem linha de visão

func _update_lost_sight_timer(delta):
	if player_spotted:
		time_since_lost_sight += delta
		if time_since_lost_sight >= lose_sight_time:
			_lose_player()

func _spot_player():
	player_spotted = true
	last_known_player_position = player_ref.global_position
	emit_signal("player_spotted_signal")
	print("[Ghost] ", GriefStage.keys()[grief_stage], " avistou o player!")

func _lose_player():
	player_spotted = false
	emit_signal("player_lost_signal")
	print("[Ghost] ", GriefStage.keys()[grief_stage], " perdeu o player de vista")

func _on_vision_body_entered(body):
	if body.is_in_group("player"):
		print("[Ghost] Player entrou na área de visão")

func _on_vision_body_exited(body):
	if body.is_in_group("player"):
		print("[Ghost] Player saiu da área de visão")

func _update_ai_state():
	if not player_ref:
		print("👻 [Ghost] Player não encontrado para IA")
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	var aggression_level = _get_aggression_level()
	
	# Debug ocasional para não spam
	if randf() < 0.1:
		print("👻 [Ghost] AI Update - Distance: ", distance_to_player, " State: ", MovementState.keys()[movement_state], " Aggression: ", aggression_level)
	
	# Verifica se pode atacar
	if distance_to_player <= attack_range and player_spotted and can_attack:
		print("👻 [Ghost] Iniciando ataque!")
		_start_attacking()
		return
	
	# IA mais agressiva baseada no nível de agressão
	if player_spotted:
		# Player visível - perseguir agressivamente
		if movement_state != MovementState.CHASING_PLAYER:
			print("👻 [Ghost] Mudando para CHASING_PLAYER (agressivo)")
			_start_chasing()
	else:
		# Player não visível - comportamento baseado na agressividade
		if distance_to_player <= aggressive_chase_distance * aggression_level:
			# Dentro da distância de perseguição agressiva
			if last_known_player_position != Vector3.ZERO:
				# Tem última posição conhecida - investigar agressivamente
				if movement_state != MovementState.INVESTIGATING:
					print("👻 [Ghost] Mudando para INVESTIGATING (agressivo)")
					_start_investigating()
			else:
				# Sem posição conhecida, mas player próximo - procurar ativamente
				if movement_state != MovementState.SEARCHING:
					print("👻 [Ghost] Mudando para SEARCHING (agressivo)")
					_start_aggressive_search()
		else:
			# Longe do player - patrulhar mais ativamente
			if movement_state not in [MovementState.PATROLLING, MovementState.IDLE]:
				print("👻 [Ghost] Mudando para PATROLLING")
				_start_patrolling()
			elif movement_state == MovementState.IDLE and aggression_level > 1.0:
				# Fantasmas agressivos não ficam muito tempo parados
				print("👻 [Ghost] Saindo do IDLE por agressividade")
				_start_patrolling()

func _start_aggressive_search():
	"""Inicia busca agressiva pelo player"""
	movement_state = MovementState.SEARCHING
	
	# Vai para uma posição próxima ao player para procurar
	var search_target = player_ref.global_position + Vector3(
		randf_range(-10, 10),
		0,
		randf_range(-10, 10)
	)
	
	navigation_agent.target_position = search_target
	print("👻 [Ghost] Iniciando busca agressiva em: ", search_target)
	
	# Após um tempo, volta a patrulhar se não encontrar
	await get_tree().create_timer(3.0).timeout
	if movement_state == MovementState.SEARCHING and not player_spotted:
		_start_patrolling()

func _start_chasing():
	movement_state = MovementState.CHASING_PLAYER
	navigation_agent.target_position = player_ref.global_position
	print("[Ghost] ", GriefStage.keys()[grief_stage], " começou a perseguir!")

func _start_investigating():
	movement_state = MovementState.INVESTIGATING
	navigation_agent.target_position = last_known_player_position
	print("[Ghost] ", GriefStage.keys()[grief_stage], " investigando última posição conhecida")

func _start_attacking():
	movement_state = MovementState.ATTACKING
	perform_attack()

func _handle_movement(delta):
	# Calcula velocidade baseada no estado e agressividade
	var current_speed = _calculate_movement_speed()
	
	match movement_state:
		MovementState.PATROLLING:
			_move_towards_target(current_speed)
		MovementState.INVESTIGATING:
			_move_towards_target(current_speed * 1.2)  # Mais rápido ao investigar
		MovementState.CHASING_PLAYER:
			if player_spotted and player_ref:
				navigation_agent.target_position = player_ref.global_position
			_move_towards_target(current_speed * 1.5)  # Muito mais rápido ao perseguir
		MovementState.SEARCHING:
			_move_towards_target(current_speed * 1.3)  # Rápido ao procurar
		MovementState.ATTACKING:
			velocity = Vector3.ZERO
		MovementState.IDLE:
			idle_timer -= delta
			velocity = Vector3.ZERO
			if idle_timer <= 0:
				_start_patrolling()

func _calculate_movement_speed() -> float:
	"""Calcula a velocidade de movimento baseada no estado e agressividade"""
	var base_speed = speed
	var aggression_level = _get_aggression_level()
	
	# Multiplicador baseado na agressividade
	var aggression_multiplier = 0.8 + (aggression_level * 0.4)  # 0.8 a 1.4x
	
	# Multiplicador baseado no estado emocional
	var state_multiplier = 1.0
	match movement_state:
		MovementState.CHASING_PLAYER:
			state_multiplier = 1.3 + (aggression_level * 0.2)  # Muito mais rápido ao perseguir
		MovementState.INVESTIGATING:
			state_multiplier = 1.1 + (aggression_level * 0.1)  # Pouco mais rápido ao investigar
		MovementState.SEARCHING:
			state_multiplier = 1.2 + (aggression_level * 0.15)  # Rápido ao procurar
		MovementState.PATROLLING:
			state_multiplier = 0.9 + (aggression_level * 0.2)  # Velocidade base de patrulha
	
	return base_speed * aggression_multiplier * state_multiplier

func _move_towards_target(movement_speed: float = 0.0):
	if not navigation_agent:
		print("❌ [Ghost] NavigationAgent3D não encontrado!")
		return
	
	# Usa velocidade calculada ou velocidade padrão
	var current_speed = movement_speed if movement_speed > 0.0 else speed
	
	# Verifica se há um caminho válido
	if navigation_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		if randf() < 0.1:  # Debug ocasional
			print("🏁 [Ghost] Navegação finalizada - Posição: ", global_position)
		return
	
	# Obtém a próxima posição do caminho
	var next_path_position = navigation_agent.get_next_path_position()
	var direction = (next_path_position - global_position).normalized()
	
	# Usa o NavigationAgent para obter a altura correta do NavigationMesh
	var navigation_map = get_world_3d().navigation_map
	var nav_position = NavigationServer3D.map_get_closest_point(navigation_map, global_position)
	var target_height = nav_position.y
	
	# Se não conseguir obter a altura da navegação, usa a altura do spawn como fallback
	if target_height == 0.0 or is_nan(target_height):
		target_height = spawn_position.y
	
	# Corrige a altura do fantasma se estiver muito longe da navegação
	if abs(global_position.y - target_height) > 0.5:
		global_position.y = target_height
		if randf() < 0.1:  # Debug ocasional
			print("🔧 [Ghost] Altura corrigida para NavigationMesh: ", target_height)
	
	# Aplica movimento apenas no plano horizontal
	direction.y = 0
	
	# Debug do movimento ocasional para não spam
	if randf() < 0.02:
		print("🚶 [Ghost] Movendo para: ", next_path_position, " | Speed: ", current_speed, " | State: ", MovementState.keys()[movement_state])
	
	# Aplica velocidade horizontal baseada na velocidade calculada
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	
	# Adiciona flutuação vertical suave (pequena oscilação)
	var float_time = Time.get_time_dict_from_system()["second"] + randf() * 10.0
	velocity.y = sin(float_time * 2.0) * 0.1  # Flutuação muito sutil
	
	# Rotaciona o fantasma na direção do movimento
	if direction.length() > 0.1:
		var target_rotation = atan2(direction.x, direction.z)
		var rotation_speed_multiplier = 1.0 + (current_speed / speed - 1.0) * 0.5  # Rotação mais rápida quando mais rápido
		rotation.y = lerp_angle(rotation.y, target_rotation, 0.1 * rotation_speed_multiplier)
	
	# Aplica o movimento
	move_and_slide()
	
	# Garante que a altura seja mantida após o movimento
	var final_nav_position = NavigationServer3D.map_get_closest_point(navigation_map, global_position)
	var final_target_height = final_nav_position.y
	
	# Se não conseguir obter a altura da navegação, usa a altura do spawn
	if final_target_height == 0.0 or is_nan(final_target_height):
		final_target_height = spawn_position.y
	
	if global_position.y < final_target_height - 0.2 or global_position.y > final_target_height + 0.5:
		global_position.y = final_target_height

func _on_navigation_finished():
	match movement_state:
		MovementState.PATROLLING:
			_next_patrol_point()
		MovementState.INVESTIGATING:
			# Chegou ao local, procurar ao redor
			_start_searching_area()

func _next_patrol_point():
	if patrol_points.size() == 0:
		return
	
	var aggression_level = _get_aggression_level()
	
	# Fantasmas mais agressivos podem pular pontos ou ir diretamente para pontos mais distantes
	if aggression_level > 1.0 and randf() < 0.4:
		# Vai para um ponto aleatório em vez do próximo sequencial
		current_patrol_index = randi() % patrol_points.size()
		print("👻 [Ghost] Patrulhamento agressivo - saltando para ponto aleatório")
	else:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	
	navigation_agent.target_position = patrol_points[current_patrol_index]
	
	# Chance de ficar idle baseada na agressividade (menos agressivos ficam mais tempo parados)
	var idle_chance = 0.4 - (aggression_level * 0.2)
	if randf() < idle_chance:
		_start_idle()
	
	print("👻 [Ghost] Próximo ponto de patrulha: ", patrol_points[current_patrol_index])

func _start_searching_area():
	movement_state = MovementState.SEARCHING
	# Procura em um raio ao redor da última posição conhecida
	var search_radius = 3.0
	var random_angle = randf() * 2.0 * PI
	var search_target = last_known_player_position + Vector3(
		cos(random_angle) * search_radius,
		0,
		sin(random_angle) * search_radius
	)
	navigation_agent.target_position = search_target
	
	# Após um tempo, volta a patrulhar
	await get_tree().create_timer(5.0).timeout
	if movement_state == MovementState.SEARCHING:
		last_known_player_position = Vector3.ZERO
		_start_patrolling()

func _start_idle():
	movement_state = MovementState.IDLE
	idle_timer = randf_range(idle_time_min, idle_time_max)
	velocity = Vector3.ZERO

func perform_attack():
	can_attack = false
	print("👊 Ghost ", GriefStage.keys()[grief_stage], " atacou o jogador!")
	
	# Para de se mover durante o ataque
	velocity = Vector3.ZERO
	
	# Executa habilidade especial baseada no estágio
	_execute_special_ability()
	
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(attack_damage)
		print("[Ghost] Causou ", attack_damage, " de dano ao player!")
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	
	# Volta a perseguir se ainda pode ver o player
	if player_spotted:
		movement_state = MovementState.CHASING_PLAYER
	else:
		movement_state = MovementState.INVESTIGATING

func _execute_special_ability():
	var ability = _get_special_ability()
	
	match ability:
		"phase_through":
			_phase_through_ability()
		"rage_attack":
			_rage_attack_ability()
		"heal_others":
			_heal_others_ability()
		"drain_energy":
			_drain_energy_ability()
		"peaceful_death":
			_peaceful_death_ability()

func _phase_through_ability():
	# Negação: Torna-se intangível por um breve momento
	print("🌫️ Ghost da Negação passou através do jogador!")
	collision_layer = 0
	await get_tree().create_timer(1.0).timeout
	collision_layer = 3

func _rage_attack_ability():
	# Raiva: Ataque duplo
	print("😡 Ghost da Raiva ataca com fúria!")
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(attack_damage * 0.5)  # Ataque adicional

func _heal_others_ability():
	# Barganha: Cura outros fantasmas próximos
	print("💙 Ghost da Barganha cura aliados próximos!")
	var nearby_ghosts = get_tree().get_nodes_in_group("ghosts")
	for ghost in nearby_ghosts:
		if ghost != self and global_position.distance_to(ghost.global_position) < 5.0:
			if ghost.has_method("heal"):
				ghost.heal(20)

func _drain_energy_ability():
	# Depressão: Reduz velocidade do jogador temporariamente
	print("😢 Ghost da Depressão drena energia do jogador!")
	if player_ref and player_ref.has_method("apply_slow_effect"):
		player_ref.apply_slow_effect(3.0, 0.5)

func _peaceful_death_ability():
	# Aceitação: Morte pacífica sem causar dano extra
	print("✨ Ghost da Aceitação aceita seu destino...")
	# Não causa dano extra, apenas o ataque normal

func take_damage(amount: int):
	# Método de compatibilidade - chama o método com crítico como false
	take_damage_with_critical(amount, false)

func take_damage_with_critical(amount: int, is_critical: bool = false):
	if current_health <= 0 or is_dying:
		return
		
	current_health -= amount
	
	if is_critical:
		print("💥🔥 [Ghost] Fantasma ", GriefStage.keys()[grief_stage], " tomou DANO CRÍTICO de ", amount, "! Vida restante: ", current_health, "/", max_health)
	else:
		print("👻 [Ghost] Fantasma ", GriefStage.keys()[grief_stage], " tomou ", amount, " de dano! Vida restante: ", current_health, "/", max_health)
	
	# Mostra a label de dano com informação de crítico
	if damage_label_scene:
		var label = damage_label_scene.instantiate()
		add_child(label)
		label.setup(amount, true, is_critical)
	
	# Efeito visual de dano mais intenso para críticos
	var flash_color = Vector4(1.0, 0.0, 0.0, 1.0)  # Vermelho normal
	var flash_duration = 0.3
	
	if is_critical:
		flash_color = Vector4(1.0, 1.0, 0.0, 1.0)  # Amarelo para crítico
		flash_duration = 0.5  # Dura mais tempo
	
	if ghost_cylinder and ghost_cylinder.material is ShaderMaterial:
		var original_color = ghost_cylinder.material.get_shader_parameter("ghost_color")
		ghost_cylinder.material.set_shader_parameter("ghost_color", flash_color)
		await get_tree().create_timer(flash_duration).timeout
		ghost_cylinder.material.set_shader_parameter("ghost_color", original_color)
	elif sprite:
		var original_modulate = sprite.modulate
		var flash_sprite_color = Color(flash_color.x, flash_color.y, flash_color.z, flash_color.w)
		sprite.modulate = flash_sprite_color
		await get_tree().create_timer(flash_duration).timeout
		sprite.modulate = original_modulate
	
	# Aplica shake na câmera quando o fantasma recebe dano (mais intenso para críticos)
	var viewport = get_viewport()
	if viewport:
		var camera = viewport.get_camera_3d()
		if camera and camera.has_method("shake"):
			if is_critical:
				# Shake mais intenso para dano crítico
				if camera.has_method("shake_intense"):
					camera.shake_intense()
				else:
					camera.shake()
			else:
				camera.shake()
	
	# Força o fantasma a reagir ao dano entrando em modo de perseguição
	if player_ref and not player_spotted:
		_spot_player()
		movement_state = MovementState.CHASING_PLAYER
		if is_critical:
			print("🎯🔥 [Ghost] Fantasma ENFURECIDO pelo dano crítico! Iniciando perseguição intensa!")
		else:
			print("🎯 [Ghost] Fantasma alertado pelo dano! Iniciando perseguição!")
	
	# Verifica se morreu
	if current_health <= 0:
		if is_critical:
			print("💀🔥 [Ghost] Fantasma ", GriefStage.keys()[grief_stage], " foi ANIQUILADO com dano crítico!")
		else:
			print("💀 [Ghost] Fantasma ", GriefStage.keys()[grief_stage], " foi derrotado!")
		die()

func heal(amount: int):
	current_health = min(current_health + amount, max_health)
	print("[Ghost] ", GriefStage.keys()[grief_stage], " curado em ", amount, " pontos!")

func die():
	if is_dying:
		return
		
	is_dying = true
	print("💀 [Ghost] Iniciando sequência de morte do estágio ", GriefStage.keys()[grief_stage])
	
	# === CONCEDE PONTOS DE LUCIDEZ ===
	# Conecta ao LucidityManager para conceder pontos
	var lucidity_manager = get_node_or_null("/root/LucidityManager")
	if lucidity_manager and lucidity_manager.has_method("add_lucidity_point"):
		lucidity_manager.add_lucidity_point(1)
		print("✨ [Ghost] Fantasma derrotado! +1 ponto de lucidez concedido")
	else:
		print("⚠️ [Ghost] LucidityManager não encontrado - pontos não concedidos")
	
	# Executa morte especial baseada no estágio
	_execute_death_special()
	
	# Emite sinal de derrota
	emit_signal("ghost_defeated")
	
	# Remove o fantasma da cena após um pequeno delay para dar tempo dos efeitos
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _execute_death_special():
	match grief_stage:
		GriefStage.DENIAL:
			print("🌫️ Ghost da Negação desaparece lentamente...")
		GriefStage.ANGER:
			print("💥 Ghost da Raiva explode de raiva!")
			_create_explosion_effect()
		GriefStage.BARGAINING:
			print("💎 Ghost da Barganha deixa um item especial...")
		GriefStage.DEPRESSION:
			print("😢 Ghost da Depressão se dissolve em lágrimas...")
		GriefStage.ACCEPTANCE:
			print("✨ Ghost da Aceitação parte em paz...")

func _create_explosion_effect():
	# Cria efeito de explosão para o ghost da raiva
	var explosion_area = Area3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 3.0
	var collision = CollisionShape3D.new()
	collision.shape = shape
	explosion_area.add_child(collision)
	explosion_area.global_transform.origin = global_transform.origin
	get_tree().current_scene.add_child(explosion_area)
	
	# Dano em área
	for body in explosion_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.take_damage(attack_damage)
	
	# Remove a área após um tempo
	await get_tree().create_timer(0.1).timeout
	explosion_area.queue_free()

func _connect_ghost_signal():
	# Conecta sinais necessários
	pass

# Método para o sistema de dano do player
func get_grief_stage() -> int:
	return grief_stage 
