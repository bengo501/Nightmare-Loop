extends Area3D

@onready var mesh_instance = $MeshInstance3D
@onready var point_light = $OmniLight3D
@onready var interaction_prompt = $InteractionPrompt/Label3D

var can_interact: bool = false
var is_collected: bool = false
var health_recovery: int = 20

# Cor específica do item de vida (verde brilhante)
var health_color: Color = Color(0.2, 1.0, 0.2, 1.0)

# OTIMIZAÇÃO: Timer para verificação de input
var input_check_timer: Timer

func _ready():
	# === FORÇA CONFIGURAÇÕES DE COLLISION ===
	monitoring = true
	monitorable = true
	collision_layer = 0
	collision_mask = 2
	
	# Debug detalhado
	print("❤️ [HealthItem] Item de vida criado")
	print("❤️ [HealthItem] Collision Layer: ", collision_layer)
	print("❤️ [HealthItem] Collision Mask: ", collision_mask)
	print("❤️ [HealthItem] Monitoring: ", monitoring)
	print("❤️ [HealthItem] Monitorable: ", monitorable)
	print("❤️ [HealthItem] Posição: ", global_position)
	
	# OTIMIZAÇÃO: Setup timer ao invés de _process
	_setup_input_timer()
	
	# Configurar animação de rotação e flutuação
	_setup_animations()
	
	# Conectar sinais
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Configurar visual
	_setup_visual()
	
	# Esconde o prompt inicialmente
	if interaction_prompt and is_instance_valid(interaction_prompt):
		interaction_prompt.visible = false
		interaction_prompt.text = "Pressione E para coletar\nItem de Vida (+20 HP)"

func _setup_input_timer():
	"""OTIMIZAÇÃO: Timer para verificação de input ao invés de _process"""
	input_check_timer = Timer.new()
	input_check_timer.wait_time = 0.033  # ~30 FPS
	input_check_timer.autostart = true
	input_check_timer.timeout.connect(_check_input)
	add_child(input_check_timer)

func _check_input():
	"""OTIMIZAÇÃO: Verifica input apenas quando necessário"""
	if can_interact and not is_collected:
		if Input.is_action_just_pressed("interact"):
			print("❤️ [HealthItem] Tecla E pressionada! Coletando...")
			collect()

func _setup_animations():
	# Animação de rotação
	var rotation_tween = create_tween()
	rotation_tween.set_loops()
	rotation_tween.tween_property(self, "rotation_degrees", Vector3(0, 360, 0), 2.0)
	
	# Animação de flutuação
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(self, "position", position + Vector3(0, 0.5, 0), 1.0)
	float_tween.tween_property(self, "position", position - Vector3(0, 0.5, 0), 1.0)

func _setup_visual():
	# Configurar cor da luz
	if point_light and is_instance_valid(point_light):
		point_light.light_color = health_color
		point_light.light_energy = 3.0
		point_light.omni_range = 5.0
		
		# Efeito pulsante na luz
		var light_tween = create_tween()
		light_tween.set_loops()
		light_tween.tween_property(point_light, "light_energy", 4.0, 0.8)
		light_tween.tween_property(point_light, "light_energy", 2.5, 0.8)
	
	# Configurar material da mesh
	if mesh_instance and is_instance_valid(mesh_instance):
		var material = StandardMaterial3D.new()
		material.albedo_color = health_color
		material.emission_enabled = true
		material.emission = health_color
		material.emission_energy = 2.5
		material.metallic = 0.3
		material.roughness = 0.1
		mesh_instance.material_override = material

# OTIMIZAÇÃO: Remove _process completamente
# func _process(_delta): # REMOVIDO - substituído por timer

func _on_body_entered(body):
	print("❤️ [HealthItem] Corpo detectado: ", body.name, " | Grupos: ", body.get_groups())
	if body.is_in_group("player"):
		can_interact = true
		print("❤️ [HealthItem] Player detectado! Interaction habilitada")
		if interaction_prompt and is_instance_valid(interaction_prompt):
			interaction_prompt.visible = true
			print("❤️ [HealthItem] Prompt mostrado")
	else:
		print("❤️ [HealthItem] Corpo não é player")

func _on_body_exited(body):
	print("❤️ [HealthItem] Corpo saiu: ", body.name, " | Grupos: ", body.get_groups())
	if body.is_in_group("player"):
		can_interact = false
		print("❤️ [HealthItem] Player saiu! Interaction desabilitada")
		if interaction_prompt and is_instance_valid(interaction_prompt):
			interaction_prompt.visible = false
			print("❤️ [HealthItem] Prompt escondido")
	else:
		print("❤️ [HealthItem] Corpo que saiu não é player")

func collect():
	if is_collected:
		print("❤️ [HealthItem] Item já foi coletado - ignorando")
		return
		
	print("❤️ [HealthItem] === INICIANDO COLETA ===")
	is_collected = true
	can_interact = false
	
	# OTIMIZAÇÃO: Para o timer quando coletado
	if input_check_timer:
		input_check_timer.stop()
	
	# Esconde o prompt
	if interaction_prompt and is_instance_valid(interaction_prompt):
		interaction_prompt.visible = false
		print("❤️ [HealthItem] Prompt escondido")
	
	# OTIMIZAÇÃO: Busca player de forma mais eficiente
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		var old_health = player.stats.hp
		player.heal(health_recovery)
		var new_health = player.stats.hp
		print("❤️❤️ [HealthItem] VIDA RECUPERADA! ❤️❤️")
		print("❤️ [HealthItem] Vida: ", old_health, " → ", new_health, " (+", health_recovery, " HP)")
	else:
		print("❌ [HealthItem] ERRO: Player não encontrado!")
	
	# Efeito visual de coleta
	print("❤️ [HealthItem] Executando efeito visual de coleta")
	_play_collection_effect()

func _play_collection_effect():
	# OTIMIZAÇÃO: Limpeza mais eficiente de tweens
	var tweens = get_tree().get_nodes_in_group("tween")
	for tween in tweens:
		if tween.get_parent() == self:
			tween.kill()
	
	# Efeito de crescimento e desaparecimento
	var collection_tween = create_tween()
	collection_tween.parallel().tween_property(self, "scale", Vector3(2.0, 2.0, 2.0), 0.4)
	collection_tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0), 0.6)
	
	# Efeito de luz intensa
	if point_light and is_instance_valid(point_light):
		collection_tween.parallel().tween_property(point_light, "light_energy", 10.0, 0.3)
		collection_tween.parallel().tween_property(point_light, "omni_range", 10.0, 0.3)
	
	# Remove o objeto após a animação
	collection_tween.tween_callback(queue_free) 