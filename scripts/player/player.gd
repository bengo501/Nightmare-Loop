extends CharacterBody3D

# === CONSTANTES DE MOVIMENTO ===
const SPEED = 3.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003
@export var rotation_speed: float = 6.0

# === VARIÁVEIS DE ATAQUE ===
@export var attack_damage: float = 10.0
@export var attack_range: float = 10.0
@export var attack_cooldown: float = 0.2

# === NÓS ===
@onready var third_person_camera = $"../ThirdPersonCamera"
@onready var first_person_camera = $FirstPersonCamera
@onready var animation_player = $visuals/GamePucrsMC/AnimationPlayer
@onready var visuals = $visuals
@onready var weapon = $FirstPersonCamera/weapon
@onready var shoot_ray = $FirstPersonCamera/ShootRay
@onready var laser_line = $FirstPersonCamera/LaseLine
@onready var hud = $"../CanvasLayer/CanvasLayer2"
@onready var player = $"."
@onready var crosshair = $"../Crosshair"
@onready var mouse_ray = $"../ThirdPersonCamera/MouseRay"

# === ESTADOS ===
var first_person_mode = false
var laser_active = false
var can_attack: bool = true
var attack_timer: Timer
var current_target = null



# === INICIALIZAÇÃO ===
func _ready():
	activate_third_person()
	laser_line.visible = false
	setup_attack_system()
	setup_animations()

func setup_attack_system():
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.connect("timeout", _on_attack_timer_timeout)
	add_child(attack_timer)

	shoot_ray.target_position = Vector3(0, 0, -attack_range)
	shoot_ray.collision_mask = 2
	shoot_ray.enabled = true

func setup_animations():
	var transitions = [
		["idle", "walk_front"], ["idle", "walk_back"],
		["idle", "walk_left"], ["idle", "walk_right"],
		["walk_front", "idle"], ["walk_back", "idle"],
		["walk_left", "idle"], ["walk_right", "idle"]
	]
	for pair in transitions:
		animation_player.set_blend_time(pair[0], pair[1], 0.3)

# === FÍSICA ===
func _physics_process(delta: float):
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if not first_person_mode:
		move_isometric(delta)
		rotate_toward_mouse(delta)
	else:
		move_first_person(delta)

	if laser_active and first_person_mode:
		check_ray_collision()

	move_and_slide()


func get_mouse_ground_position() -> Vector3:
	var mouse_pos = get_viewport().get_mouse_position()
	var from = third_person_camera.project_ray_origin(mouse_pos)
	var to = from + third_person_camera.project_ray_normal(mouse_pos) * 1000

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 << 7  # Layer 8
	query.exclude = [self]
	query.collide_with_areas = false

	var result = get_world_3d().direct_space_state.intersect_ray(query)

	if result:
		return result.position
	else:
		return global_transform.origin



# === ROTAÇÃO PARA O MOUSE ===
func rotate_toward_mouse(delta):
	var point = get_mouse_ground_position()
	var dir = point - global_transform.origin
	dir.y = 0

	if dir.length_squared() > 0.01:
		var angle = atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, angle, delta * rotation_speed)
		







# === MOVIMENTO ISOMÉTRICO ===
func move_isometric(delta: float):
	var input_vector = Vector3.ZERO

	if Input.is_action_pressed("foward"):
		input_vector.z -= 1
	if Input.is_action_pressed("backward"):
		input_vector.z += 1
	if Input.is_action_pressed("left"):
		input_vector.x -= 1
	if Input.is_action_pressed("right"):
		input_vector.x += 1

	if input_vector != Vector3.ZERO:
		input_vector = input_vector.normalized()
		var camera_basis = third_person_camera.global_transform.basis
		var direction = (camera_basis.x * input_vector.x) + (camera_basis.z * input_vector.z)
		direction.y = 0
		direction = direction.normalized()

		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		play_animation("walk_front")
	else:
		velocity.x = lerp(velocity.x, 0.0, 0.2)
		velocity.z = lerp(velocity.z, 0.0, 0.2)
		play_animation("idle")


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

# === ANIMAÇÕES ===
func play_animation(anim_name: String):
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

# === LASER E ATAQUE ===
func check_ray_collision():
	shoot_ray.force_raycast_update()
	if shoot_ray.is_colliding():
		var collider = shoot_ray.get_collider()
		if collider and collider.is_in_group("enemy"):
			if collider != current_target:
				current_target = collider
				perform_attack(collider)
		else:
			current_target = null
	else:
		current_target = null

func perform_attack(target = null):
	if not can_attack or target == null:
		return
	can_attack = false
	attack_timer.start()
	if target.has_method("take_damage"):
		print("DEBUG: Causando ", attack_damage, " de dano em ", target.name)
		target.take_damage(attack_damage)

func _on_attack_timer_timeout():
	can_attack = true
	if current_target and is_instance_valid(current_target):
		perform_attack(current_target)

# === ENTRADAS ===
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

func rotate_camera(mouse_motion: Vector2):
	rotation.y -= mouse_motion.x * MOUSE_SENSITIVITY
	first_person_camera.rotation.x -= mouse_motion.y * MOUSE_SENSITIVITY
	first_person_camera.rotation.x = clamp(first_person_camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

# === MODOS ===
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

# === LASER ===
func update_laser_color():
	if crosshair.material is ShaderMaterial:
		var cross_color = crosshair.material.get_shader_parameter("dot_color")
		if laser_line.material_override == null:
			var shader_material = ShaderMaterial.new()
			shader_material.shader = preload("res://shaders/laserRay.gdshader")
			laser_line.material_override = shader_material
		if laser_line.material_override is ShaderMaterial:
			laser_line.material_override.set_shader_parameter("core_color", cross_color)
