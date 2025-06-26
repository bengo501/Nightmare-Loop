extends Node3D
class_name FogOfWar

@export var fog_plane_size: Vector2 = Vector2(300, 300)
@export var fog_height: float = 8.0
@export var reveal_radius: float = 6.0
@export var fade_distance: float = 2.0
@export var fog_intensity: float = 0.9
@export var update_interval: float = 0.05

var player_ref: Node3D = null
var fog_plane: MeshInstance3D = null
var fog_material: ShaderMaterial = null
var update_timer: float = 0.0

func _ready():
	print("[FogOfWar] Inicializando sistema de fog of war leve...")
	_setup_fog_plane()
	_find_player()
	add_to_group("fog_of_war")

func _setup_fog_plane():
	"""Cria o plano de fog of war"""
	
	# Cria o MeshInstance3D
	fog_plane = MeshInstance3D.new()
	fog_plane.name = "FogOfWarPlane"
	add_child(fog_plane)
	
	# Cria a mesh do plano
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = fog_plane_size
	plane_mesh.subdivide_width = 32
	plane_mesh.subdivide_depth = 32
	fog_plane.mesh = plane_mesh
	
	# Posiciona o plano acima do mundo
	fog_plane.position.y = fog_height
	
	# Cria o material shader
	fog_material = ShaderMaterial.new()
	fog_material.shader = load("res://shaders/fog_of_war.gdshader")
	
	# Configura os parâmetros iniciais
	fog_material.set_shader_parameter("reveal_radius", reveal_radius)
	fog_material.set_shader_parameter("fade_distance", fade_distance)
	fog_material.set_shader_parameter("fog_intensity", fog_intensity)
	fog_material.set_shader_parameter("fog_color", Vector4(0.01, 0.05, 0.01, 0.95))
	fog_material.set_shader_parameter("noise_scale", 3.0)
	fog_material.set_shader_parameter("noise_speed", 0.3)
	
	# Aplica o material
	fog_plane.material_override = fog_material
	
	print("[FogOfWar] Plano de fog criado com sucesso!")

func _find_player():
	"""Encontra o jogador na cena"""
	
	# Procura pelo player em diferentes locais
	var possible_paths = [
		"../Player",
		"../../Player", 
		"/root/*/Player"
	]
	
	for path in possible_paths:
		player_ref = get_node_or_null(path)
		if player_ref:
			print("[FogOfWar] Player encontrado: ", player_ref.name)
			return
	
	# Tenta pelos grupos
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
		print("[FogOfWar] Player encontrado via grupo: ", player_ref.name)

func _process(delta):
	if not player_ref or not fog_material:
		return
	
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		_update_fog_position()

func _update_fog_position():
	"""Atualiza a posição do fog baseada na posição do jogador"""
	
	if not player_ref or not fog_material:
		return
	
	# Obtém a posição do jogador
	var player_pos = player_ref.global_position
	
	# Atualiza a posição do plano de fog para seguir o jogador
	fog_plane.global_position = Vector3(player_pos.x, fog_height, player_pos.z)
	
	# Atualiza a posição do jogador no shader
	fog_material.set_shader_parameter("player_position", player_pos)
	
	# Adiciona variação dinâmica no fog baseado no movimento
	var time = Time.get_time_dict_from_system()
	var dynamic_intensity = fog_intensity + sin(Time.get_time_dict_from_system().second * 0.1) * 0.05
	fog_material.set_shader_parameter("fog_intensity", dynamic_intensity)

# Funções para ajustar parâmetros em tempo real
func set_reveal_radius(radius: float):
	reveal_radius = radius
	if fog_material:
		fog_material.set_shader_parameter("reveal_radius", radius)

func set_fog_intensity(intensity: float):
	fog_intensity = intensity
	if fog_material:
		fog_material.set_shader_parameter("fog_intensity", intensity)

func set_fade_distance(distance: float):
	fade_distance = distance
	if fog_material:
		fog_material.set_shader_parameter("fade_distance", distance)

func toggle_fog_of_war(enabled: bool):
	"""Liga/desliga o fog of war"""
	if fog_plane:
		fog_plane.visible = enabled
		print("[FogOfWar] Fog of war ", "ativado" if enabled else "desativado")

# Debug
func _input(event):
	if event.is_action_pressed("ui_accept"):  # Tecla Enter para debug
		print("[FogOfWar] Debug - Player pos: ", player_ref.global_position if player_ref else "null")
		print("[FogOfWar] Debug - Fog plane pos: ", fog_plane.global_position if fog_plane else "null") 
