extends Camera3D

var shake_amount = 0.0
var shake_time = 0.0

# Referência para a arma
@onready var weapon = $CanvasLayer/weapon

# Variáveis para a animação da arma
var weapon_draw_time = 0.0
var weapon_draw_duration = 0.5
var weapon_draw_start_pos = Vector2(576, 748)  # Posição inicial (fora da tela)
var weapon_draw_end_pos = Vector2(576, 648)    # Posição final (posição normal)
var is_drawing_weapon = false

# Variável para controlar se a câmera está ativa
var is_active = false

func _ready():
	print("FirstPersonCamera: Inicializado")
	if weapon:
		print("Weapon found: ", weapon.name)
		weapon.position = weapon_draw_start_pos
		weapon.visible = false  # Começa invisível
	else:
		print("Weapon not found!")

func _process(delta):
	# Verifica se a câmera está ativa
	if current != is_active:
		is_active = current
		if is_active:
			show_weapon()  # Mostra a arma quando a câmera é ativada
		else:
			hide_weapon()  # Esconde a arma quando a câmera é desativada
	
	# Processa o shake da câmera
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
	
	# Processa a animação de empunhar a arma
	if is_drawing_weapon and weapon:
		weapon_draw_time += delta
		var progress = min(weapon_draw_time / weapon_draw_duration, 1.0)
		
		# Usa uma curva de easing para suavizar a animação
		progress = ease(progress, 0.5)  # Curva de easing quadrática
		
		# Interpola a posição da arma
		weapon.position = weapon_draw_start_pos.lerp(weapon_draw_end_pos, progress)
		
		# Adiciona um leve efeito de rotação
		weapon.rotation = lerp(-0.2, 0.0, progress)
		
		print("Weapon animation - Position: ", weapon.position, " Progress: ", progress)
		
		# Verifica se a animação terminou
		if progress >= 1.0:
			is_drawing_weapon = false
			print("Weapon animation completed")

# Função para iniciar o shake
func shake():
	shake_amount = 0.1  # Intensidade reduzida
	shake_time = 0.15   # Duração um pouco menor

# Função para mostrar a arma e iniciar a animação
func show_weapon():
	if weapon:
		print("Showing weapon...")
		weapon.visible = true
		weapon.position = weapon_draw_start_pos
		is_drawing_weapon = true
		weapon_draw_time = 0.0
		print("Weapon animation started")

# Função para esconder a arma
func hide_weapon():
	if weapon:
		print("Hiding weapon...")
		weapon.visible = false
		is_drawing_weapon = false
		print("Weapon hidden")
