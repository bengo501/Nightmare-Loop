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
@export var vision_range: float = 12.0
@export var vision_angle: float = 90.0  # Ângulo de visão em graus
@export var lose_sight_time: float = 3.0  # Tempo para perder o player de vista

# Propriedades de movimento
@export var wander_radius: float = 10.0
@export var wander_chance: float = 0.3
@export var idle_time_min: float = 2.0
@export var idle_time_max: float = 5.0

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
	# Cria pontos de patrulha ao redor da posição inicial
	patrol_points.clear()
	var num_points = 4
	var radius = wander_radius * 0.7
	
	for i in range(num_points):
		var angle = (i * 2.0 * PI) / num_points
		var point = spawn_position + Vector3(
			cos(angle) * radius,
			0,
			sin(angle) * radius
		)
		patrol_points.append(point)

func _start_patrolling():
	movement_state = MovementState.PATROLLING
	current_patrol_index = 0
	if patrol_points.size() > 0:
		navigation_agent.target_position = patrol_points[current_patrol_index]

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
	
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 1.0
	navigation_agent.path_max_distance = 25.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 0.4
	navigation_agent.neighbor_distance = 8.0
	navigation_agent.max_neighbors = 6
	navigation_agent.time_horizon = 1.5
	navigation_agent.max_speed = speed
	
	# Conecta sinais de navegação
	navigation_agent.navigation_finished.connect(_on_navigation_finished)

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
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	# Verifica se pode atacar
	if distance_to_player <= attack_range and player_spotted and can_attack:
		_start_attacking()
		return
	
	# Estado baseado na detecção do player
	if player_spotted:
		# Player visível - perseguir
		if movement_state != MovementState.CHASING_PLAYER:
			_start_chasing()
	else:
		# Player não visível
		if last_known_player_position != Vector3.ZERO:
			# Tem última posição conhecida - investigar
			if movement_state != MovementState.INVESTIGATING:
				_start_investigating()
		else:
			# Sem informação do player - patrulhar
			if movement_state not in [MovementState.PATROLLING, MovementState.IDLE]:
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
	match movement_state:
		MovementState.PATROLLING:
			_move_towards_target()
		MovementState.INVESTIGATING:
			_move_towards_target()
		MovementState.CHASING_PLAYER:
			if player_spotted and player_ref:
				navigation_agent.target_position = player_ref.global_position
			_move_towards_target()
		MovementState.ATTACKING:
			velocity = Vector3.ZERO
		MovementState.IDLE:
			idle_timer -= delta
			velocity = Vector3.ZERO
			if idle_timer <= 0:
				_start_patrolling()

func _move_towards_target():
	if navigation_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return
	
	var next_path_position = navigation_agent.get_next_path_position()
	var direction = (next_path_position - global_position).normalized()
	direction.y = 0  # Mantém no plano horizontal
	
	# Adiciona flutuação vertical suave
	var float_offset = sin(Time.get_time_dict_from_system().second * 2.0) * 0.15
	
	velocity = direction * speed
	velocity.y = float_offset
	
	# Rotaciona o fantasma na direção do movimento
	if direction.length() > 0.1:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * get_physics_process_delta_time())
	
	move_and_slide()

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
		
	current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	navigation_agent.target_position = patrol_points[current_patrol_index]
	
	# Chance de ficar idle no ponto de patrulha
	if randf() < 0.3:
		_start_idle()

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
	if not stage_properties.has(grief_stage):
		print("❌ [Ghost] Erro: Estágio de luto não encontrado para habilidade: ", grief_stage)
		return
	
	var ability = stage_properties[grief_stage]["special_ability"]
	
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
	if current_health <= 0 or is_dying:
		return
		
	current_health -= amount
	print("DEBUG: Ghost ", GriefStage.keys()[grief_stage], " tomou ", amount, " de dano! Vida restante: ", current_health)
	
	# Mostra a label de dano
	if damage_label_scene:
		var label = damage_label_scene.instantiate()
		add_child(label)
		label.setup(amount, true)
	
	# Efeito visual de dano
	if sprite:
		var original_modulate = sprite.modulate
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.2).timeout
		sprite.modulate = original_modulate
	
	# Verifica se morreu
	if current_health <= 0:
		print("[Ghost] Fantasma ", GriefStage.keys()[grief_stage], " morreu!")
		die()

func heal(amount: int):
	current_health = min(current_health + amount, max_health)
	print("[Ghost] ", GriefStage.keys()[grief_stage], " curado em ", amount, " pontos!")

func die():
	if is_dying:
		return
		
	is_dying = true
	print("[Ghost] Iniciando sequência de morte do estágio ", GriefStage.keys()[grief_stage])
	
	# Executa morte especial baseada no estágio
	_execute_death_special()
	
	# Emite sinal de derrota
	emit_signal("ghost_defeated")
	
	# Remove o fantasma da cena
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
