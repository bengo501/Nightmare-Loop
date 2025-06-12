extends SubViewport

@onready var camera = $MinimapCamera
@onready var player = get_node("/root/GameManager/Player")

# Configurações do minimapa
var camera_height = 15.0  # Reduzido para uma visão mais próxima
var camera_rotation = -PI/2  # -90 graus para visão de cima
var camera_fov = 30.0  # Reduzido para uma visão mais detalhada
var update_interval = 0.05  # Atualização mais frequente
var time_since_last_update = 0.0

func _ready():
	# Configura a câmera
	camera.fov = camera_fov
	camera.rotation.x = camera_rotation
	camera.position.y = camera_height
	
	# Aplica o material do minimapa
	var material = load("res://materials/minimap_material.tres")
	$MinimapCamera/WorldEnvironment.environment.background_mode = Environment.BG_COLOR
	$MinimapCamera/WorldEnvironment.environment.background_color = Color(0.2, 0.2, 0.2, 1.0)
	
	# Configura o viewport
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	
	# Garante que o viewport mantenha a proporção quadrada
	size = Vector2i(150, 150)

func _process(delta):
	time_since_last_update += delta
	
	if time_since_last_update >= update_interval and player:
		# Atualiza a posição da câmera para seguir o jogador
		var player_pos = player.global_position
		camera.global_position = Vector3(player_pos.x, camera_height, player_pos.z)
		
		# Mantém a rotação da câmera alinhada com a direção do jogador
		var player_rotation = player.global_rotation.y
		camera.global_rotation.y = player_rotation
		
		time_since_last_update = 0.0 