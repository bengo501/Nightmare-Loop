extends CharacterBody3D

const SPEED = 3.0
const ROTATION_SPEED = 2.0  # Velocidade de rotação no modo tanque
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003  # Sensibilidade do mouse no modo primeira pessoa

@onready var third_person_camera = $ThirdPersonCamera
@onready var first_person_camera = $FirstPersonCamera
@onready var animation_player = $visuals/GamePucrsMC/AnimationPlayer
@onready var visuals = $visuals

@onready var weapon = $FirstPersonCamera/weapon
@onready var shoot_ray = $FirstPersonCamera/ShootRay
@onready var laser_line = $FirstPersonCamera/LaserLine


var walking = false
var first_person_mode = false  # Indica se o jogador está em primeira pessoa
var mouse_input_enabled = false  # Controle para capturar o mouse

func _ready():
	# Iniciar no modo de terceira pessoa
	activate_third_person()
	
	# Define os tempos de transição entre animações para suavidade
	animation_player.set_blend_time("idle", "walk_front", 0.3)
	animation_player.set_blend_time("idle", "walk_back", 0.3)
	animation_player.set_blend_time("idle", "walk_left", 0.3)
	animation_player.set_blend_time("idle", "walk_right", 0.3)
	animation_player.set_blend_time("walk_front", "idle", 0.3)
	animation_player.set_blend_time("walk_back", "idle", 0.3)
	animation_player.set_blend_time("walk_left", "idle", 0.3)
	animation_player.set_blend_time("walk_right", "idle", 0.3)

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
	""" Movimentação no modo primeira pessoa (controlada pelo mouse) """
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
	var move_direction = Vector3.ZERO

	# Rotação esquerda/direita
	if Input.is_action_pressed("left"):
		rotate_direction += 1
	if Input.is_action_pressed("right"):
		rotate_direction -= 1

	# Movimento para frente/trás/direita/esquerda
	var moving = false
	
	if Input.is_action_pressed("foward"):
		move_direction -= transform.basis.z
		play_animation("walk_front")
		moving = true
	if Input.is_action_pressed("backward"):
		move_direction += transform.basis.z
		play_animation("walk_back")
		moving = true
	if Input.is_action_pressed("left"):
		move_direction -= transform.basis.x
		play_animation("walk_left")
		moving = true
	if Input.is_action_pressed("right"):
		move_direction += transform.basis.x
		play_animation("walk_right")
		moving = true

	# Se nenhuma tecla foi pressionada, define a animação como "idle"
	if not moving:
		play_animation("idle")

	# Normaliza a direção
	move_direction = move_direction.normalized()

	# Aplica a rotação do personagem
	rotation.y += rotate_direction * ROTATION_SPEED * delta

	# Movimenta na direção correta
	velocity.x = move_direction.x * SPEED
	velocity.z = move_direction.z * SPEED

func play_animation(anim_name: String):
	""" Controla a troca de animação garantindo suavidade """
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

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
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		fire_laser()


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
	weapon.visible = true

func activate_third_person():
	""" Ativa a câmera de terceira pessoa e libera o cursor """
	first_person_mode = false
	third_person_camera.current = true
	first_person_camera.current = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # Libera o cursor
	weapon.visible = false
	
func change_laser_color(color: Color):
	if laser_line.material == null:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		laser_line.material = mat
	else:
		if laser_line.material is StandardMaterial3D:
			laser_line.material.albedo_color = color

func fire_laser():
	if not first_person_mode:
		return  # Só dispara em primeira pessoa

	shoot_ray.force_raycast_update()

	var from_pos = shoot_ray.global_transform.origin
	var hit_position = shoot_ray.get_collision_point()
	var to_pos = hit_position if shoot_ray.is_colliding() else from_pos + shoot_ray.global_transform.basis.z * shoot_ray.target_position.length()

	var direction = to_pos - from_pos
	var length = direction.length()
	var mid_point = from_pos + direction / 2.0

	# Atualiza posição e orientação do laser
	laser_line.global_transform.origin = mid_point
	laser_line.look_at(to_pos, Vector3.UP)
	laser_line.scale.y = length / 2.0  # Ajusta o comprimento do cilindro

	# Define a cor do laser (ex: vermelho)
	change_laser_color(Color(1, 0, 0))

	# Mostra o laser e esconde após um tempo
	laser_line.visible = true
	await get_tree().create_timer(0.1).timeout
	laser_line.visible = false
