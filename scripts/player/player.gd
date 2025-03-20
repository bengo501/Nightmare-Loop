extends CharacterBody3D

const SPEED = 3.0
const ROTATION_SPEED = 2.0  # Velocidade de rotação do personagem no modo tanque
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003  # Sensibilidade do mouse para girar a câmera em primeira pessoa

@onready var third_person_camera = $ThirdPersonCamera
@onready var first_person_camera = $FirstPersonCamera
@onready var animation_player = $visuals/GamePucrsMC/AnimationPlayer
@onready var visuals = $visuals

var walking = false
var first_person_mode = false  # Indica se o jogador está em primeira pessoa
var mouse_input_enabled = false  # Controle para capturar o mouse

func _ready():
	# Iniciar no modo de terceira pessoa
	activate_third_person()
	
	animation_player.set_blend_time("idle","walk_front",0.2)
	animation_player.set_blend_time("walk_front","idle",0.2)

func _physics_process(delta: float) -> void:
	# Adiciona gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Pular
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Alternar entre os dois modos de movimentação
	if first_person_mode:
		move_first_person(delta)
	else:
		move_third_person(delta)

	move_and_slide()

func move_first_person(delta: float):
	""" Movimentação no modo primeira pessoa (livre, controlada pelo mouse) """
	var input_dir = Vector3.ZERO
	
	# Movimentação com W, A, S, D
	if Input.is_action_pressed("foward"):
		input_dir -= first_person_camera.global_transform.basis.z
	if Input.is_action_pressed("backward"):
		input_dir += first_person_camera.global_transform.basis.z
	if Input.is_action_pressed("left"):
		input_dir -= first_person_camera.global_transform.basis.x
	if Input.is_action_pressed("right"):
		input_dir += first_person_camera.global_transform.basis.x

	# Normaliza a direção para manter a velocidade constante em diagonais
	input_dir.y = 0
	input_dir = input_dir.normalized()

	velocity.x = input_dir.x * SPEED
	velocity.z = input_dir.z * SPEED

func move_third_person(delta: float):
	""" Movimentação estilo tanque no modo terceira pessoa """
	var rotate_direction = 0
	var move_direction = 0

	# Rotação esquerda/direita
	if Input.is_action_pressed("left"):
		rotate_direction += 1
	if Input.is_action_pressed("right"):
		rotate_direction -= 1

	# Movimento para frente/trás
	if Input.is_action_pressed("foward"):
		move_direction += 1
	if Input.is_action_pressed("backward"):
		move_direction -= 1

	# Aplica a rotação do personagem
	rotation.y += rotate_direction * ROTATION_SPEED * delta

	# Movimenta na direção que está virado
	var direction = -transform.basis.z * move_direction
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED

	# Controle de animação
	if move_direction != 0:
		if not walking:
			walking = true
			animation_player.play("walk_front")
	else:
		if walking:
			walking = false
			animation_player.play("idle")

func _input(event):
	# Alternar entre primeira e terceira pessoa com o botão direito do mouse
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			activate_first_person()
		else:
			activate_third_person()

	# Rotação da câmera no modo primeira pessoa
	if first_person_mode and event is InputEventMouseMotion:
		rotate_camera(event.relative)

func rotate_camera(mouse_motion: Vector2):
	""" Faz a câmera girar com o movimento do mouse no modo primeira pessoa """
	rotation.y -= mouse_motion.x * MOUSE_SENSITIVITY  # Rotação horizontal do personagem
	first_person_camera.rotation.x -= mouse_motion.y * MOUSE_SENSITIVITY  # Rotação vertical da câmera
	
	# Limita a rotação vertical para não ultrapassar 90° para cima/baixo
	first_person_camera.rotation.x = clamp(first_person_camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func activate_first_person():
	""" Ativa a câmera de primeira pessoa e captura o cursor """
	first_person_mode = true
	first_person_camera.current = true
	third_person_camera.current = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # Captura o mouse para rotação livre

func activate_third_person():
	""" Ativa a câmera de terceira pessoa e libera o cursor """
	first_person_mode = false
	third_person_camera.current = true
	first_person_camera.current = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # Libera o cursor
