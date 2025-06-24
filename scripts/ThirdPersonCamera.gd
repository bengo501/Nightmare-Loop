extends Camera3D

@export var target: Node3D
@export var offset: Vector3 = Vector3(2, 3.5, 2)  # Reduzido de (3, 5, 3) para ficar mais próximo
@export var follow_speed: float = 5.0
@export var mouse_influence: float = 1.5

@onready var mouse_ray = $MouseRay
var debug_marker: MeshInstance3D = null

func _ready():
	if mouse_ray:
		# Configuração mais precisa do raycast
		mouse_ray.enabled = true
		mouse_ray.collision_mask = 1 << 7  # Layer 8 (chão)
		mouse_ray.target_position = Vector3(0, -100, 0)  # Raycast apontando para baixo
		mouse_ray.collide_with_areas = false  # Ignora áreas
		mouse_ray.collide_with_bodies = true  # Colide apenas com corpos físicos

	# Cria o marcador de debug
	debug_marker = MeshInstance3D.new()
	debug_marker.mesh = SphereMesh.new()
	debug_marker.mesh.radius = 0.15
	if debug_marker and is_instance_valid(debug_marker):
		debug_marker.visible = false
	add_child(debug_marker)

func _process(delta):
	if not target:
		return

	var target_position = target.global_transform.origin

	var viewport = get_viewport()
	var mouse_pos = viewport.get_mouse_position()
	var screen_size = viewport.get_visible_rect().size

	var mouse_offset = (mouse_pos / screen_size) * 2.0 - Vector2.ONE

	# Correção aqui:
	mouse_offset.x = clampf(mouse_offset.x, -1.0, 1.0)
	mouse_offset.y = clampf(mouse_offset.y, -1.0, 1.0)

	var lateral_offset = Vector3(mouse_offset.x, 0, mouse_offset.y) * mouse_influence

	var desired_position = target_position + offset + lateral_offset

	global_transform.origin = global_transform.origin.lerp(desired_position, delta * follow_speed)
	
	# MouseRay deve partir da posição da câmera para onde o mouse está na tela (sem sway)
	if mouse_ray:
		var from = project_ray_origin(mouse_pos)
		var to = from + project_ray_normal(mouse_pos) * 1000.0
		mouse_ray.global_transform.origin = from
		mouse_ray.target_position = to - from
		mouse_ray.force_raycast_update()

			# Debug visual: mostra uma esfera no ponto de colisão
	if mouse_ray.is_colliding():
		if debug_marker and is_instance_valid(debug_marker):
			debug_marker.global_transform.origin = mouse_ray.get_collision_point()
			debug_marker.visible = true
	else:
		if debug_marker and is_instance_valid(debug_marker):
			debug_marker.visible = false
