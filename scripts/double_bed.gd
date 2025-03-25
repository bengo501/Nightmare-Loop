extends Node3D

@export var teleport_position: NodePath  # Caminho até um Marker3D
@onready var pressE = $"../../CanvasLayer/CanvasLayer2/APERTE_E"
@onready var wave = $"../../Wave"
@onready var hud = $"../../CanvasLayer/CanvasLayer2"

var player_inside = false
var player_ref: Node3D
var fading = false

func _ready():
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player":
		player_inside = true
		player_ref = body
		if pressE:
			pressE.visible = true

func _on_body_exited(body):
	if body.name == "Player":
		player_inside = false
		player_ref = null
		if pressE:
			pressE.visible = false

func _input(event):
	if player_inside and event.is_action_pressed("interact") and player_ref and teleport_position != null:
		if pressE:
			pressE.visible = false

		if not fading and wave and wave.material is ShaderMaterial:
			fading = true
			fade_overlay_alpha()

func fade_overlay_alpha():
	var mat := wave.material as ShaderMaterial
	var fade_duration := 1.5
	var step := 0.05
	var alpha := 0.0

	# Oculta o HUD no início do efeito
	if hud:
		hud.visible = false

	# FADE IN
	while alpha < 1.0:
		alpha = clamp(alpha + step, 0.0, 1.0)

		var color: Color = mat.get_shader_parameter("overlay_color")
		color.a = alpha
		mat.set_shader_parameter("overlay_color", color)

		await get_tree().create_timer(fade_duration * step).timeout

	await get_tree().create_timer(2.0).timeout

	# TELETRANSPORTE
	if teleport_position != null and player_ref:
		var target_node = get_node(teleport_position)
		player_ref.global_position = target_node.global_position

	await get_tree().create_timer(0.5).timeout

	# FADE OUT
	while alpha > 0.0:
		alpha = clamp(alpha - step, 0.0, 1.0)

		var color: Color = mat.get_shader_parameter("overlay_color")
		color.a = alpha
		mat.set_shader_parameter("overlay_color", color)

		await get_tree().create_timer(fade_duration * step).timeout

	# Exibe novamente o HUD ao final do efeito
	if hud:
		hud.visible = true

	fading = false
