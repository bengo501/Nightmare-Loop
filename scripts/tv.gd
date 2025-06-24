extends Node3D

var player_inside = false
var player_ref: Node3D

@onready var pressE = $"../../CanvasLayer/CanvasLayer2/APERTE_E"
@onready var camera_tv = $Camera3D  # A câmera da TV que será ativada
@onready var hud = $"../../CanvasLayer/CanvasLayer2"
@onready var player = $"../../Player"
@onready var crosshair = $"../../Crosshair"

func _ready():
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player":
		player_inside = true
		player_ref = body
		if pressE and is_instance_valid(pressE):
			pressE.visible = true

func _on_body_exited(body):
	if body.name == "Player":
		player_inside = false
		player_ref = null
		if pressE and is_instance_valid(pressE):
			pressE.visible = false

func _input(event):
	if player_inside and event.is_action_pressed("interact"):
		# Ativa a câmera da TV
		if camera_tv:
			camera_tv.make_current()
		# Oculta a UI (opcional)
		if pressE and is_instance_valid(pressE):
			pressE.visible = false
		
		if hud and is_instance_valid(hud):
			hud.visible = false
		
		if player and is_instance_valid(player):
			player.visible = false
		
		if crosshair and is_instance_valid(crosshair):
			crosshair.visible = false
