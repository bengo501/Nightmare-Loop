extends Node3D

@onready var camera = $ThirdPersonCamera

func _ready():
	# Configurar a câmera em terceira pessoa
	if camera:
		# Definir a câmera como atual
		camera.make_current()
		
		# Configurar parâmetros da câmera (ajuste estes valores conforme necessário)
		camera.position = Vector3(0, 2, 4)  # Posição inicial da câmera
		camera.rotation_degrees = Vector3(-15, 0, 0)  # Rotação inicial da câmera
		
		# Configurar o target (alvo) da câmera como o jogador
		if get_parent() and get_parent().has_node("Player"):
			var player = get_parent().get_node("Player")
			camera.target = player
			
		# Configurar outros parâmetros da câmera
		camera.mouse_sensitivity = 0.1
		camera.zoom_speed = 0.1
		camera.min_distance = 2.0
		camera.max_distance = 5.0 
