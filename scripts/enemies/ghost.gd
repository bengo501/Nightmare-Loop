extends CharacterBody3D

@export var ghost_type: int = 1 # 1=Normal, 2=Rápido, 3=Tanque, 4=Explosivo
@export var max_health: float = 100.0
@export var speed: float = 3.0
@export var attack_range: float = 1.5
@export var attack_damage: float = 20.0  # Dano fixo de 20 na exploração 3D
@export var attack_cooldown: float = 1.0
@export var ghost_color: Color = Color(1,1,1,0.5)
@export var ghost_scale: Vector3 = Vector3(1,1,1)
@export var path_update_interval: float = 0.5 # Intervalo para atualizar o caminho
@export var rotation_speed: float = 10.0 # Velocidade de rotação do ghost

var current_health: float
var can_attack: bool = true
var player_ref: Node3D
var path_update_timer: float = 0.0
var is_dying: bool = false

@onready var navigation_agent = $NavigationAgent3D
@onready var attack_area = $AttackArea
@onready var mesh = $CSGCylinder3D
@onready var animation_player = $AnimationPlayer

@onready var camera = get_node("/root/Game/Player/Camera3D")
@onready var collision_shape = $CollisionShape3D


# Cena da label de dano
var damage_label_scene = preload("res://scenes/ui/DamageLabel.tscn")

signal ghost_defeated

func _ready():
	current_health = max_health
	print("[Ghost] Fantasma inicializado com vida: ", current_health, "/", max_health)
	add_to_group("ghosts")
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
		
	print("[Ghost] Fantasma adicionado ao grupo 'ghosts' e 'enemy'")
	
	# Conecta o sinal ghost_defeated
	_connect_ghost_signal()

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
		
		# Usa o NavigationMesh para obter a altura correta
		var navigation_map = get_world_3d().navigation_map
		var nav_position = NavigationServer3D.map_get_closest_point(navigation_map, global_position)
		var target_height = nav_position.y
		
		# Se não conseguir obter a altura da navegação, usa 1.5 como fallback
		if target_height == 0.0 or is_nan(target_height):
			target_height = 1.5
		
		# Corrige a altura se necessário
		if abs(global_position.y - target_height) > 0.3:
			global_position.y = target_height
		
		direction.y = 0 # Mantém o movimento apenas no plano horizontal
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

func take_damage(amount: int):
	if current_health <= 0 or is_dying:  # Se já estiver morto ou morrendo, não faz nada
		return
		
	current_health -= amount
	print("DEBUG: Ghost tomou ", amount, " de dano! Vida restante: ", current_health)
	
	# Mostra a label de dano
	var label = damage_label_scene.instantiate()
	add_child(label)
	label.setup(amount, true)
	

	
	# Efeito visual de dano
	if mesh and mesh.material is ShaderMaterial:
		mesh.material.set_shader_parameter("ghost_color", Vector4(2, 0, 0, 0.5))
		await get_tree().create_timer(0.2).timeout
		mesh.material.set_shader_parameter("ghost_color", Vector4(ghost_color.r, ghost_color.g, ghost_color.b, ghost_color.a))
	
	# Toca animação de dano
	if animation_player:
		animation_player.play("take_damage")
	
	# Aplica shake na câmera
	var viewport = get_viewport()
	if viewport:
		var camera = viewport.get_camera_3d()
		if camera and camera.get_script() and camera.get_script().resource_path.ends_with("FirstPersonCamera.gd"):
			camera.shake()
	
	# Verifica se morreu
	if current_health <= 0:
		print("[Ghost] Fantasma morreu! Chamando função die()...")
		die()

func attack_player():
	# Lógica de ataque
	var damage = 10  # Exemplo de dano fixo
	
	# Toca animação de ataque
	if animation_player:
		animation_player.play("attack")

func die() -> void:
	if is_dying:
		return
		
	is_dying = true
	print("[Ghost] Iniciando sequência de morte...")
	
	# === CONCEDE PONTOS DE HABILIDADE ===
	# Conecta ao SkillManager para conceder pontos
	# Concede pontos de lucidez quando o fantasma morre
	var lucidity_manager = get_node("/root/LucidityManager")
	if lucidity_manager:
		lucidity_manager.add_lucidity_point(1)
		print("🎯 Fantasma derrotado! +1 ponto de lucidez concedido")
	else:
		print("[Ghost] AVISO: SkillManager não encontrado - pontos não concedidos")
	
	# Toca animação de morte
	if animation_player:
		animation_player.play("die")
		await animation_player.animation_finished
	
	# Emite sinal de derrota
	emit_signal("ghost_defeated")
	
	# Remove o fantasma da cena
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

func _connect_ghost_signal():
	if has_signal("ghost_defeated") and has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if not is_connected("ghost_defeated", Callable(gm, "_on_ghost_defeated")):
			var error = connect("ghost_defeated", Callable(gm, "_on_ghost_defeated"))
			if error == OK:
				print("[Ghost] Sinal ghost_defeated conectado ao GameManager com sucesso!")
			else:
				push_error("[Ghost] Erro ao conectar sinal ghost_defeated ao GameManager: " + str(error))
