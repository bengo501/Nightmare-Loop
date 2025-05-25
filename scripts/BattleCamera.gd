extends Camera3D

@export var battle_position: Vector3 = Vector3(0, 10, 10)
@export var look_at_position: Vector3 = Vector3(0, 0, 0)

# Variável para armazenar a posição inicial
var initial_transform: Transform3D

func _ready():
	# Armazena a transformação inicial da câmera
	initial_transform = global_transform
	
	# Garante que esta câmera seja a atual
	current = true
	
	# Desativa o processamento de input do mouse
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(_delta):
	# Mantém a câmera na posição inicial
	global_transform = initial_transform

func _input(event):
	# Bloqueia eventos de input do mouse durante a batalha
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()

func transition_to_battle():
	# Ativa a câmera
	current = true
	
	# Desativa o processamento de input do mouse
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
