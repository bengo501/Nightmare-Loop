extends Area3D

@export var grief_stage: String = ""  # negação, raiva, barganha, depressão, aceitação
@export var item_description: String = ""
@export var bonus_points: int = 5  # Quantidade de pontos que este gift especial adiciona

@onready var mesh_instance = $MeshInstance3D
@onready var animation_player = $AnimationPlayer
@onready var collision_shape = $CollisionShape3D
@onready var interaction_prompt = $InteractionPrompt

var is_collected: bool = false
var can_interact: bool = false
var gift_manager: Node

# Cores para cada estágio do luto (mais vibrantes para gifts especiais)
var grief_colors = {
	"negacao": Color(1.0, 0.3, 0.3, 1),  # Vermelho mais vibrante
	"raiva": Color(1.0, 0.5, 0.1, 1),    # Laranja mais vibrante
	"barganha": Color(1.0, 1.0, 0.3, 1), # Amarelo mais vibrante
	"depressao": Color(0.3, 0.3, 1.0, 1), # Azul mais vibrante
	"aceitacao": Color(0.3, 1.0, 0.3, 1)  # Verde mais vibrante
}

# Velocidade de rotação (mais rápida para gifts especiais)
var rotation_speed = 3.0

func _ready():
	# Obtém referência ao GiftManager singleton
	gift_manager = get_node("/root/GiftManager")
	
	# Conecta os sinais
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Configura a cor do material baseado no estágio do luto (mais vibrante)
	if grief_stage in grief_colors:
		var material = StandardMaterial3D.new()
		material.albedo_color = grief_colors[grief_stage]
		material.emission_enabled = true
		material.emission = grief_colors[grief_stage] * 0.3  # Adiciona brilho
		mesh_instance.material_override = material
	
	# Esconde o prompt inicialmente
	if interaction_prompt and is_instance_valid(interaction_prompt):
		interaction_prompt.visible = false
	
	print("[SpecialGift] Gift especial criado: ", grief_stage, " (+", bonus_points, " pontos)")

func _process(delta):
	# Verifica interação com a tecla E
	if can_interact and Input.is_action_just_pressed("interact") and not is_collected:
		collect()
	
	# Rotação contínua (mais rápida)
	if mesh_instance and not is_collected:
		mesh_instance.rotate_y(rotation_speed * delta)
	
	# Adiciona um efeito de flutuação suave (mais pronunciado)
	if mesh_instance and not is_collected:
		mesh_instance.position.y = sin(Time.get_ticks_msec() * 0.002) * 0.3

func _on_body_entered(body):
	if body.is_in_group("player"):
		can_interact = true
		if interaction_prompt and is_instance_valid(interaction_prompt):
			interaction_prompt.visible = true
		print("[SpecialGift] Player entrou na área do gift especial: ", grief_stage)

func _on_body_exited(body):
	if body.is_in_group("player"):
		can_interact = false
		if interaction_prompt and is_instance_valid(interaction_prompt):
			interaction_prompt.visible = false

func collect():
	if is_collected:
		return
		
	is_collected = true
	
	# Adiciona os pontos bonus ao inventário usando o GiftManager
	if gift_manager:
		gift_manager.add_gift(grief_stage, bonus_points)
		print("[SpecialGift] Presente especial coletado: ", grief_stage, " (+", bonus_points, " pontos)")
		print("[SpecialGift] Total de ", grief_stage, ": ", gift_manager.get_gift_count(grief_stage))
	else:
		print("[SpecialGift] ERRO: GiftManager não encontrado!")
	
	# Efeito visual de coleta (opcional)
	_play_collection_effect()
	
	# Remove o item da cena após um pequeno delay
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _play_collection_effect():
	"""
	Efeito visual quando o gift é coletado
	"""
	if mesh_instance:
		# Cria um tween para fazer o gift crescer e desaparecer
		var tween = create_tween()
		tween.parallel().tween_property(mesh_instance, "scale", Vector3(1.5, 1.5, 1.5), 0.3)
		tween.parallel().tween_property(mesh_instance, "modulate:a", 0.0, 0.5)
		
		# Rotação final rápida
		tween.parallel().tween_property(mesh_instance, "rotation_degrees:y", 720, 0.5) 
