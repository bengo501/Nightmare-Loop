extends CharacterBody3D

const SPEED = 3.0
const ROTATION_SPEED = 2.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003

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

var walking = false
var first_person_mode = false
var laser_active = false  # ← controle se o laser está ligado

func _ready():
	activate_third_person()
	laser_line.visible = false  # Começa invisível

	# Blend de animações
	animation_player.set_blend_time("idle", "walk_front", 0.3)
	animation_player.set_blend_time("idle", "walk_back", 0.3)
	animation_player.set_blend_time("idle", "walk_left", 0.3)
	animation_player.set_blend_time("idle", "walk_right", 0.3)
	animation_player.set_blend_time("walk_front", "idle", 0.3)
	animation_player.set_blend_time("walk_back", "idle", 0.3)
	animation_player.set_blend_time("walk_left", "idle", 0.3)
	animation_player.set_blend_time("walk_right", "idle", 0.3)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if first_person_mode:
		move_first_person(delta)
	else:
		move_third_person(delta)

	move_and_slide()

func _process(delta):
	if laser_active and first_person_mode:
		update_laser_color()

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

func play_animation(anim_name: String):
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				activate_first_person()
			else:
				activate_third_person()

		# Liga/desliga o laser contínuo
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				laser_active = true
				laser_line.visible = true
			else:
				laser_active = false
				laser_line.visible = false

	if first_person_mode and event is InputEventMouseMotion:
		rotate_camera(event.relative)

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

func update_laser_color():
	if crosshair.material is ShaderMaterial:
		var cross_color = crosshair.material.get_shader_parameter("dot_color")

		if laser_line.material_override == null:
			# Cria um novo ShaderMaterial se ainda não existir
			var shader_material = ShaderMaterial.new()
			shader_material.shader = preload("res://shaders/laserRay.gdshader")  # ← ajuste aqui!
			laser_line.material_override = shader_material

		if laser_line.material_override is ShaderMaterial:
			laser_line.material_override.set_shader_parameter("core_color", cross_color)
