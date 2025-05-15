extends Camera3D

@export var battle_position: Vector3 = Vector3(0, 10, 10)
@export var look_at_position: Vector3 = Vector3(0, 0, 0)

func _ready():
	# Configura a posição inicial da câmera
	global_transform.origin = battle_position
	look_at(look_at_position)

func transition_to_battle():
	# Ativa a câmera
	current = true
	
	# Aqui você pode adicionar efeitos de transição se desejar
	# Por exemplo, fade in/out, movimento suave, etc.