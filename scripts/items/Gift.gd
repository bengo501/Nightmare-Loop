extends Area3D

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var point_light: OmniLight3D = $OmniLight3D
@onready var interaction_prompt: Label3D = $InteractionPrompt/Label3D

var can_interact: bool = false
var is_collected: bool = false
var gift_type: String = "negacao" # Pode ser: "negacao", "raiva", "barganha", "depressao", "aceitacao"

# Cores para cada tipo de gift
var gift_colors: Dictionary = {
    "negacao": Color(0.8, 0.2, 0.2, 1), # Vermelho
    "raiva": Color(1, 0.4, 0, 1), # Laranja
    "barganha": Color(0.8, 0.8, 0.2, 1), # Amarelo
    "depressao": Color(0.4, 0.2, 0.8, 1), # Roxo
    "aceitacao": Color(0.2, 0.8, 0.2, 1) # Verde
}

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
    
    animation_player.add_animation("rotate", animation)
    animation_player.play("rotate")
    
    # Conectar sinais
    body_entered.connect(_on_Gift_body_entered)
    body_exited.connect(_on_Gift_body_exited)
    
    # Configurar cor da luz baseada no tipo de gift
    if gift_type in gift_colors:
        point_light.light_color = gift_colors[gift_type]
        if mesh.material_override:
            mesh.material_override.albedo_color = gift_colors[gift_type]
            mesh.material_override.emission = gift_colors[gift_type]

func _process(_delta):
    if can_interact and Input.is_action_just_pressed("interact") and not is_collected:
        collect()

func _on_Gift_body_entered(body):
    if body.is_in_group("player"):
        can_interact = true
        interaction_prompt.visible = true

func _on_Gift_body_exited(body):
    if body.is_in_group("player"):
        can_interact = false
        interaction_prompt.visible = false

func collect():
    is_collected = true
    interaction_prompt.visible = false
    
    # Adicionar gift ao GiftManager
    var gift_manager = get_node("/root/GiftManager")
    if gift_manager:
        gift_manager.add_gift(gift_type)
    
    # Animar desaparecimento
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
    tween.tween_callback(queue_free) 