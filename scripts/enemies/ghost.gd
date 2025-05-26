extends CharacterBody3D

@export var ghost_type: int = 1 # 1=Normal, 2=Rápido, 3=Tanque, 4=Explosivo
@export var max_health: float = 100.0
@export var speed: float = 3.0
@export var attack_range: float = 1.5
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.0
@export var ghost_color: Color = Color(1,1,1,0.5)
@export var ghost_scale: Vector3 = Vector3(1,1,1)
@export var path_update_interval: float = 0.5 # Intervalo para atualizar o caminho
@export var rotation_speed: float = 10.0 # Velocidade de rotação do ghost

var current_health: float
var can_attack: bool = true
var player_ref: Node3D
var path_update_timer: float = 0.0

@onready var navigation_agent = $NavigationAgent3D
@onready var attack_area = $AttackArea
@onready var mesh = $CSGCylinder3D

func _ready():
	current_health = max_health
	add_to_group("enemy")
	self.scale = ghost_scale
	
	# Configura o NavigationAgent3D
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5
	navigation_agent.path_max_distance = 10.0
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 0.5
	navigation_agent.neighbor_distance = 50.0
	navigation_agent.max_neighbors = 10
	navigation_agent.time_horizon = 1.0
	navigation_agent.max_speed = speed
	
	# Aplica cor
	if mesh and mesh.material is ShaderMaterial:
		mesh.material.set_shader_parameter("ghost_color", Vector4(ghost_color.r, ghost_color.g, ghost_color.b, ghost_color.a))
	
	# Busca o jogador
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
		direction.y = 0 # Mantém o ghost no mesmo nível
		velocity = direction * speed
		
		# Rotaciona o ghost para a direção do movimento
		if direction != Vector3.ZERO:
			var target_rotation = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, delta * rotation_speed)
		
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
	print("👊 Ghost atacou o jogador!")
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(attack_damage)
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(damage: float) -> void:
	current_health -= damage
	print("DEBUG: Ghost tomou ", damage, " de dano! Vida restante: ", current_health)
	if mesh and mesh.material is ShaderMaterial:
		mesh.material.set_shader_parameter("ghost_color", Vector4(2, 0, 0, 0.5))
		await get_tree().create_timer(0.2).timeout
		mesh.material.set_shader_parameter("ghost_color", Vector4(ghost_color.r, ghost_color.g, ghost_color.b, ghost_color.a))
	if current_health <= 0:
		die()

func die() -> void:
	print("DEBUG: Ghost morreu!")
	# Atributo especial ao morrer
	_on_special_death()
	# Salva dados do ghost e troca para a cena de batalha
	BattleData.enemy_data = {
		"scene_path": "res://scenes/enemies/ghost1.tscn", # Caminho da cena do ghost
		"ghost_type": ghost_type,
		"max_health": max_health,
		"current_health": current_health,
		"speed": speed,
		"attack_range": attack_range,
		"attack_damage": attack_damage,
		"attack_cooldown": attack_cooldown,
		"ghost_color": ghost_color,
		"ghost_scale": ghost_scale
	}
	get_node("/root/SceneManager").change_scene("battle")
	await get_tree().create_timer(0.5).timeout
	queue_free()

# Atributo especial de cada tipo
func _on_special_death():
	match ghost_type:
		1:
			pass # Normal
		2:
			pass # Rápido
		3:
			pass # Tanque
		4:
			_explode()

func _explode():
	print("💥 Ghost Explosivo explodiu!")
	# Dano em área (exemplo)
	var area = Area3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 3.0
	var collision = CollisionShape3D.new()
	collision.shape = shape
	area.add_child(collision)
	area.global_transform.origin = global_transform.origin
	get_tree().current_scene.add_child(area)
	# Dano a todos jogadores próximos
	for body in area.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.take_damage(attack_damage * 2)
	area.queue_free()
