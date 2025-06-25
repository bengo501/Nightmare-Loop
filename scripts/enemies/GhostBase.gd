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

# Propriedades específicas por estágio
var stage_properties = {
	GriefStage.DENIAL: {
		"color": Color(0.2, 1.0, 0.2, 0.7),
		"texture": "res://assets/textures/greenGhost.png",
		"speed_multiplier": 1.0,
		"health_multiplier": 1.0,
		"special_ability": "phase_through"
	},
	GriefStage.ANGER: {
		"color": Color(0.7, 0.7, 0.7, 0.8),
		"texture": "res://assets/textures/greyGhost.png",
		"speed_multiplier": 1.5,
		"health_multiplier": 1.2,
		"special_ability": "rage_attack"
	},
	GriefStage.BARGAINING: {
		"color": Color(0.2, 0.2, 1.0, 0.6),
		"texture": "res://assets/textures/blueGhost.png",
		"speed_multiplier": 0.8,
		"health_multiplier": 1.5,
		"special_ability": "heal_others"
	},
	GriefStage.DEPRESSION: {
		"color": Color(0.6, 0.2, 0.8, 0.5),
		"texture": "res://assets/textures/purpleGhost.png",
		"speed_multiplier": 0.6,
		"health_multiplier": 2.0,
		"special_ability": "drain_energy"
	},
	GriefStage.ACCEPTANCE: {
		"color": Color(1.0, 1.0, 0.2, 0.9),
		"texture": "res://assets/textures/yellowGhost.png",
		"speed_multiplier": 1.2,
		"health_multiplier": 0.8,
		"special_ability": "peaceful_death"
	}
}

var current_health: float
var can_attack: bool = true
var player_ref: Node3D
var path_update_timer: float = 0.0
var is_dying: bool = false

@onready var navigation_agent = $NavigationAgent3D
@onready var attack_area = $AttackArea
@onready var billboard = $Billboard
@onready var sprite = $Billboard/Sprite3D

# Cena da label de dano
var damage_label_scene = preload("res://scenes/ui/DamageLabel.tscn")

signal ghost_defeated

func _ready():
	_setup_stage_properties()
	current_health = max_health
	print("[Ghost] Fantasma do estágio ", GriefStage.keys()[grief_stage], " inicializado")
	add_to_group("ghosts")
	add_to_group("enemy")
	
	_setup_navigation()
	_find_player()
	_connect_ghost_signal()

func _setup_stage_properties():
	var props = stage_properties[grief_stage]
	
	# Aplica multiplicadores
	speed *= props.speed_multiplier
	max_health *= props.health_multiplier
	
	# Configura a textura do sprite
	if sprite and ResourceLoader.exists(props.texture):
		var texture = load(props.texture)
		sprite.texture = texture
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.modulate = props.color

func _setup_navigation():
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5
	navigation_agent.path_max_distance = 10.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 0.5
	navigation_agent.neighbor_distance = 50.0
	navigation_agent.max_neighbors = 10
	navigation_agent.time_horizon = 1.0
	navigation_agent.max_speed = speed

func _find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
		_update_navigation_target()
	else:
		print("⚠️ Jogador não encontrado.")

func _physics_process(delta):
	if not player_ref:
		return
		
	# Atualiza o caminho periodicamente
	path_update_timer += delta
	if path_update_timer >= path_update_interval:
		path_update_timer = 0.0
		_update_navigation_target()
	
	# Move o ghost
	if navigation_agent.is_navigation_finished():
		velocity = Vector3.ZERO
	else:
		var next_path_position = navigation_agent.get_next_path_position()
		var direction = (next_path_position - global_position).normalized()
		direction.y = 0
		velocity = direction * speed
		
		# Rotaciona o billboard para sempre olhar para o player
		if billboard and player_ref:
			billboard.look_at(player_ref.global_position, Vector3.UP)
		
		move_and_slide()
	
	# Verifica se pode atacar
	var distance = global_position.distance_to(player_ref.global_position)
	if distance <= attack_range and can_attack:
		perform_attack()

func _update_navigation_target():
	if player_ref and navigation_agent:
		navigation_agent.target_position = player_ref.global_position

func perform_attack():
	can_attack = false
	print("👊 Ghost ", GriefStage.keys()[grief_stage], " atacou o jogador!")
	
	# Executa habilidade especial baseada no estágio
	_execute_special_ability()
	
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(attack_damage)
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

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