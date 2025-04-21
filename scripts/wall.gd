extends CSGBox3D

@export var fade_duration := 0.4

@onready var player = $"../../Player"
@onready var camera = $"../../ThirdPersonCamera"
var fade_amount: float = 0.0
var fade_target: float = 0.0

func _ready():
	# Torna o material único para cada parede
	if material and material is ShaderMaterial:
		material = material.duplicate()
		print("DEBUG: Material duplicado para esta parede.")


func _physics_process(delta):
	if not player or not camera:
		print("DEBUG: Player ou câmera não encontrados!")
		return

	var from = player.global_transform.origin
	var to = camera.global_transform.origin

	var space_state = get_world_3d().direct_space_state
	var ray_params := PhysicsRayQueryParameters3D.create(from, to)
	ray_params.exclude = [player]
	ray_params.collision_mask = 1  # Ajuste conforme necessário

	var result = space_state.intersect_ray(ray_params)

	if result:
		print("DEBUG: Ray colidiu com: ", result.collider.name)

		# Usa is_a_parent_of para garantir que qualquer parte da parede seja reconhecida
		if result:
			print("DEBUG: Ray colidiu com: ", result.collider.name)

			if self.is_ancestor_of(result.collider) or result.collider == self:
				print("DEBUG: Esta parede está entre o player e a câmera!")
				fade_target = 1.0
			else:
				fade_target = 0.0
		else:
			print("DEBUG: Ray não colidiu com nada.")
			fade_target = 0.0


	# Transição suave de fade
	fade_amount = lerp(fade_amount, fade_target, delta / fade_duration)
	print("DEBUG: fade_amount atual: ", fade_amount)

	# Atualiza o shader
	var mat := material as ShaderMaterial
	if mat:
		print("DEBUG: Material encontrado.")
		mat.set_shader_parameter("fade_amount", fade_amount)
		print("DEBUG: fade_amount enviado ao shader.")
	else:
		print("DEBUG: Material não é ShaderMaterial.")
