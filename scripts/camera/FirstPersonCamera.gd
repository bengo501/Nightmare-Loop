extends Camera3D

var shake_amount = 0.0
var shake_time = 0.0

func _ready():
	print("FirstPersonCamera: Inicializado")

func _process(delta):
	if shake_time > 0:
		shake_time -= delta
		
		# Aplica o shake com intensidade reduzida
		rotation.x += randf_range(-shake_amount, shake_amount) * 0.5
		rotation.y += randf_range(-shake_amount, shake_amount) * 0.5
		
		# Reduz a intensidade do shake mais suavemente
		shake_amount = lerp(shake_amount, 0.0, delta * 3.0)
		
		# Reseta a rotação quando o shake termina
		if shake_time <= 0:
			rotation.x = 0
			rotation.y = 0

# Função para iniciar o shake
func shake():
	shake_amount = 0.1  # Intensidade reduzida
	shake_time = 0.15   # Duração um pouco menor
