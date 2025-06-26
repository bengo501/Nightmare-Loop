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

# Velocidade de rotação
var rotation_speed = 2.0

func _ready():
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
	
	# Debug detalhado
	print("🎁 [CollectibleItem] Item criado: ", grief_stage)
	print("🎁 [CollectibleItem] Collision Layer: ", collision_layer)
	print("🎁 [CollectibleItem] Collision Mask: ", collision_mask)
	print("🎁 [CollectibleItem] Monitoring: ", monitoring)
	print("🎁 [CollectibleItem] Posição: ", global_position)
	print("🎁 [CollectibleItem] GiftManager: ", gift_manager != null)

func _process(delta):
	# Verifica interação com a tecla E
	if can_interact and Input.is_action_just_pressed("interact") and not is_collected:
		collect()
	
	# Rotação contínua
	if mesh_instance and not is_collected:
		mesh_instance.rotate_y(rotation_speed * delta)
	
	# Adiciona um efeito de flutuação suave
	if mesh_instance and not is_collected:
		mesh_instance.position.y = sin(Time.get_ticks_msec() * 0.001) * 0.2

func _on_body_entered(body):
	print("🎁 [CollectibleItem] Corpo detectado: ", body.name, " Grupos: ", body.get_groups())
	if body.is_in_group("player"):
		can_interact = true
		if interaction_prompt and is_instance_valid(interaction_prompt):
			interaction_prompt.visible = true
		print("🎁 [CollectibleItem] ✅ PLAYER DETECTADO! Prompt ativado para: ", grief_stage)
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
	
	# Adiciona o item ao inventário usando o GiftManager
	if gift_manager:
		gift_manager.add_gift(grief_stage)
		print("Presente coletado: ", grief_stage)
	else:
		print("Erro: GiftManager não encontrado!")
	
	# Remove o item da cena
	queue_free()
