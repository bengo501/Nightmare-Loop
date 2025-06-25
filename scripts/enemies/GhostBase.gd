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
@export var path_update_interval: float = 0.5
@export var rotation_speed: float = 10.0

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
		"scale": Vector3(0.6, 0.6, 0.6)
	},
	GriefStage.ANGER: {
		"color": Vector4(0.7, 0.7, 0.7, 0.8),
		"texture": "res://assets/textures/greyGhost.png",
		"speed_multiplier": 1.5,
		"health_multiplier": 1.2,
		"special_ability": "rage_attack",
		"scale": Vector3(0.7, 0.7, 0.7)
	},
	GriefStage.BARGAINING: {
		"color": Vector4(0.2, 0.2, 1.0, 0.6),
		"texture": "res://assets/textures/blueGhost.png",
		"speed_multiplier": 0.8,
		"health_multiplier": 1.5,
		"special_ability": "heal_others",
		"scale": Vector3(0.8, 0.8, 0.8)
	},
	GriefStage.DEPRESSION: {
		"color": Vector4(0.6, 0.2, 0.8, 0.5),
		"texture": "res://assets/textures/purpleGhost.png",
		"speed_multiplier": 0.6,
		"health_multiplier": 2.0,
		"special_ability": "drain_energy",
		"scale": Vector3(0.9, 0.9, 0.9)
	},
	GriefStage.ACCEPTANCE: {
		"color": Vector4(1.0, 1.0, 0.2, 0.9),
		"texture": "res://assets/textures/yellowGhost.png",
		"speed_multiplier": 1.2,
		"health_multiplier": 0.8,
		"special_ability": "peaceful_death",
		"scale": Vector3(0.5, 0.5, 0.5)
	}
}

# Estados de movimento
enum MovementState {
	CHASING_PLAYER,
	WANDERING,
	IDLE,
	ATTACKING
}

var current_health: float
var can_attack: bool = true
var player_ref: Node3D
var path_update_timer: float = 0.0
var is_dying: bool = false
var movement_state: MovementState = MovementState.WANDERING
var wander_target: Vector3
var idle_timer: float = 0.0
var spawn_position: Vector3

@onready var navigation_agent = $NavigationAgent3D
@onready var attack_area = $AttackArea
@onready var billboard = $Billboard
@onready var sprite = $Billboard/Sprite3D
@onready var ghost_cylinder = $GhostCylinder
@onready var collision_shape = $CollisionShape3D

# Cena da label de dano
var damage_label_scene = preload("res://scenes/ui/DamageLabel.tscn")

signal ghost_defeated

func _ready():
	_setup_stage_properties()
	current_health = max_health
	spawn_position = global_position
	print("[Ghost] Fantasma do estágio ", GriefStage.keys()[grief_stage], " inicializado")
	add_to_group("ghosts")
	add_to_group("enemy")
	
	_setup_navigation()
	_find_player()
	_connect_ghost_signal()
	_setup_ghost_appearance()
	_start_wandering()

func _setup_stage_properties():
	var props = stage_properties[grief_stage]
	
	# Aplica multiplicadores
	speed *= props.speed_multiplier
	max_health *= props.health_multiplier
	
	# Aplica escala
	scale = props.scale

func _setup_ghost_appearance():
	var props = stage_properties[grief_stage]
	
	# Configura o cilindro com shader
	if ghost_cylinder:
		var shader_material = ShaderMaterial.new()
		shader_material.shader = preload("res://shaders/ghost.gdshader")
		shader_material.set_shader_parameter("ghost_color", props.color)
		shader_material.set_shader_parameter("fuwafuwa_speed", 2.0)
		shader_material.set_shader_parameter("fuwafuwa_size", 0.03)
		shader_material.set_shader_parameter("outline_ratio", 2.0)
		shader_material.set_shader_parameter("noise_speed", 1.5)
		shader_material.set_shader_parameter("noise_scale", 1.5)
		ghost_cylinder.material = shader_material
	
	# Configura a textura do sprite billboard interno
	if sprite and ResourceLoader.exists(props.texture):
		var texture = load(props.texture)
		sprite.texture = texture
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.modulate = Color(props.color.x, props.color.y, props.color.z, props.color.w * 0.8)
		# Posiciona o sprite um pouco para dentro do cilindro
		sprite.position = Vector3(0, 0, 0)
		sprite.scale = Vector3(0.8, 0.8, 0.8)

func _setup_navigation():
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5
	navigation_agent.path_max_distance = 15.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 0.3
	navigation_agent.neighbor_distance = 50.0
	navigation_agent.max_neighbors = 10
	navigation_agent.time_horizon = 1.0
	navigation_agent.max_speed = speed

func _find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
	else:
		print("⚠️ Jogador não encontrado.")

func _physics_process(delta):
	if is_dying:
		return
		
	if not player_ref:
		_find_player()
		return
	
	# Atualiza o caminho periodicamente
	path_update_timer += delta
	if path_update_timer >= path_update_interval:
		path_update_timer = 0.0
		_update_movement_state()
	
	# Executa movimento baseado no estado
	_handle_movement(delta)
	
	# Rotaciona o billboard para sempre olhar para o player
	if billboard and player_ref:
		billboard.look_at(player_ref.global_position, Vector3.UP)

func _update_movement_state():
	if not player_ref:
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	# Verifica se pode atacar
	if distance_to_player <= attack_range and can_attack:
		movement_state = MovementState.ATTACKING
		perform_attack()
		return
	
	# Decide entre perseguir o jogador ou vagar
	if distance_to_player <= 8.0:  # Raio de detecção do jogador
		movement_state = MovementState.CHASING_PLAYER
		navigation_agent.target_position = player_ref.global_position
	else:
		# Chance de começar a vagar ou ficar idle
		if randf() < wander_chance:
			_start_wandering()
		elif randf() < 0.2:  # 20% chance de ficar idle
			_start_idle()

func _start_wandering():
	movement_state = MovementState.WANDERING
	# Gera um ponto aleatório ao redor da posição de spawn
	var random_angle = randf() * 2.0 * PI
	var random_distance = randf() * wander_radius
	wander_target = spawn_position + Vector3(
		cos(random_angle) * random_distance,
		0,
		sin(random_angle) * random_distance
	)
	navigation_agent.target_position = wander_target

func _start_idle():
	movement_state = MovementState.IDLE
	idle_timer = randf_range(idle_time_min, idle_time_max)
	velocity = Vector3.ZERO

func _handle_movement(delta):
	match movement_state:
		MovementState.CHASING_PLAYER:
			_move_towards_target()
		MovementState.WANDERING:
			_move_towards_target()
			# Verifica se chegou ao destino
			if navigation_agent.is_navigation_finished():
				_start_idle()
		MovementState.IDLE:
			idle_timer -= delta
			velocity = Vector3.ZERO
			if idle_timer <= 0:
				_start_wandering()
		MovementState.ATTACKING:
			velocity = Vector3.ZERO

func _move_towards_target():
	if navigation_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return
	
	var next_path_position = navigation_agent.get_next_path_position()
	var direction = (next_path_position - global_position).normalized()
	direction.y = 0  # Mantém no plano horizontal
	
	# Adiciona um pouco de flutuação vertical
	var float_offset = sin(Time.get_time_dict_from_system().second * 2.0) * 0.1
	velocity = direction * speed
	velocity.y = float_offset
	
	move_and_slide()

func perform_attack():
	can_attack = false
	print("👊 Ghost ", GriefStage.keys()[grief_stage], " atacou o jogador!")
	
	# Executa habilidade especial baseada no estágio
	_execute_special_ability()
	
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(attack_damage)
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	movement_state = MovementState.CHASING_PLAYER

func _execute_special_ability():
	var ability = stage_properties[grief_stage].special_ability
	
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