extends Area3D

@export var grief_stage: String = ""  # negação, raiva, barganha, depressão, aceitação
@export var item_description: String = ""
@export var bonus_points: int = 5  # Quantidade de pontos que este gift especial adiciona

@onready var mesh_instance = $MeshInstance3D
@onready var animation_player = $AnimationPlayer
@onready var collision_shape = $CollisionShape3D
@onready var interaction_prompt = $InteractionPrompt
# Se não encontrar InteractionPrompt, tenta encontrar o Label3D diretamente
@onready var interaction_label = $InteractionPrompt if has_node("InteractionPrompt") else null

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
	
	# Configura a cor do material baseado no estágio do luto (mais vibrante)
	if grief_stage in grief_colors:
		var material = StandardMaterial3D.new()
		material.albedo_color = grief_colors[grief_stage]
		material.emission_enabled = true
		material.emission = grief_colors[grief_stage] * 0.3  # Adiciona brilho
		mesh_instance.material_override = material
	
	# Esconde o prompt inicialmente
	var prompt_node = interaction_prompt if interaction_prompt else interaction_label
	if prompt_node and is_instance_valid(prompt_node):
		prompt_node.visible = false
	
	print("[SpecialGift] Gift especial criado: ", grief_stage, " (+", bonus_points, " pontos)")
	print("[SpecialGift] InteractionPrompt encontrado: ", prompt_node != null)
	print("[SpecialGift] Configurações - Monitoring: ", monitoring, " Monitorable: ", monitorable)
	print("[SpecialGift] Collision Layer: ", collision_layer, " Collision Mask: ", collision_mask)
	print("[SpecialGift] Posição: ", global_position)
	
	# Teste: procura por players na cena
	var players = get_tree().get_nodes_in_group("player")
	print("[SpecialGift] Players encontrados na cena: ", players.size())
	for i in range(players.size()):
		if i < players.size():
			var player = players[i]
			print("[SpecialGift] Player ", i, ": ", player.name, " Collision Layer: ", player.collision_layer)

func _process(delta):
	# Debug de distância do player (a cada 2 segundos)
	if fmod(Time.get_time_dict_from_system()["second"], 2) == 0 and fmod(Time.get_ticks_msec(), 1000) < 50:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var player = players[0]
			var distance = global_position.distance_to(player.global_position)
			if distance < 5.0:  # Só mostra se player estiver perto
				print("[SpecialGift] 📏 Distância do player: ", distance, " can_interact: ", can_interact, " grief: ", grief_stage)
	
	# Debug global de input E (sempre ativo)
	if Input.is_action_just_pressed("interact"):
		print("[SpecialGift] 🔑 TECLA E DETECTADA GLOBALMENTE! can_interact=", can_interact, " is_collected=", is_collected, " grief_stage=", grief_stage)
	
	# Verifica interação com a tecla E
	if can_interact and Input.is_action_just_pressed("interact") and not is_collected:
		print("[SpecialGift] ✅ Tecla E pressionada! Coletando gift especial: ", grief_stage)
		collect()
	
	# Debug adicional para verificar estado
	if can_interact and not is_collected:
		if Input.is_action_just_pressed("interact"):
			print("[SpecialGift] 🔑 Input E detectado mas gift pode estar coletado ou can_interact=false")
	
	# Rotação contínua (mais rápida)
	if mesh_instance and not is_collected:
		mesh_instance.rotate_y(rotation_speed * delta)
	
	# Adiciona um efeito de flutuação suave (mais pronunciado)
	if mesh_instance and not is_collected:
		mesh_instance.position.y = sin(Time.get_ticks_msec() * 0.002) * 0.3

func _on_body_entered(body):
	print("[SpecialGift] Corpo detectado: ", body.name, " Grupos: ", body.get_groups())
	if body.is_in_group("player"):
		can_interact = true
		var prompt_node = interaction_prompt if interaction_prompt else interaction_label
		if prompt_node and is_instance_valid(prompt_node):
			prompt_node.visible = true
		print("[SpecialGift] ✅ PLAYER DETECTADO! Gift especial: ", grief_stage)
		print("[SpecialGift] Prompt ativado: ", prompt_node != null)

func _on_body_exited(body):
	if body.is_in_group("player"):
		can_interact = false
		var prompt_node = interaction_prompt if interaction_prompt else interaction_label
		if prompt_node and is_instance_valid(prompt_node):
			prompt_node.visible = false
		print("[SpecialGift] Player saiu da área do gift: ", grief_stage)

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
