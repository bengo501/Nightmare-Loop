extends Camera3D

@export var target: Node3D
@export var offset: Vector3 = Vector3(3, 5, 3)
@export var follow_speed: float = 5.0
@export var mouse_influence: float = 1.5

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
