extends Area3D

@export var grief_stage: String = ""  # negação, raiva, barganha, depressão, aceitação
@export var item_description: String = ""

@onready var mesh_instance = $MeshInstance3D
@onready var animation_player = $AnimationPlayer
@onready var collision_shape = $CollisionShape3D
@onready var interaction_prompt = $InteractionPrompt

var is_collected: bool = false
var can_interact: bool = false
var battle_data: Node

func _ready():
	# Obtém referência ao BattleData singleton
	battle_data = get_node("/root/BattleData")
	
	# Conecta os sinais
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Inicia a animação de flutuação
	if animation_player:
		animation_player.play("float")
	
	# Esconde o prompt inicialmente
	if interaction_prompt:
		interaction_prompt.visible = false

func _process(_delta):
	# Verifica interação com a tecla E
	if can_interact and Input.is_action_just_pressed("interact") and not is_collected:
		collect()
	
	# Adiciona um efeito de flutuação suave
	if mesh_instance and not is_collected:
		mesh_instance.position.y = sin(Time.get_ticks_msec() * 0.001) * 0.2

func _on_body_entered(body):
	if body.is_in_group("player"):
		can_interact = true
		if interaction_prompt:
			interaction_prompt.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		can_interact = false
		if interaction_prompt:
			interaction_prompt.visible = false

func collect():
	if is_collected:
		return
		
	is_collected = true
	
	# Toca a animação de coleta
	if animation_player:
		animation_player.play("collect")
		await animation_player.animation_finished
	
	# Adiciona o item ao inventário usando o BattleData
	if battle_data:
		battle_data.add_gift(grief_stage)
		print("Presente coletado: ", grief_stage)
	else:
		print("Erro: BattleData não encontrado!")
	
	# Atualiza a UI se necessário
	var ui_manager = get_node("/root/UiManager")
	if ui_manager:
		ui_manager.update_gift_ui()
	
	# Remove o item da cena
	queue_free()
