extends Label3D

var velocity = Vector3.ZERO
var gravity = 2.0
var lifetime = 1.0
var fade_speed = 1.0

func _ready():
	# Mantém a cor vermelha
	modulate = Color(1, 0, 0, 1)

func _process(delta):
	# Aplica gravidade
	velocity.y -= gravity * delta
	
	# Move a label
	position += velocity * delta
	
	# Fade out
	modulate.a -= fade_speed * delta
	
	# Remove quando ficar invisível
	if modulate.a <= 0:
		queue_free()

func setup(damage: int, is_damage: bool = true):
	text = str(damage) if is_damage else "+" + str(damage)
	velocity = Vector3(randf_range(-1, 1), 2, 0)  # Movimento inicial para cima e um pouco aleatório 