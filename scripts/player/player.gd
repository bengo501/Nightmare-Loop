extends CharacterBody3D

# === CONSTANTES DE MOVIMENTO ===
const SPEED = 3.0
const ROTATION_SPEED = 2.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003

# === VARIÁVEIS DE ATAQUE ===
@export var attack_damage: float = 10.0
@export var attack_range: float = 10.0
@export var attack_cooldown: float = 0.2

# === NÓS ===
@onready var third_person_camera = $ThirdPersonCamera
@onready var first_person_camera = $FirstPersonCamera
@onready var animation_player = $visuals/GamePucrsMC/AnimationPlayer
@onready var visuals = $visuals
@onready var weapon = $FirstPersonCamera/weapon
@onready var shoot_ray = $FirstPersonCamera/ShootRay
@onready var laser_line = $FirstPersonCamera/LaseLine
@onready var hud = $"../CanvasLayer/CanvasLayer2"
@onready var player = $"."
@onready var crosshair = $"../Crosshair"

# === ESTADOS ===
var walking = false
var first_person_mode = false
var laser_active = false
var can_attack: bool = true
var attack_timer: Timer
var current_target = null  # Alvo atual atingido pelo laser

# === INICIALIZAÇÃO ===
func _ready():
	activate_third_person()
	laser_line.visible = false
	setup_attack_system()
	setup_animations()

# Configura o timer de ataque e o raycast
func setup_attack_system():
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.connect("timeout", _on_attack_timer_timeout)
	add_child(attack_timer)

	shoot_ray.target_position = Vector3(0, 0, -attack_range)
	shoot_ray.collision_mask = 2  # Camada usada pelos inimigos
	shoot_ray.enabled = true
	print("DEBUG: Ray configurado com alcance de ", attack_range)

# Configura blend entre animações de movimento
func setup_animations():
	animation_player.set_blend_time("idle", "walk_front", 0.3)
	animation_player.set_blend_time("idle", "walk_back", 0.3)
	animation_player.set_blend_time("idle", "walk_left", 0.3)
	animation_player.set_blend_time("idle", "walk_right", 0.3)
	animation_player.set_blend_time("walk_front", "idle", 0.3)
	animation_player.set_blend_time("walk_back", "idle", 0.3)
	animation_player.set_blend_time("walk_left", "idle", 0.3)
	animation_player.set_blend_time("walk_right", "idle", 0.3)

# === LÓGICA DE FÍSICA (MOVIMENTO) ===
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if first_person_mode:
		move_first_person(delta)
	else:
		move_third_person(delta)

	if laser_active and first_person_mode:
		check_ray_collision()

	move_and_slide()

# Atualização visual do laser
func _process(_delta):
	if laser_active and first_person_mode:
		update_laser_color()

# === DETECÇÃO DE COLISÃO DO RAY ===
func check_ray_collision():
	shoot_ray.force_raycast_update()

	if shoot_ray.is_colliding():
		var collider = shoot_ray.get_collider()
		if collider and collider.is_in_group("enemy"):
			if collider != current_target:
				current_target = collider
				perform_attack(collider)  # inicia ataque assim que colidir com novo alvo
		else:
			current_target = null
	else:
		current_target = null

# Executa o ataque se permitido
func perform_attack(target = null):
	if not can_attack or target == null:
		return

	can_attack = false
	attack_timer.start()

	if target and target.has_method("take_damage"):
		print("DEBUG: Causando ", attack_damage, " de dano em ", target.name)
		target.take_damage(attack_damage)

# Callback quando o cooldown acaba
func _on_attack_timer_timeout():
	can_attack = true
	# Se ainda estiver mirando no inimigo, repetir o ataque
	if current_target and is_instance_valid(current_target):
		perform_attack(current_target)

# === CONTROLE DE ENTRADAS ===
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				activate_first_person()
			else:
				activate_third_person()

		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				laser_active = true
				laser_line.visible = true
				print("DEBUG: Laser ativado")
			else:
				laser_active = false
				laser_line.visible = false
				current_target = null
				print("DEBUG: Laser desativado")

	if first_person_mode and event is InputEventMouseMotion:
		rotate_camera(event.relative)

# === MOVIMENTO EM PRIMEIRA PESSOA ===
func move_first_person(delta: float):
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("foward"):
		input_dir -= first_person_camera.global_transform.basis.z
	if Input.is_action_pressed("backward"):
		input_dir += first_person_camera.global_transform.basis.z
	if Input.is_action_pressed("left"):
		input_dir -= first_person_camera.global_transform.basis.x
	if Input.is_action_pressed("right"):
		input_dir += first_person_camera.global_transform.basis.x

	input_dir.y = 0
	input_dir = input_dir.normalized()
	velocity.x = input_dir.x * SPEED
	velocity.z = input_dir.z * SPEED

# === MOVIMENTO EM TERCEIRA PESSOA ===
func move_third_person(delta: float):
	var rotate_direction = 0
	var move_direction = Vector3.ZERO

	if Input.is_action_pressed("left"):
		rotate_direction += 1
	if Input.is_action_pressed("right"):
		rotate_direction -= 1

	var moving_forward = Input.is_action_pressed("foward")
	var moving_backward = Input.is_action_pressed("backward")
	var moving_left = Input.is_action_pressed("left")
	var moving_right = Input.is_action_pressed("right")
	var moving = false

	if moving_forward:
		move_direction -= transform.basis.z
		play_animation("walk_front")
		moving = true
	elif moving_backward:
		move_direction += transform.basis.z
		play_animation("walk_back")
		moving = true
	elif moving_left:
		move_direction -= transform.basis.x
		play_animation("walk_left")
		moving = true
	elif moving_right:
		move_direction += transform.basis.x
		play_animation("walk_right")
		moving = true

	if not moving:
		play_animation("idle")

	move_direction = move_direction.normalized()
	rotation.y += rotate_direction * ROTATION_SPEED * delta
	velocity.x = move_direction.x * SPEED
	velocity.z = move_direction.z * SPEED

# === ANIMAÇÃO, CÂMERA E MODO ===
func play_animation(anim_name: String):
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

func rotate_camera(mouse_motion: Vector2):
	rotation.y -= mouse_motion.x * MOUSE_SENSITIVITY
	first_person_camera.rotation.x -= mouse_motion.y * MOUSE_SENSITIVITY
	first_person_camera.rotation.x = clamp(first_person_camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func activate_first_person():
	crosshair.visible = true
	player.visible = true
	hud.visible = true
	first_person_mode = true
	first_person_camera.current = true
	third_person_camera.current = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	weapon.visible = true

func activate_third_person():
	first_person_mode = false
	crosshair.visible = true
	player.visible = true
	hud.visible = true
	third_person_camera.current = true
	first_person_camera.current = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	weapon.visible = false

# Atualiza a cor do laser para combinar com o crosshair
func update_laser_color():
	if crosshair.material is ShaderMaterial:
		var cross_color = crosshair.material.get_shader_parameter("dot_color")

		if laser_line.material_override == null:
			var shader_material = ShaderMaterial.new()
			shader_material.shader = preload("res://shaders/laserRay.gdshader")
			laser_line.material_override = shader_material

		if laser_line.material_override is ShaderMaterial:
			laser_line.material_override.set_shader_parameter("core_color", cross_color)
