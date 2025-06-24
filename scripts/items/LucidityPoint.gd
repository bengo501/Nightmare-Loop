extends Area3D

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var point_light: OmniLight3D = $OmniLight3D
@onready var interaction_prompt: Label3D = $InteractionPrompt/Label3D

var can_interact: bool = false
var is_collected: bool = false

func _ready():
	# Configurar animação de rotação
	var animation_player = AnimationPlayer.new()
	add_child(animation_player)
	
	var animation = Animation.new()
	var track_idx = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx, ".:rotation")
	animation.track_insert_key(track_idx, 0.0, rotation)
	animation.track_insert_key(track_idx, 3.0, rotation + Vector3(0, TAU, 0))
	animation.loop_mode = Animation.LOOP_LINEAR
	
	animation_player.add_animation_library("", AnimationLibrary.new())
	animation_player.get_animation_library("").add_animation("rotate", animation)
	animation_player.play("rotate")
	
	# Conectar sinais
	body_entered.connect(_on_LucidityPoint_body_entered)
	body_exited.connect(_on_LucidityPoint_body_exited)
	
	# Esconde o prompt inicialmente
	if interaction_prompt and is_instance_valid(interaction_prompt):
		interaction_prompt.visible = false

func _process(_delta):
	if can_interact and Input.is_action_just_pressed("interact") and not is_collected:
		collect()

func _on_LucidityPoint_body_entered(body):
	if body.is_in_group("player"):
		can_interact = true
		if interaction_prompt and is_instance_valid(interaction_prompt):
			interaction_prompt.visible = true

func _on_LucidityPoint_body_exited(body):
	if body.is_in_group("player"):
		can_interact = false
		if interaction_prompt and is_instance_valid(interaction_prompt):
			interaction_prompt.visible = false

func collect():
	is_collected = true
	if interaction_prompt and is_instance_valid(interaction_prompt):
		interaction_prompt.visible = false
	
	# Adicionar ponto de lucidez ao LucidityManager
	var lucidity_manager = get_node("/root/LucidityManager")
	if lucidity_manager:
		lucidity_manager.add_lucidity_point()
	
	# Animar desaparecimento
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
	tween.tween_callback(queue_free) 
