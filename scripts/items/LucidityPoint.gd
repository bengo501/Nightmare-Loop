extends Area3D

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var point_light: OmniLight3D = $OmniLight3D
@onready var interaction_prompt: Label3D = $InteractionPrompt/Label3D

var can_interact: bool = false
var is_collected: bool = false

# Cor específica dos pontos de lucidez (azul ciano brilhante)
var lucidity_color: Color = Color(0.2, 0.8, 1.0, 1.0)

func _ready():
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
		interaction_prompt.text = "Pressione E para coletar\nPonto de Lucidez"

func _setup_animations():
	# Animação de rotação
	var rotation_tween = create_tween()
	rotation_tween.set_loops()
	rotation_tween.tween_property(self, "rotation_degrees", Vector3(0, 360, 0), 3.0)
	
	# Animação de flutuação
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(self, "position", position + Vector3(0, 0.3, 0), 1.5)
	float_tween.tween_property(self, "position", position - Vector3(0, 0.3, 0), 1.5)

func _setup_visual():
	# Configurar cor da luz
	if point_light and is_instance_valid(point_light):
		point_light.light_color = lucidity_color
		point_light.light_energy = 2.5
		point_light.omni_range = 4.0
		
		# Efeito pulsante na luz
		var light_tween = create_tween()
		light_tween.set_loops()
		light_tween.tween_property(point_light, "light_energy", 3.5, 1.0)
		light_tween.tween_property(point_light, "light_energy", 2.0, 1.0)
	
	# Configurar material da mesh
	if mesh and is_instance_valid(mesh):
		var material = StandardMaterial3D.new()
		material.albedo_color = lucidity_color
		material.emission_enabled = true
		material.emission = lucidity_color
		material.emission_energy = 2.0
		material.metallic = 0.8
		material.roughness = 0.2
		mesh.material_override = material

func _process(_delta):
	if can_interact and Input.is_action_just_pressed("interact") and not is_collected:
		collect()

func _on_body_entered(body):
	if body.is_in_group("player"):
		can_interact = true
		if interaction_prompt and is_instance_valid(interaction_prompt):
			interaction_prompt.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		can_interact = false
		if interaction_prompt and is_instance_valid(interaction_prompt):
			interaction_prompt.visible = false

func collect():
	if is_collected:
		return
		
	is_collected = true
	can_interact = false
	
	# Esconde o prompt
	if interaction_prompt and is_instance_valid(interaction_prompt):
		interaction_prompt.visible = false
	
	# Adicionar ponto de lucidez ao LucidityManager
	var lucidity_manager = get_node("/root/LucidityManager")
	if lucidity_manager:
		lucidity_manager.add_lucidity_point(1)
		print("✨ Ponto de Lucidez coletado! +1 ponto adicionado")
	else:
		print("[LucidityPoint] ERRO: LucidityManager não encontrado!")
	
	# Efeito visual de coleta
	_play_collection_effect()

func _play_collection_effect():
	# Para todas as animações existentes
	var tweens = get_tree().get_nodes_in_group("tween")
	for tween in tweens:
		if tween.get_parent() == self:
			tween.kill()
	
	# Efeito de crescimento e desaparecimento
	var collection_tween = create_tween()
	collection_tween.parallel().tween_property(self, "scale", Vector3(1.5, 1.5, 1.5), 0.3)
	collection_tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	
	# Efeito de luz intensa
	if point_light and is_instance_valid(point_light):
		collection_tween.parallel().tween_property(point_light, "light_energy", 8.0, 0.2)
		collection_tween.parallel().tween_property(point_light, "omni_range", 8.0, 0.2)
	
	# Remove o objeto após a animação
	collection_tween.tween_callback(queue_free) 
