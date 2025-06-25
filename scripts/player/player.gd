extends CharacterBody3D

# === CONSTANTES DE MOVIMENTO ===
const SPEED = 3.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003
@export var rotation_speed: float = 35.0

# === VARIÁVEIS DE ATAQUE ===
@export var attack_damage: float = 10.0
@export var attack_range: float = 10.0
@export var attack_cooldown: float = 0.2
@export var max_health: float = 100.0
var current_health: float
var defense_bonus: float = 1.0

# === NÓS (referências adaptadas) ===
@onready var third_person_camera = $ThirdPersonCamera
@onready var first_person_camera = $FirstPersonCamera
@onready var animation_player = $visuals/GamePucrsMC/AnimationPlayer
@onready var visuals = $visuals
@onready var weapon = $FirstPersonCamera/weapon
@onready var shoot_ray = $FirstPersonCamera/ShootRay
@onready var laser_line = $FirstPersonCamera/LaseLine
@onready var crosshair = $Crosshair
@onready var mouse_ray = $ThirdPersonCamera/MouseRay
# Ajuste o caminho do HUD para usar o UIManager:
@onready var hud = null  # Será inicializado no _ready()
@onready var damage_indicator_scene = preload("res://scenes/ui/damage_indicator.tscn")
@onready var camera_shake_script = preload("res://scripts/camera/camera_shake.gd")

# === ESTADOS ===
var first_person_mode = false
var laser_active = false
var can_attack: bool = true
var attack_timer: Timer
var current_target = null
var can_move = true

@export var camera_distance: float = -3.0  # Reduzido de -4.0 para ficar mais próximo
@export var camera_height: float = 5.0  # Reduzido de 7.0 para ficar mais próximo
@export var camera_angle_deg: float = 45.0
@export var camera_smooth: float = 8.0
@export var sway_max_offset: float = 1.5
@export var sway_speed: float = 5.0
var sway_offset: Vector3 = Vector3.ZERO

# Variáveis de movimento
@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var gravity: float = 9.8

# Multiplicadores de status
var speed_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var health_multiplier: float = 1.0

# Referências
@onready var camera_mount = $CameraMount
@onready var camera = $CameraMount/Camera3D
@onready var ray_cast = $CameraMount/RayCast3D



signal game_over

# Sinais para comunicação com outros sistemas
signal player_health_changed(new_health, max_health)  # Emitido quando o HP muda
signal player_mp_changed(new_mp, max_mp)             # Emitido quando o MP muda
signal player_xp_changed(new_xp)                      # Emitido quando o XP muda
signal player_consciencia_changed(new_value)          # Emitido quando a consciência muda
signal player_stats_changed(stats)                    # Emitido quando qualquer estatística muda
signal player_died                                    # Emitido quando o jogador é derrotado
signal health_changed(new_health: float)

# Estatísticas base do jogador
var stats = {
	"hp": 100,          # Pontos de vida atuais
	"max_hp": 100,      # Pontos de vida máximos
	"mp": 50,           # Pontos de magia atuais
	"max_mp": 50,       # Pontos de magia máximos
	"xp": 0,            # Pontos de experiência
	"consciencia": 100, # Nível de consciência (afeta interações com fantasmas)
	"defesa": 10,       # Reduz o dano recebido
	"ataque": 15,       # Aumenta o dano causado
	"velocidade": 10    # Afeta a velocidade de movimento e ordem dos turnos
}

# Modificadores temporários de status
var status_effects = {
	"defesa_reduzida": 0,  # Quantidade de defesa reduzida
	"ataque_reduzido": 0,  # Quantidade de ataque reduzido
	"velocidade_reduzida": 0, # Quantidade de velocidade reduzida
	"gift_boost": 0        # Multiplicador de eficácia dos gifts
}

func _ready():
	add_to_group("player")
	current_health = max_health
	emit_signal("health_changed", current_health)
	
	# Garante que o player pode se mover
	can_move = true
	
	# Inicializa a referência da HUD
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager and ui_manager.has_method("get") and ui_manager.get("hud_instance"):
		hud = ui_manager.hud_instance
	
	# Conecta ao SkillManager
	var skill_manager = get_node_or_null("/root/SkillManager")
	if skill_manager:
		skill_manager.skill_upgraded.connect(_on_skill_upgraded)



	# Tenta encontrar os nós, se existirem
	if has_node("../ThirdPersonCamera"):
		third_person_camera = get_node("../ThirdPersonCamera")
		# Adiciona o script de shake à câmera de terceira pessoa
		if not third_person_camera.has_node("CameraShake"):
			var camera_shake = Node3D.new()
			camera_shake.set_script(camera_shake_script)
			camera_shake.name = "CameraShake"
			third_person_camera.add_child(camera_shake)
			print("Adicionado CameraShake à câmera de terceira pessoa")
	
	if has_node("FirstPersonCamera"):
		first_person_camera = get_node("FirstPersonCamera")
		# Adiciona o script de shake à câmera de primeira pessoa
		if not first_person_camera.has_node("CameraShake"):
			var camera_shake = Node3D.new()
			camera_shake.set_script(camera_shake_script)
			camera_shake.name = "CameraShake"
			first_person_camera.add_child(camera_shake)
			print("Adicionado CameraShake à câmera de primeira pessoa")
		
		# Arma 2D como TextureRect dentro da câmera de primeira pessoa
		if first_person_camera.has_node("weapon"):
			weapon = first_person_camera.get_node("weapon")
		if first_person_camera.has_node("ShootRay"):
			shoot_ray = first_person_camera.get_node("ShootRay")
		if first_person_camera.has_node("LaseLine"):
			laser_line = first_person_camera.get_node("LaseLine")
	if has_node("visuals"):
		visuals = get_node("visuals")
		if visuals.has_node("GamePucrsMC/AnimationPlayer"):
			animation_player = visuals.get_node("GamePucrsMC/AnimationPlayer")
	# MouseRay pode estar na câmera de terceira pessoa
	if third_person_camera and third_person_camera.has_node("MouseRay"):
		mouse_ray = third_person_camera.get_node("MouseRay")

	# Inicialização de sistemas
	if third_person_camera:
		activate_third_person()
	if laser_line and is_instance_valid(laser_line):
		laser_line.visible = false
	setup_attack_system()
	setup_animations()

	# Configurações iniciais
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if hud:
		connect("player_health_changed", Callable(hud, "set_health"))

func setup_attack_system():
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.connect("timeout", _on_attack_timer_timeout)
	add_child(attack_timer)

	if shoot_ray:
		shoot_ray.target_position = Vector3(0, 0, -attack_range)
		shoot_ray.collision_mask = 2
		shoot_ray.enabled = true

func setup_animations():
	if animation_player == null:
		return
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
	if not can_move:
		return
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

# === ROTAÇÃO PARA O MOUSE ===
func rotate_toward_mouse(delta):
	if not third_person_camera or not mouse_ray:
		return
	mouse_ray.force_raycast_update()
	if mouse_ray.is_colliding():
		var hit_point = mouse_ray.get_collision_point()
		var player_pos = global_transform.origin
		var dir = hit_point - player_pos
		dir.y = 0
		if dir.length_squared() > 0.01:
			var target_angle = atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, target_angle, delta * rotation_speed)
			if visuals:
				visuals.rotation.y = rotation.y

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
		velocity.x = direction.x * SPEED * speed_multiplier
		velocity.z = direction.z * SPEED * speed_multiplier
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
	velocity.x = input_dir.x * SPEED * speed_multiplier
	velocity.z = input_dir.z * SPEED * speed_multiplier

# === ANIMAÇÕES ===
func play_animation(anim_name: String):
	if animation_player and animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

# === LASER E ATAQUE ===
func check_ray_collision():
	if not shoot_ray:
		return
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

# === ENTRADAS E TIRO EM PRIMEIRA PESSOA ===
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				activate_first_person()
			else:
				activate_third_person()
		if event.button_index == MOUSE_BUTTON_LEFT and first_person_mode:
			if event.pressed:
				laser_active = true
				if laser_line and is_instance_valid(laser_line):
					laser_line.visible = true
				shoot_first_person()
			else:
				laser_active = false
				if laser_line and is_instance_valid(laser_line):
					laser_line.visible = false
				current_target = null
	if first_person_mode and event is InputEventMouseMotion:
		rotate_camera(event.relative)
	# Ativação do laser/ataque com a tecla F
	if first_person_mode and event is InputEventKey:
		if event.keycode == KEY_F:
			if event.pressed and not event.echo:
				laser_active = true
				if laser_line and is_instance_valid(laser_line):
					laser_line.visible = true
				shoot_first_person()
			elif not event.pressed:
				laser_active = false
				if laser_line and is_instance_valid(laser_line):
					laser_line.visible = false
				current_target = null

func shoot_first_person():
	if not shoot_ray:
		return
	shoot_ray.force_raycast_update()
	if shoot_ray.is_colliding():
		var collider = shoot_ray.get_collider()
		if collider and collider.is_in_group("enemy"):
			if collider.has_method("take_damage"):
				collider.take_damage(attack_damage)
				print("DEBUG: Acertou inimigo em primeira pessoa!")

func rotate_camera(mouse_motion: Vector2):
	if not first_person_camera:
		return
	rotation.y -= mouse_motion.x * MOUSE_SENSITIVITY
	# Bloqueia rotação vertical no modo primeira pessoa
	if first_person_mode:
		first_person_camera.rotation.x = 0
	else:
		first_person_camera.rotation.x -= mouse_motion.y * MOUSE_SENSITIVITY
		first_person_camera.rotation.x = clamp(first_person_camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

# === MODOS ===
func activate_first_person():
	first_person_mode = true
	if visuals:
		visuals.visible = false
	if crosshair and is_instance_valid(crosshair):
		crosshair.visible = true
	if hud and is_instance_valid(hud):
		hud.visible = true
		# Alterna crosshair para modo centralizado
		if hud.has_method("set_crosshair_mode"):
			hud.set_crosshair_mode(true)
	if first_person_camera:
		first_person_camera.current = true
	if third_person_camera:
		third_person_camera.current = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Centraliza o cursor na tela
	var viewport = get_viewport()
	var screen_center = viewport.get_visible_rect().size / 2
	viewport.warp_mouse(screen_center)
	
	if weapon and is_instance_valid(weapon):
		weapon.visible = true

func activate_third_person():
	first_person_mode = false
	if visuals:
		visuals.visible = true
	if crosshair and is_instance_valid(crosshair):
		crosshair.visible = false
	if hud and is_instance_valid(hud):
		hud.visible = true
		# Alterna crosshair para seguir o mouse
		if hud.has_method("set_crosshair_mode"):
			hud.set_crosshair_mode(false)
	if third_person_camera:
		third_person_camera.current = true
	if first_person_camera:
		first_person_camera.current = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if weapon and is_instance_valid(weapon):
		weapon.visible = false

# === LASER ===
func update_laser_color():
	if crosshair and crosshair.material is ShaderMaterial:
		var cross_color = crosshair.material.get_shader_parameter("dot_color")
		if laser_line and laser_line.material_override == null:
			var shader_material = ShaderMaterial.new()
			shader_material.shader = preload("res://shaders/laserRay.gdshader")
			laser_line.material_override = shader_material
		if laser_line and laser_line.material_override is ShaderMaterial:
			laser_line.material_override.set_shader_parameter("core_color", cross_color)



func die() -> void:
	print("DEBUG: Jogador morreu!")
	emit_signal("game_over")
	queue_free()

# Função para receber dano
func take_damage(amount: float):
	var actual_damage = amount * (1.0 - (stats.defesa / 100.0))
	stats.hp = max(0, stats.hp - actual_damage)
	emit_signal("health_changed", stats.hp)
	emit_signal("player_health_changed", stats.hp, stats.max_hp)
	
	# Mostra o indicador de dano
	var damage_indicator = damage_indicator_scene.instantiate()
	add_child(damage_indicator)
	damage_indicator.set_damage(int(actual_damage))
	
	# Aplica o efeito de shake nas câmeras
	print("Tentando aplicar shake nas câmeras...")
	
	# Shake na câmera de terceira pessoa
	if third_person_camera:
		var third_person_shake = third_person_camera.get_node_or_null("CameraShake")
		if third_person_shake:
			print("Aplicando shake na câmera de terceira pessoa")
			third_person_shake.start_shake()
		else:
			print("CameraShake não encontrado na câmera de terceira pessoa")
	
	# Shake na câmera de primeira pessoa
	if first_person_camera:
		var first_person_shake = first_person_camera.get_node_or_null("CameraShake")
		if first_person_shake:
			print("Aplicando shake na câmera de primeira pessoa")
			first_person_shake.start_shake()
		else:
			print("CameraShake não encontrado na câmera de primeira pessoa")
	
	if stats.hp <= 0:
		emit_signal("player_died")
		game_over.emit()

func _process(delta):
	if not first_person_mode and third_person_camera:
		update_camera_sway(delta)
		update_third_person_look()
		if hud and hud.has_method("update_crosshair_position"):
			hud.update_crosshair_position()

func update_camera_sway(delta):
	var viewport = get_viewport()
	var mouse_pos = viewport.get_mouse_position()
	var size = viewport.get_visible_rect().size

	var norm_x = ((mouse_pos.x / size.x) - 0.5) * 2.0
	var norm_y = ((mouse_pos.y / size.y) - 0.5) * 2.0

	var target_offset = Vector3(norm_x * sway_max_offset, 0, norm_y * sway_max_offset)
	sway_offset = sway_offset.lerp(target_offset, sway_speed * delta)

	# Posição base da câmera: bem acima e atrás do jogador
	var base_pos = global_transform.origin
	base_pos.x += sway_offset.x
	base_pos.z += sway_offset.z
	base_pos.y += camera_height

	# Aplica o deslocamento para trás (ângulo isométrico)
	var angle_rad = deg_to_rad(camera_angle_deg)
	base_pos.x += camera_distance * sin(angle_rad)
	base_pos.z += camera_distance * cos(angle_rad)

	third_person_camera.global_transform.origin = base_pos
	third_person_camera.look_at(global_transform.origin, Vector3.UP)

func update_third_person_look():
	if third_person_camera and third_person_camera.has_node("MouseRay"):
		var cam_mouse_ray = third_person_camera.get_node("MouseRay")
		var viewport = get_viewport()
		var mouse_pos = viewport.get_mouse_position()
		
		# Converte a posição do mouse para coordenadas do viewport normalizadas (-1 a 1)
		var viewport_size = viewport.get_visible_rect().size
		var normalized_pos = Vector2(
			(mouse_pos.x / viewport_size.x) * 2.0 - 1.0,
			(mouse_pos.y / viewport_size.y) * 2.0 - 1.0
		)
		
		# Cria um raio a partir da câmera
		var camera = third_person_camera
		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * 1000.0
		
		# Atualiza a posição e direção do mouseRay
		cam_mouse_ray.global_position = from
		cam_mouse_ray.target_position = to - from
		cam_mouse_ray.force_raycast_update()
		
		# Atualiza a rotação do personagem se houver colisão
		if cam_mouse_ray.is_colliding():
			var hit_point = cam_mouse_ray.get_collision_point()
			var player_pos = global_transform.origin
			var look_dir = hit_point - player_pos
			look_dir.y = 0
			if look_dir.length() > 0.1 and visuals:
				var look_at_pos = Vector3(hit_point.x, visuals.global_transform.origin.y, hit_point.z)
				# Inverte a direção do look_at adicionando 180 graus à rotação
				visuals.look_at(look_at_pos, Vector3.UP)
				visuals.rotation.y += PI  # Adiciona 180 graus (PI radianos)
				visuals.rotation.x = 0
				visuals.rotation.z = 0

# Métodos para as habilidades
func set_speed_multiplier(value: float):
	speed_multiplier = value

func set_damage_multiplier(value: float):
	damage_multiplier = value

func set_health_multiplier(value: float):
	health_multiplier = value

# Função para atualizar a velocidade baseada nas estatísticas
func update_speed():
	speed = 200.0 * (1.0 - (status_effects.velocidade_reduzida / 100.0))
	speed = max(speed, 50.0)  # Velocidade mínima

# Função para curar o jogador
func heal(amount):
	stats.hp = min(stats.hp + amount, stats.max_hp)
	emit_signal("player_health_changed", stats.hp, stats.max_hp)
	print("Jogador curado em ", amount, " HP. HP atual: ", stats.hp)

# Função para restaurar MP
func restore_mp(amount):
	stats.mp = min(stats.mp + amount, stats.max_mp)
	emit_signal("player_mp_changed", stats.mp, stats.max_mp)
	print("MP restaurado em ", amount, ". MP atual: ", stats.mp)

# Função para ganhar experiência
func gain_xp(amount):
	stats.xp += amount
	emit_signal("player_xp_changed", stats.xp)
	print("Ganhou ", amount, " de XP. XP total: ", stats.xp)

# Função para aplicar upgrades de habilidades da TV
func apply_skill_upgrade(branch: String, level: int):
	print("[Player] Aplicando upgrade de habilidade: ", branch, " nível ", level)
	
	match branch:
		"speed":
			match level:
				1:
					speed_multiplier += 0.1  # +10%
					print("[Player] Velocidade aumentada em 10%")
				2:
					speed_multiplier += 0.1  # +20% total
					print("[Player] Velocidade aumentada em 20% (total)")
				3:
					speed_multiplier += 0.1  # +30% total
					print("[Player] Velocidade aumentada em 30% (total)")
		
		"damage":
			match level:
				1:
					damage_multiplier += 0.15  # +15%
					attack_damage *= 1.15
					print("[Player] Dano aumentado em 15%")
				2:
					damage_multiplier += 0.1   # +25% total
					attack_damage *= 1.087  # Para chegar a 25% total
					print("[Player] Dano aumentado em 25% (total)")
				3:
					damage_multiplier += 0.1   # +35% total
					attack_damage *= 1.08   # Para chegar a 35% total
					print("[Player] Dano aumentado em 35% (total)")
		
		"health":
			match level:
				1:
					health_multiplier += 0.2  # +20%
					var old_max = stats.max_hp
					stats.max_hp = int(stats.max_hp * 1.2)
					stats.hp = int(stats.hp * (stats.max_hp / float(old_max)))
					max_health = stats.max_hp
					current_health = stats.hp
					emit_signal("player_health_changed", stats.hp, stats.max_hp)
					print("[Player] Vida máxima aumentada em 20%")
				2:
					health_multiplier += 0.1  # +30% total
					var old_max = stats.max_hp
					stats.max_hp = int(stats.max_hp * 1.083)  # Para chegar a 30% total
					stats.hp = int(stats.hp * (stats.max_hp / float(old_max)))
					max_health = stats.max_hp
					current_health = stats.hp
					emit_signal("player_health_changed", stats.hp, stats.max_hp)
					print("[Player] Vida máxima aumentada em 30% (total)")
				3:
					health_multiplier += 0.1  # +40% total
					var old_max = stats.max_hp
					stats.max_hp = int(stats.max_hp * 1.077)  # Para chegar a 40% total
					stats.hp = int(stats.hp * (stats.max_hp / float(old_max)))
					max_health = stats.max_hp
					current_health = stats.hp
					emit_signal("player_health_changed", stats.hp, stats.max_hp)
					print("[Player] Vida máxima aumentada em 40% (total)")
	
	# Atualiza as estatísticas
	emit_signal("player_stats_changed", stats)

# Callback para quando uma habilidade é melhorada via SkillManager
func _on_skill_upgraded(branch: String, level: int):
	apply_skill_upgrade(branch, level)

# Função para alterar a consciência
func change_consciencia(amount):
	stats.consciencia = clamp(stats.consciencia + amount, 0, 100)
	emit_signal("player_consciencia_changed", stats.consciencia)
	print("Consciência alterada em ", amount, ". Valor atual: ", stats.consciencia)

# Função para aplicar efeito de status
func apply_status_effect(effect_type, amount):
	match effect_type:
		"defesa_reduzida":
			status_effects.defesa_reduzida += amount
		"ataque_reduzido":
			status_effects.ataque_reduzido += amount
		"velocidade_reduzida":
			status_effects.velocidade_reduzida += amount
			update_speed()
		"gift_boost":
			status_effects.gift_boost += amount
	
	print("Efeito de status aplicado: ", effect_type, " (", amount, ")")

# Função para remover efeito de status
func remove_status_effect(effect_type, amount):
	match effect_type:
		"defesa_reduzida":
			status_effects.defesa_reduzida = max(0, status_effects.defesa_reduzida - amount)
		"ataque_reduzido":
			status_effects.ataque_reduzido = max(0, status_effects.ataque_reduzido - amount)
		"velocidade_reduzida":
			status_effects.velocidade_reduzida = max(0, status_effects.velocidade_reduzida - amount)
			update_speed()
		"gift_boost":
			status_effects.gift_boost = max(0, status_effects.gift_boost - amount)
	
	print("Efeito de status removido: ", effect_type, " (", amount, ")")

# Função para salvar o estado do jogador
func save_state():
	var save_data = {
		"stats": stats,
		"status_effects": status_effects,
		"position": {
			"x": position.x,
			"y": position.y
		}
	}
	return save_data

# Função para carregar o estado do jogador
func load_state(save_data):
	stats = save_data.stats
	status_effects = save_data.status_effects
	position = Vector3(save_data.position.x, position.y, save_data.position.y)
	
	# Atualiza a velocidade baseada nos efeitos de status
	update_speed()
	
	# Emite sinais de atualização
	emit_signal("player_health_changed", stats.hp, stats.max_hp)
	emit_signal("player_mp_changed", stats.mp, stats.max_mp)
	emit_signal("player_xp_changed", stats.xp)
	emit_signal("player_consciencia_changed", stats.consciencia)
	emit_signal("player_stats_changed", stats)

# Função para reativar completamente o player após transições
func reactivate_player():
	"""
	Reativa completamente o player após transições de cena
	"""
	print("[Player] Reativando player completamente")
	
	# Reativa todos os processos
	set_physics_process(true)
	set_process_input(true)
	set_process(true)
	
	# Garante que pode se mover
	can_move = true
	
	# Reseta velocidade se for CharacterBody3D
	if self is CharacterBody3D:
		velocity = Vector3.ZERO
	
	# Reativa o modo de mouse se necessário
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and first_person_mode:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.mouse_mode != Input.MOUSE_MODE_VISIBLE and not first_person_mode:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	print("[Player] Player reativado - can_move: ", can_move, " physics: ", is_physics_processing(), " input: ", is_processing_input())
