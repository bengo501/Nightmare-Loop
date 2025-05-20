extends CharacterBody3D

@export var ghost_type: int = 1 # 1=Normal, 2=Rápido, 3=Tanque, 4=Explosivo
@export var max_health: float = 100.0
@export var speed: float = 3.0
@export var attack_range: float = 1.5
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.0
@export var ghost_color: Color = Color(1,1,1,0.5)
@export var ghost_scale: Vector3 = Vector3(1,1,1)

var current_health: float
var can_attack: bool = true
var player_ref: Node3D
var battle_manager: Node

@onready var agent = $Agent
@onready var attack_area = $AttackArea
@onready var mesh = $CSGCylinder3D

func _ready():
	current_health = max_health
	add_to_group("enemy")
	self.scale = ghost_scale
	# Aplica cor
	if mesh and mesh.material is ShaderMaterial:
		mesh.material.set_shader_parameter("ghost_color", Vector4(ghost_color.r, ghost_color.g, ghost_color.b, ghost_color.a))
	# Busca o jogador
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
	else:
		print("⚠️ Jogador não encontrado.")
	# Busca o gerenciador de batalha
	battle_manager = get_node_or_null("/root/BattleSceneManager")
	if not battle_manager:
		print("⚠️ BattleSceneManager não encontrado.")

func _physics_process(delta):
	if not player_ref:
		return
	agent.set_target_position(player_ref.global_transform.origin)
	if agent.is_navigation_finished() == false:
		var direction = (agent.get_next_path_position() - global_transform.origin).normalized()
		direction.y = 0
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		move_and_slide()
	else:
		velocity = Vector3.ZERO
	var distance = global_transform.origin.distance_to(player_ref.global_transform.origin)
	if distance <= attack_range and can_attack:
		perform_attack()

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
	# Inicia a cena de batalha antes de remover o fantasma
	if battle_manager:
		battle_manager.start_battle(self)
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
