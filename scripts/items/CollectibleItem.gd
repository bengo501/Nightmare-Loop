extends Area3D

@export var grief_stage: String = ""  # negação, raiva, barganha, depressão, aceitação
@export var item_description: String = ""

@onready var mesh_instance = $MeshInstance3D
@onready var animation_player = $AnimationPlayer
@onready var collision_shape = $CollisionShape3D
@onready var interaction_prompt = $InteractionPrompt

var is_collected: bool = false
var can_interact: bool = false
var gift_manager: Node

# Cores para cada estágio do luto
var grief_colors = {
	"negacao": Color(0.8, 0.2, 0.2, 1),  # Vermelho escuro
	"raiva": Color(0.8, 0.4, 0, 1),      # Laranja
	"barganha": Color(0.8, 0.8, 0.2, 1), # Amarelo
	"depressao": Color(0.2, 0.2, 0.8, 1), # Azul
	"aceitacao": Color(0.2, 0.8, 0.2, 1)  # Verde
}

# OTIMIZAÇÃO: Controle de animações com timers
var rotation_speed = 2.0
var float_timer: Timer
var rotation_timer: Timer
var input_check_timer: Timer

# OTIMIZAÇÃO: Cache de valores para animação
var base_y_position: float
var float_amplitude: float = 0.2
var float_frequency: float = 2.0

func _ready():
	# Força configurações de área para garantir detecção
	monitoring = true
	monitorable = true
	collision_layer = 0
	collision_mask = 2
	
	# Obtém referência ao GiftManager singleton
	gift_manager = get_node("/root/GiftManager")
	
	# Conecta os sinais
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Configura a cor do material baseado no estágio do luto
	if grief_stage in grief_colors:
		var material = StandardMaterial3D.new()
		material.albedo_color = grief_colors[grief_stage]
		mesh_instance.material_override = material
	
	# Esconde o prompt inicialmente
	if interaction_prompt and is_instance_valid(interaction_prompt):
		interaction_prompt.visible = false
	
	# OTIMIZAÇÃO: Setup de timers para animações
	_setup_animation_timers()
	
	# OTIMIZAÇÃO: Cache da posição base
	if mesh_instance:
		base_y_position = mesh_instance.position.y
	
	# Debug detalhado
	print("🎁 [CollectibleItem] Item criado: ", grief_stage)
	print("🎁 [CollectibleItem] Collision Layer: ", collision_layer)
	print("🎁 [CollectibleItem] Collision Mask: ", collision_mask)
	print("🎁 [CollectibleItem] Monitoring: ", monitoring)
	print("🎁 [CollectibleItem] Monitorable: ", monitorable)
	print("🎁 [CollectibleItem] Posição: ", global_position)
	print("🎁 [CollectibleItem] GiftManager: ", gift_manager != null)

func _setup_animation_timers():
	"""OTIMIZAÇÃO: Configura timers para animações ao invés de _process"""
	
	# Timer para verificação de input (reduz de 60fps para 30fps)
	input_check_timer = Timer.new()
	input_check_timer.wait_time = 0.033  # ~30 FPS
	input_check_timer.autostart = true
	input_check_timer.timeout.connect(_check_input)
	add_child(input_check_timer)
	
	# Timer para rotação (reduz de 60fps para 20fps)
	rotation_timer = Timer.new()
	rotation_timer.wait_time = 0.05  # ~20 FPS
	rotation_timer.autostart = true
	rotation_timer.timeout.connect(_update_rotation)
	add_child(rotation_timer)
	
	# Timer para flutuação (reduz de 60fps para 15fps)
	float_timer = Timer.new()
	float_timer.wait_time = 0.066  # ~15 FPS
	float_timer.autostart = true
	float_timer.timeout.connect(_update_floating)
	add_child(float_timer)

func _check_input():
	"""OTIMIZAÇÃO: Verifica input apenas quando necessário"""
	if can_interact and Input.is_action_just_pressed("interact") and not is_collected:
		print("🎁 [CollectibleItem] ✅ Tecla E pressionada! Coletando ", grief_stage)
		collect()

func _update_rotation():
	"""OTIMIZAÇÃO: Atualiza rotação com menor frequência"""
	if mesh_instance and not is_collected:
		mesh_instance.rotate_y(rotation_speed * rotation_timer.wait_time)

func _update_floating():
	"""OTIMIZAÇÃO: Atualiza flutuação com menor frequência"""
	if mesh_instance and not is_collected:
		var time = Time.get_ticks_msec() * 0.001
		mesh_instance.position.y = base_y_position + sin(time * float_frequency) * float_amplitude

func _on_body_entered(body):
	print("🎁 [CollectibleItem] Corpo detectado: ", body.name, " Grupos: ", body.get_groups())
	print("🎁 [CollectibleItem] Collision Layer do corpo: ", body.collision_layer)
	if body.is_in_group("player"):
		can_interact = true
		if interaction_prompt and is_instance_valid(interaction_prompt):
			interaction_prompt.visible = true
		print("🎁 [CollectibleItem] ✅ PLAYER DETECTADO! Prompt ativado para: ", grief_stage)
		print("🎁 [CollectibleItem] Tecla para interagir: E")
	else:
		print("🎁 [CollectibleItem] ❌ Corpo não é player: ", body.name)

func _on_body_exited(body):
	print("🎁 [CollectibleItem] Corpo saiu: ", body.name)
	if body.is_in_group("player"):
		can_interact = false
		if interaction_prompt and is_instance_valid(interaction_prompt):
			interaction_prompt.visible = false
		print("🎁 [CollectibleItem] 👋 Player saiu da área do item: ", grief_stage)

func collect():
	if is_collected:
		return
		
	is_collected = true
	
	# OTIMIZAÇÃO: Para todos os timers quando coletado
	if input_check_timer:
		input_check_timer.stop()
	if rotation_timer:
		rotation_timer.stop()
	if float_timer:
		float_timer.stop()
	
	# Adiciona o item ao inventário usando o GiftManager
	if gift_manager:
		gift_manager.add_gift(grief_stage)
		print("Presente coletado: ", grief_stage)
	else:
		print("Erro: GiftManager não encontrado!")
	
	# Remove o item da cena
	queue_free()

# OTIMIZAÇÃO: Função para pausar/retomar animações
func set_animations_active(active: bool):
	if input_check_timer:
		input_check_timer.paused = not active
	if rotation_timer:
		rotation_timer.paused = not active
	if float_timer:
		float_timer.paused = not active
