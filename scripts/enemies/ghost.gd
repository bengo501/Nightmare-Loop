extends CharacterBody3D

@export var max_health: float = 100.0
@export var speed: float = 3.0
@export var attack_range: float = 1.5
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.0

var current_health: float
var can_attack: bool = true
var player_ref: Node3D
var battle_manager: Node

@onready var agent = $Agent
@onready var attack_area = $AttackArea

func _ready():
	current_health = max_health
	add_to_group("enemy")

	# Busca o jogador
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
	else:
		print("⚠️ Jogador não encontrado.")
		
	# Busca o gerenciador de batalha
	battle_manager = get_node("/root/BattleSceneManager")
	if not battle_manager:
		print("⚠️ BattleSceneManager não encontrado.")

func _physics_process(delta):
	if not player_ref:
		return

	# Atualiza destino do agente
	agent.set_target_position(player_ref.global_transform.origin)

	# Caminha até o destino
	if agent.is_navigation_finished() == false:
		var direction = (agent.get_next_path_position() - global_transform.origin).normalized()
		direction.y = 0
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		move_and_slide()
	else:
		velocity = Vector3.ZERO

	# Verifica distância de ataque
	var distance = global_transform.origin.distance_to(player_ref.global_transform.origin)
	if distance <= attack_range and can_attack:
		perform_attack()

func perform_attack():
	can_attack = false
	print("👊 Ghost atacou o jogador!")

	# Aplica dano ao player se tiver método
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(attack_damage)

	# Cooldown de ataque
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(damage: float) -> void:
	current_health -= damage
	print("DEBUG: Ghost tomou ", damage, " de dano! Vida restante: ", current_health)

	var material := $CSGCylinder3D.material as ShaderMaterial
	if material:
		material.set_shader_parameter("ghost_color", Vector4(2, 0, 0, 0.5))
		await get_tree().create_timer(0.2).timeout
		material.set_shader_parameter("ghost_color", Vector4(2, 3, 0.85, 0.5))

	if current_health <= 0:
		die()

func die() -> void:
	print("DEBUG: Ghost morreu!")
	
	# Inicia a cena de batalha antes de remover o fantasma
	if battle_manager:
		battle_manager.start_battle()
	
	# Aguarda um pequeno delay antes de remover o fantasma
	await get_tree().create_timer(0.5).timeout
	queue_free()
