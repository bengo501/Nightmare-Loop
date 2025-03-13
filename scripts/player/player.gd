extends CharacterBody3D

const SPEED = 3.0
const ROTATION_SPEED = 2.0  # Velocidade de rotação do personagem
const JUMP_VELOCITY = 4.5

@onready var third_person_camera = $ThirdPersonCamera
@onready var first_person_camera = $FirstPersonCamera
@onready var animation_player = $visuals/player/AnimationPlayer
@onready var visuals = $visuals
var walking = false

func _physics_process(delta: float) -> void:
	# Adiciona gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Pular
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Controles Tank (Resident Evil clássico)
	var rotate_direction = 0
	var move_direction = 0

	if Input.is_action_pressed("left"):  # Rotaciona para esquerda (A)
		rotate_direction += 1
	if Input.is_action_pressed("right"):  # Rotaciona para direita (D)
		rotate_direction -= 1
	if Input.is_action_pressed("foward"):  # Anda para frente (W)
		move_direction += 1
	if Input.is_action_pressed("backward"):  # Anda para trás (S)
		move_direction -= 1

	# Aplica a rotação do personagem
	rotation.y += rotate_direction * ROTATION_SPEED * delta

	# Movimenta na direção que está virado
	var direction = -transform.basis.z * move_direction  # -Z é a frente do personagem
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	
	# Controle de animação
	if move_direction != 0:
		if not walking:
			walking = true
			animation_player.play("walk")
	else:
		if walking:
			walking = false
			animation_player.play("idle")

	move_and_slide()

func _input(event):
	# Alterna entre câmeras com o botão direito do mouse
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				activate_first_person()
			else:
				activate_third_person()

func activate_first_person():
	first_person_camera.current = true  # Ativa a câmera de primeira pessoa

func activate_third_person():
	third_person_camera.current = true  # Volta para a câmera de terceira pessoa
