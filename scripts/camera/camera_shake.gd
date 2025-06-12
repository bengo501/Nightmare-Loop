extends Node3D

@export var shake_amount: float = 2.0
@export var shake_duration: float = 0.4
@export var shake_frequency: float = 20.0

var original_position: Vector3
var is_shaking: bool = false
var shake_timer: float = 0.0

func _ready():
	original_position = position
	print("CameraShake inicializado em: ", get_parent().name)

func _process(delta):
	if is_shaking:
		shake_timer -= delta
		if shake_timer <= 0:
			stop_shake()
		else:
			# Aplica o shake com intensidade baseada no dano
			var intensity = shake_timer / shake_duration
			# Adiciona um efeito de "punch" no início
			intensity = intensity * (1.0 + (1.0 - intensity) * 2.0)
			
			var current_shake = Vector3(
				randf_range(-shake_amount, shake_amount) * intensity,
				randf_range(-shake_amount, shake_amount) * intensity,
				randf_range(-shake_amount, shake_amount) * intensity
			)
			position = original_position + current_shake
			print("Aplicando shake: ", current_shake, " em ", get_parent().name)

func start_shake():
	print("Iniciando shake em: ", get_parent().name)
	is_shaking = true
	shake_timer = shake_duration
	original_position = position  # Atualiza a posição original

func stop_shake():
	print("Parando shake em: ", get_parent().name)
	is_shaking = false
	position = original_position 