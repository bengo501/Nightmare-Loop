extends Camera3D

@export var target: Node3D  # O jogador
@export var offset: Vector3 = Vector3(3, 5, 3)  # 📏 Câmera mais próxima do jogador
@export var follow_speed: float = 4.0

func _process(delta):
	if target == null:
		return

	var desired_position = target.global_transform.origin + offset
	global_transform.origin = global_transform.origin.lerp(desired_position, delta * follow_speed)
	look_at(target.global_transform.origin, Vector3.UP)
