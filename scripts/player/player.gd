extends CharacterBody3D

# === CONSTANTES DE MOVIMENTO ===
const SPEED = 3.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003
@export var rotation_speed: float = 35.0

# === VARIÁVEIS DE ATAQUE ===
@export var attack_damage: float = 20.0  # Dano base aumentado para 20
@export var attack_range: float = 10.0
@export var attack_cooldown: float = 0.2
@export var max_health: float = 100.0
var current_health: float
var defense_bonus: float = 1.0

# === SISTEMA DE MUNIÇÃO BASEADO NOS PONTOS DO LUTO ===
@export var ammo_consumption_rate: float = 0.3  # Reduzido para tiro mais rápido
var last_shot_time: float = 0.0
var ammo_timer: Timer

# === SISTEMA DE MODOS DE ATAQUE ===
enum AttackMode {
	NEGACAO = 0,    # Azul - Contra fantasmas de Negação
	RAIVA = 1,      # Verde - Contra fantasmas de Raiva  
	BARGANHA = 2,   # Azul escuro/cinza - Contra fantasmas de Barganha
	DEPRESSAO = 3,  # Roxo - Contra fantasmas de Depressão
	ACEITACAO = 4   # Amarelo - Contra fantasmas de Aceitação
}

var current_attack_mode: AttackMode = AttackMode.NEGACAO
var attack_mode_colors: Dictionary = {
	AttackMode.NEGACAO: Color(0, 0.6, 1, 1),      # Azul
	AttackMode.RAIVA: Color(0.2, 1, 0.2, 1),      # Verde
	AttackMode.BARGANHA: Color(0.4, 0.5, 0.6, 1), # Azul escuro/cinza
	AttackMode.DEPRESSAO: Color(0.6, 0.2, 1, 1),  # Roxo
	AttackMode.ACEITACAO: Color(1, 0.9, 0.2, 1)   # Amarelo
}

var attack_mode_names: Dictionary = {
	AttackMode.NEGACAO: "Negação",
	AttackMode.RAIVA: "Raiva", 
	AttackMode.BARGANHA: "Barganha",
	AttackMode.DEPRESSAO: "Depressão",
	AttackMode.ACEITACAO: "Aceitação"
}

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

# === REFERÊNCIA PARA O SISTEMA DE MUNIÇÃO ===
@onready var gift_manager = null  # Será inicializado no _ready()

# === ESTADOS ===
var first_person_mode = false
var laser_active = false
var can_attack: bool = true
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

# === SISTEMA DE TIRO CONTÍNUO ===
var is_shooting: bool = false  # Indica se está segurando o botão de tiro
var can_shoot_continuous: bool = true  # Controla se pode atirar continuamente

# === SISTEMA DE ANIMAÇÕES SUAVES ===
var current_animation: String = "idle"
var target_animation: String = "idle"
var animation_blend_time: float = 0.3  # Tempo de transição entre animações
var is_transitioning: bool = false

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
	
	# Configura collision layers para detecção pelos fantasmas
	collision_layer = 2  # Layer 2 para detecção pelos fantasmas
	collision_mask = 1   # Pode colidir com paredes (layer 1)
	
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
	
	# === INICIALIZA SISTEMA DE MUNIÇÃO ===
	# Conecta ao GiftManager
	gift_manager = get_node_or_null("/root/GiftManager")
	if not gift_manager:
		print("ERRO: GiftManager não encontrado! Sistema de munição desabilitado.")
	else:
		print("✓ GiftManager conectado - Sistema de munição ativo")
	
	# Configura o timer de munição
	setup_ammo_system()

	# === DEBUG DO SISTEMA DE MOVIMENTO ===
	print("========================================")
	print("🎮 SISTEMA DE MOVIMENTO INICIALIZADO")
	print("========================================")
	print("can_move: ", can_move)
	print("SPEED: ", SPEED)
	print("speed_multiplier: ", speed_multiplier)
	print("third_person_camera: ", third_person_camera != null)
	print("animation_player: ", animation_player != null)
	print("visuals: ", visuals != null)
	print("mouse_ray: ", mouse_ray != null)
	print("========================================")

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
			print("✓ AnimationPlayer encontrado: ", animation_player.get_animation_list())
	# MouseRay pode estar na câmera de terceira pessoa
	if third_person_camera and third_person_camera.has_node("MouseRay"):
		mouse_ray = third_person_camera.get_node("MouseRay")
		print("✓ MouseRay encontrado na câmera de terceira pessoa")

	# Inicialização de sistemas
	if third_person_camera:
		activate_third_person()
		print("✓ Modo terceira pessoa ativado por padrão")
	if laser_line and is_instance_valid(laser_line):
		laser_line.visible = false
	
	# === CONFIGURA SISTEMA DE ANIMAÇÕES SUAVES ===
	setup_animations()
	
	# === CONFIGURA OUTROS SISTEMAS ===
	setup_attack_system()
	setup_attack_modes()

	# Configurações iniciais
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if hud:
		connect("player_health_changed", Callable(hud, "set_health"))

func setup_attack_system():
	# Sistema de attack_timer removido - agora usando sistema de tiro contínuo
	# Timer de munição é configurado em setup_ammo_system()
	
	if shoot_ray:
		shoot_ray.target_position = Vector3(0, 0, -attack_range)
		shoot_ray.collision_mask = 2
		shoot_ray.enabled = true

func setup_animations():
	if animation_player == null:
		print("⚠️ AnimationPlayer não encontrado para configurar transições")
		return
	
	# Lista de todas as animações possíveis
	var animations = ["idle", "walk_front", "walk_back", "walk_left", "walk_right", "walk", "run"]
	
	# Configura transições suaves entre todas as animações
	for from_anim in animations:
		for to_anim in animations:
			if from_anim != to_anim and animation_player.has_animation(from_anim) and animation_player.has_animation(to_anim):
				animation_player.set_blend_time(from_anim, to_anim, animation_blend_time)
	
	print("✅ Transições de animação configuradas com tempo de blend: ", animation_blend_time, " segundos")
	print("📋 Animações disponíveis: ", animation_player.get_animation_list())

func setup_attack_modes():
	# Inicializa o modo de ataque padrão
	current_attack_mode = AttackMode.NEGACAO
	print("========================================")
	print("SISTEMA DE MODOS DE ATAQUE INICIALIZADO")
	print("========================================")
	print("Modo padrão: ", get_current_attack_name())
	print("Cor padrão: ", get_current_attack_color())
	
	# Configura o shader do laser com a cor inicial
	if laser_line and is_instance_valid(laser_line):
		update_laser_color()
		print("✓ Laser configurado com cor inicial")
	else:
		print("⚠️ LaseLine não encontrado ou inválido")
	
	# Configura o crosshair com a cor inicial
	update_crosshair_color()
	print("✓ Crosshair configurado com cor inicial")
	
	print("========================================")
	print("CONTROLES DOS MODOS DE ATAQUE:")
	print("1 - Negação (Azul) - Efetivo contra fantasmas Verdes")
	print("2 - Raiva (Verde) - Efetivo contra fantasmas Cinzas")
	print("3 - Barganha (Cinza) - Efetivo contra fantasmas Azuis")
	print("4 - Depressão (Roxo) - Efetivo contra fantasmas Roxos")
	print("5 - Aceitação (Amarelo) - Efetivo contra fantasmas Amarelos")
	print("========================================")

# === CONFIGURAÇÃO DO SISTEMA DE MUNIÇÃO ===
func setup_ammo_system():
	# Configura o timer de munição
	ammo_timer = Timer.new()
	ammo_timer.wait_time = ammo_consumption_rate
	ammo_timer.one_shot = true
	add_child(ammo_timer)
	
	print("========================================")
	print("SISTEMA DE MUNIÇÃO INICIALIZADO")
	print("========================================")
	print("Taxa de consumo: ", ammo_consumption_rate, " segundos entre tiros")
	print("Cada tiro consome 1 ponto do estágio do luto correspondente")
	print("========================================")

# === FÍSICA ===
func _physics_process(delta: float):
	# Verifica se deve continuar atirando
	if is_shooting and first_person_mode and can_shoot_continuous:
		# Só atira se tiver munição para o modo atual
		if has_ammo_for_current_mode():
			# Verifica se pode atirar (cooldown)
			if can_shoot():
				shoot_first_person()
		else:
			# Para o tiro se não tiver munição
			print("🚫 Tiro contínuo interrompido: Sem munição de ", get_current_attack_name())
			is_shooting = false
			laser_active = false
			if laser_line and is_instance_valid(laser_line):
				laser_line.visible = false
			stop_continuous_shooting()
	
	# Sistema de gravidade
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Sistema de pulo
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Sistema de movimento baseado no modo da câmera
	if can_move:
		if not first_person_mode:
			# Movimento isométrico no modo terceira pessoa
			move_isometric(delta)
			# Rotação para o mouse
			rotate_toward_mouse(delta)
		else:
			# Movimento em primeira pessoa
			handle_first_person_movement()
	
	# Aplica o movimento
	move_and_slide()

# === ROTAÇÃO PARA O MOUSE ===
func rotate_toward_mouse(delta):
	if not third_person_camera or not mouse_ray:
		return
		
	# Força a atualização do raycast
	mouse_ray.force_raycast_update()
	
	if mouse_ray.is_colliding():
		var hit_point = mouse_ray.get_collision_point()
		var player_pos = global_transform.origin
		var dir = hit_point - player_pos
		dir.y = 0  # Mantém no plano horizontal
		
		# Só rotaciona se a direção for significativa
		if dir.length_squared() > 0.01:
			var target_angle = atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, target_angle, delta * rotation_speed)
			
			# Aplica a rotação também aos visuais se disponível
			if visuals:
				visuals.rotation.y = rotation.y
				
			print("🔄 Rotacionando para: ", rad_to_deg(rotation.y), "°")

# === MOVIMENTO ISOMÉTRICO ===
func move_isometric(delta: float):
	var input_vector = Vector3.ZERO
	var raw_input = Vector2.ZERO
	
	# Captura as entradas do jogador
	if Input.is_action_pressed("foward"):
		input_vector.z -= 1
		raw_input.y -= 1
	if Input.is_action_pressed("backward"):
		input_vector.z += 1
		raw_input.y += 1
	if Input.is_action_pressed("left"):
		input_vector.x -= 1
		raw_input.x -= 1
	if Input.is_action_pressed("right"):
		input_vector.x += 1
		raw_input.x += 1
	
	# Se há movimento, aplica o movimento isométrico
	if input_vector != Vector3.ZERO:
		input_vector = input_vector.normalized()
		
		# Converte o input para movimento isométrico baseado na câmera
		if third_person_camera:
			var camera_basis = third_person_camera.global_transform.basis
			var direction = (camera_basis.x * input_vector.x) + (camera_basis.z * input_vector.z)
			direction.y = 0
			direction = direction.normalized()
			
			# Aplica a velocidade
			velocity.x = direction.x * SPEED * speed_multiplier
			velocity.z = direction.z * SPEED * speed_multiplier
		else:
			# Fallback se não tiver câmera
			velocity.x = input_vector.x * SPEED * speed_multiplier
			velocity.z = input_vector.z * SPEED * speed_multiplier
		
		# Determina a animação baseada na direção do input
		var animation_to_play = get_movement_animation(raw_input)
		play_animation(animation_to_play)
	else:
		# Para o movimento suavemente quando não há input
		velocity.x = lerp(velocity.x, 0.0, 0.2)
		velocity.z = lerp(velocity.z, 0.0, 0.2)
		
		# Toca a animação idle
		play_animation("idle")

# === SISTEMA DE ANIMAÇÕES DIRECIONAIS ===
func get_movement_animation(input_dir: Vector2) -> String:
	# Determina a direção principal do movimento
	if abs(input_dir.x) > abs(input_dir.y):
		# Movimento horizontal dominante
		if input_dir.x > 0:
			return "walk_right"
		else:
			return "walk_left"
	else:
		# Movimento vertical dominante
		if input_dir.y < 0:
			return "walk_front"
		else:
			return "walk_back"

# === MOVIMENTO EM PRIMEIRA PESSOA ===
func handle_first_person_movement():
	var input_dir = Vector3()
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
	if not animation_player:
		print("⚠️ AnimationPlayer não encontrado!")
		return
	
	# Normaliza o nome da animação e encontra a melhor disponível
	var final_animation = get_best_available_animation(anim_name)
	
	if final_animation == "":
		print("⚠️ Nenhuma animação disponível para: ", anim_name)
		return
	
	# Se já está tocando a animação desejada, não faz nada
	if current_animation == final_animation and animation_player.is_playing():
		return
	
	# Atualiza o estado da animação
	target_animation = final_animation
	
	# Se não há animação atual ou é a primeira vez, toca diretamente
	if current_animation == "" or not animation_player.is_playing():
		_play_animation_direct(final_animation)
		return
	
	# Se há uma animação tocando, faz a transição suave
	_play_animation_with_transition(final_animation)

# === SISTEMA DE TRANSIÇÕES SUAVES ===
func get_best_available_animation(requested_anim: String) -> String:
	# Primeiro, tenta a animação exata
	if animation_player.has_animation(requested_anim):
		return requested_anim
	
	# Se não encontrar, tenta alternativas baseadas no tipo
	match requested_anim:
		"walk_front", "walk_back", "walk_left", "walk_right":
			# Tenta animações de caminhada genéricas
			if animation_player.has_animation("walk"):
				return "walk"
			elif animation_player.has_animation("run"):
				return "run"
			elif animation_player.has_animation("idle"):
				return "idle"
		"idle":
			# Para idle, tenta variações
			if animation_player.has_animation("idle"):
				return "idle"
			elif animation_player.has_animation("default"):
				return "default"
		_:
			# Para outras animações, tenta idle como fallback
			if animation_player.has_animation("idle"):
				return "idle"
	
	return ""  # Nenhuma animação encontrada

func _play_animation_direct(anim_name: String):
	animation_player.play(anim_name)
	current_animation = anim_name
	target_animation = anim_name
	is_transitioning = false
	print("🎭 Tocando animação direta: ", anim_name)

func _play_animation_with_transition(anim_name: String):
	# Se já está em transição para a mesma animação, não faz nada
	if is_transitioning and target_animation == anim_name:
		return
	
	is_transitioning = true
	
	# Usa o sistema de blend do Godot para transição suave
	var blend_time = animation_blend_time
	
	# Ajusta o tempo de blend baseado no tipo de transição
	if (current_animation == "idle" and anim_name.begins_with("walk")) or \
	   (current_animation.begins_with("walk") and anim_name == "idle"):
		blend_time = animation_blend_time * 0.7  # Transição mais rápida idle <-> walk
	elif current_animation.begins_with("walk") and anim_name.begins_with("walk"):
		blend_time = animation_blend_time * 0.5  # Transição muito rápida entre direções
	
	# Executa a transição
	animation_player.play(anim_name, -1, 1.0, false)
	current_animation = anim_name
	target_animation = anim_name
	
	print("🔄 Transição suave: ", current_animation, " -> ", anim_name, " (", blend_time, "s)")
	
	# Agenda o fim da transição
	await get_tree().create_timer(blend_time).timeout
	is_transitioning = false

# === FUNÇÃO AUXILIAR PARA VERIFICAR ESTADO DAS ANIMAÇÕES ===
func get_current_animation_info() -> Dictionary:
	return {
		"current": current_animation,
		"target": target_animation,
		"is_playing": animation_player.is_playing() if animation_player else false,
		"is_transitioning": is_transitioning,
		"player_animation": animation_player.current_animation if animation_player else ""
	}

# === LASER E ATAQUE ===
# Funções antigas removidas - agora usando sistema de tiro contínuo

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
				# Inicia tiro contínuo
				is_shooting = true
				laser_active = true
				if laser_line and is_instance_valid(laser_line):
					laser_line.visible = true
				start_continuous_shooting()
			else:
				# Para tiro contínuo
				is_shooting = false
				laser_active = false
				if laser_line and is_instance_valid(laser_line):
					laser_line.visible = false
				stop_continuous_shooting()
	if first_person_mode and event is InputEventMouseMotion:
		rotate_camera(event.relative)
	# Ativação do laser/ataque com a tecla F
	if first_person_mode and event is InputEventKey:
		if event.keycode == KEY_F:
			if event.pressed and not event.echo:
				# Inicia tiro contínuo
				is_shooting = true
				laser_active = true
				if laser_line and is_instance_valid(laser_line):
					laser_line.visible = true
				start_continuous_shooting()
			elif not event.pressed:
				# Para tiro contínuo
				is_shooting = false
				laser_active = false
				if laser_line and is_instance_valid(laser_line):
					laser_line.visible = false
				stop_continuous_shooting()
	
	# === SISTEMA DE SELEÇÃO DE MODO DE ATAQUE ===
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				set_attack_mode(AttackMode.NEGACAO)
			KEY_2:
				set_attack_mode(AttackMode.RAIVA)
			KEY_3:
				set_attack_mode(AttackMode.BARGANHA)
			KEY_4:
				set_attack_mode(AttackMode.DEPRESSAO)
			KEY_5:
				set_attack_mode(AttackMode.ACEITACAO)
			# === TESTE: GANHA PONTOS DE LUCIDEZ ===
			KEY_P:
				# Tecla P para ganhar pontos de lucidez (apenas para teste)
				var lucidity_manager = get_node_or_null("/root/LucidityManager")
				if lucidity_manager:
					lucidity_manager.add_lucidity_point(1)
					print("🎯 [TESTE] +1 ponto de lucidez concedido! Total: ", lucidity_manager.get_lucidity_points())
			KEY_T:
				# Tecla T para debug do sistema de animações
				print("========================================")
				print("🎭 DEBUG SISTEMA DE ANIMAÇÕES")
				print("========================================")
				var info = get_current_animation_info()
				print("Animação atual: ", info.current)
				print("Animação alvo: ", info.target)
				print("Está reproduzindo: ", info.is_playing)
				print("Em transição: ", info.is_transitioning)
				print("AnimationPlayer atual: ", info.player_animation)
				print("Tempo de blend: ", animation_blend_time, " segundos")
				if animation_player:
					print("Animações disponíveis: ", animation_player.get_animation_list())
				print("========================================")

func shoot_first_person():
	# GARANTIA EXTRA: Só funciona se estiver realmente no modo primeira pessoa
	if not first_person_mode:
		print("DEBUG: Tentativa de ataque bloqueada - não está no modo primeira pessoa")
		return
	
	# === SISTEMA DE MUNIÇÃO ===
	# Verifica se pode atirar (cooldown + munição)
	if not can_shoot():
		if not has_ammo_for_current_mode():
			print("🚫 TIRO BLOQUEADO: Sem munição de ", get_current_attack_name(), "!")
			# Para o tiro contínuo se não tiver munição
			is_shooting = false
			laser_active = false
			if laser_line and is_instance_valid(laser_line):
				laser_line.visible = false
		else:
			print("⏱️ TIRO BLOQUEADO: Aguarde o cooldown de ", ammo_consumption_rate, " segundos")
		return
	
	# Consome munição antes de atirar
	if not consume_ammo():
		print("🚫 TIRO CANCELADO: Falha ao consumir munição")
		# Para o tiro contínuo se falhar ao consumir munição
		is_shooting = false
		laser_active = false
		if laser_line and is_instance_valid(laser_line):
			laser_line.visible = false
		return
		
	if not shoot_ray:
		return
	shoot_ray.force_raycast_update()
	if shoot_ray.is_colliding():
		var collider = shoot_ray.get_collider()
		if collider and collider.is_in_group("enemy"):
			if collider.has_method("take_damage"):
				var damage_result = calculate_damage_against_target(collider)
				var final_damage = damage_result.damage
				var is_critical = damage_result.is_critical
				
				# Chama take_damage com informação de crítico se o método suportar
				if collider.has_method("take_damage_with_critical"):
					collider.take_damage_with_critical(final_damage, is_critical)
				else:
					collider.take_damage(final_damage)
				
				if is_critical:
					print("💥🔥 ACERTO CRÍTICO! Dano: ", final_damage, " (modo: ", get_current_attack_name(), ")")
				else:
					print("🎯 ACERTO! Dano: ", final_damage, " (modo: ", get_current_attack_name(), ")")
	else:
		print("💥 TIRO DISPARADO: Sem alvo atingido (modo: ", get_current_attack_name(), ")")

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
	
	# === REABILITA O SISTEMA DE LASER E ATAQUE ===
	# Reabilita o ShootRay para permitir detecção de colisões
	if shoot_ray and is_instance_valid(shoot_ray):
		shoot_ray.enabled = true
		print("DEBUG: ShootRay reabilitado no modo primeira pessoa")
	
	# === CONFIGURAÇÕES VISUAIS E DE CÂMERA ===
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
	
	print("DEBUG: Modo primeira pessoa ativado - Laser e ataques habilitados")

func activate_third_person():
	first_person_mode = false
	
	# === PARA COMPLETAMENTE O SISTEMA DE TIRO CONTÍNUO ===
	is_shooting = false
	can_shoot_continuous = false
	
	# === DESABILITA COMPLETAMENTE O SISTEMA DE LASER E ATAQUE ===
	# Para garantir que não haja ataques no modo terceira pessoa
	laser_active = false
	current_target = null
	
	# Esconde e desabilita o laser
	if laser_line and is_instance_valid(laser_line):
		laser_line.visible = false
		print("DEBUG: Laser desabilitado no modo terceira pessoa")
	
	# Desabilita o ShootRay para evitar detecções acidentais
	if shoot_ray and is_instance_valid(shoot_ray):
		shoot_ray.enabled = false
		print("DEBUG: ShootRay desabilitado no modo terceira pessoa")
	
	# === CONFIGURAÇÕES VISUAIS E DE CÂMERA ===
	if visuals:
		visuals.visible = true
	if crosshair and is_instance_valid(crosshair):
		crosshair.visible = false
	if hud and is_instance_valid(hud):
		# Alterna crosshair para modo de terceira pessoa
		if hud.has_method("set_crosshair_mode"):
			hud.set_crosshair_mode(false)
	if first_person_camera:
		first_person_camera.current = false
	if third_person_camera:
		third_person_camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if weapon and is_instance_valid(weapon):
		weapon.visible = false
	
	print("DEBUG: Modo terceira pessoa ativado - Laser, ataques e tiro contínuo desabilitados")

# === SISTEMA DE MODOS DE ATAQUE ===
func set_attack_mode(mode: AttackMode):
	current_attack_mode = mode
	var mode_name = attack_mode_names[mode]
	var ammo_count = get_current_ammo_count()
	
	print("========================================")
	print("🎯 MODO DE ATAQUE ALTERADO")
	print("Modo: ", mode_name)
	print("Cor: ", attack_mode_colors[mode])
	print("Munição disponível: ", ammo_count)
	
	# Verifica se tem munição para este modo
	if ammo_count <= 0:
		print("⚠️ ATENÇÃO: Sem munição! Colete presentes de ", mode_name, " para atirar")
		
		# Esconde o laser se estiver ativo e não tiver munição
		if laser_active and laser_line and is_instance_valid(laser_line):
			laser_line.visible = false
			print("🚫 Laser escondido - sem munição de ", mode_name)
		
		# Para o tiro contínuo se estiver ativo
		if is_shooting:
			is_shooting = false
			laser_active = false
			stop_continuous_shooting()
			print("🛑 Tiro contínuo interrompido - sem munição de ", mode_name)
	else:
		# Mostra o laser se estiver ativo e tiver munição
		if laser_active and laser_line and is_instance_valid(laser_line):
			laser_line.visible = true
			print("✅ Laser reativado - munição de ", mode_name, " disponível")
	
	print("========================================")
	
	# Atualiza a cor do laser
	update_laser_color()
	
	# Atualiza a cor do crosshair se estiver disponível
	update_crosshair_color()

func get_current_attack_mode() -> AttackMode:
	return current_attack_mode

func get_current_attack_color() -> Color:
	return attack_mode_colors[current_attack_mode]

func get_current_attack_name() -> String:
	return attack_mode_names[current_attack_mode]

func calculate_damage_against_target(target) -> Dictionary:
	var base_damage = attack_damage  # 20 de dano base
	var is_critical = false
	
	# Verifica se o alvo é um fantasma com estágio de luto
	if target.has_method("get_grief_stage"):
		var target_stage = target.get_grief_stage()
		
		# Mapeia os estágios dos fantasmas para os modos de ataque
		var stage_to_mode = {
			0: AttackMode.NEGACAO,    # GriefStage.DENIAL
			1: AttackMode.RAIVA,      # GriefStage.ANGER  
			2: AttackMode.BARGANHA,   # GriefStage.BARGAINING
			3: AttackMode.DEPRESSAO,  # GriefStage.DEPRESSION
			4: AttackMode.ACEITACAO   # GriefStage.ACCEPTANCE
		}
		
		# Se o modo de ataque corresponde ao estágio do fantasma, dano duplo (CRÍTICO)
		if target_stage in stage_to_mode and stage_to_mode[target_stage] == current_attack_mode:
			base_damage *= 2.0
			is_critical = true
			print("💥🔥 DANO CRÍTICO! Modo ", get_current_attack_name(), " vs fantasma ", target_stage, " = ", base_damage, " dano")
		else:
			print("⚔️ Dano normal: ", base_damage, " (modo ", get_current_attack_name(), " vs fantasma estágio ", target_stage, ")")
	else:
		print("⚔️ Dano base: ", base_damage, " contra alvo sem estágio de luto")
	
	return {
		"damage": base_damage,
		"is_critical": is_critical
	}

# === LASER ===
func update_laser_color():
	if laser_line and is_instance_valid(laser_line):
		# Garante que o laser tem um material shader
		if laser_line.material_override == null:
			var shader_material = ShaderMaterial.new()
			shader_material.shader = preload("res://shaders/laserRay.gdshader")
			laser_line.material_override = shader_material
		
		# Atualiza a cor baseada no modo de ataque atual
		if laser_line.material_override is ShaderMaterial:
			var current_color = get_current_attack_color()
			laser_line.material_override.set_shader_parameter("core_color", current_color)
			print("Cor do laser atualizada para: ", current_color)

func update_crosshair_color():
	# Atualiza a cor do crosshair se disponível
	if crosshair and is_instance_valid(crosshair) and crosshair.material is ShaderMaterial:
		var current_color = get_current_attack_color()
		crosshair.material.set_shader_parameter("dot_color", current_color)
		crosshair.material.set_shader_parameter("line_color", current_color)
		print("Cor do crosshair atualizada para: ", current_color)
	
	# Também atualiza no HUD se disponível
	if hud and hud.has_method("set_crosshair_color"):
		hud.set_crosshair_color(get_current_attack_color())

# === SISTEMA DE MUNIÇÃO BASEADO NOS PONTOS DO LUTO ===
func can_shoot() -> bool:
	# Verifica se passou o tempo de cooldown
	if ammo_timer and not ammo_timer.is_stopped():
		return false
	
	# Verifica se tem munição (pontos do estágio correspondente)
	return has_ammo_for_current_mode()

func has_ammo_for_current_mode() -> bool:
	if not gift_manager:
		print("AVISO: GiftManager não disponível - permitindo tiro")
		return true
	
	var ammo_type = get_ammo_type_for_mode(current_attack_mode)
	var current_ammo = gift_manager.get_gift_count(ammo_type)
	
	return current_ammo > 0

func get_ammo_type_for_mode(mode: AttackMode) -> String:
	# Mapeia os modos de ataque para os tipos de gift
	match mode:
		AttackMode.NEGACAO:
			return "negacao"
		AttackMode.RAIVA:
			return "raiva"
		AttackMode.BARGANHA:
			return "barganha"
		AttackMode.DEPRESSAO:
			return "depressao"
		AttackMode.ACEITACAO:
			return "aceitacao"
		_:
			return "negacao"  # Fallback

func consume_ammo() -> bool:
	if not gift_manager:
		print("AVISO: GiftManager não disponível - não consumindo munição")
		return true
	
	var ammo_type = get_ammo_type_for_mode(current_attack_mode)
	var current_ammo = gift_manager.get_gift_count(ammo_type)
	
	if current_ammo <= 0:
		print("🚫 SEM MUNIÇÃO! Não há pontos de ", get_current_attack_name(), " disponíveis")
		return false
	
	# Consome 1 ponto do estágio correspondente
	if gift_manager.use_gift(ammo_type, 1):
		print("💥 MUNIÇÃO CONSUMIDA: -1 ponto de ", get_current_attack_name(), " (Restante: ", gift_manager.get_gift_count(ammo_type), ")")
		
		# Inicia o cooldown para o próximo tiro
		if ammo_timer:
			ammo_timer.start()
		
		return true
	else:
		print("ERRO: Falha ao consumir munição")
		return false

func get_current_ammo_count() -> int:
	if not gift_manager:
		return 0
	
	var ammo_type = get_ammo_type_for_mode(current_attack_mode)
	return gift_manager.get_gift_count(ammo_type)

func die() -> void:
	print("💀 [Player] Executando função die()...")
	can_move = false  # Impede movimento
	
	# Emite sinais de morte
	emit_signal("player_died")
	emit_signal("game_over")
	
	# Garante que o estado muda para GAME_OVER
	var state_manager = get_node_or_null("/root/GameStateManager")
	if state_manager:
		state_manager.change_state(state_manager.GameState.GAME_OVER)
		print("💀 [Player] Estado mudado para GAME_OVER")
	else:
		print("❌ [Player] GameStateManager não encontrado!")
	
	# Mostra o menu de game over via UIManager
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager:
		ui_manager.show_ui("game_over")
		print("💀 [Player] Menu de Game Over mostrado")
	else:
		print("❌ [Player] UIManager não encontrado!")
	
	print("💀 [Player] Sequência de morte concluída")

# Função para receber dano
func take_damage(amount: float):
	var actual_damage = amount * (1.0 - (stats.defesa / 100.0))
	stats.hp = max(0, stats.hp - actual_damage)
	current_health = stats.hp  # Sincroniza com current_health
	
	emit_signal("health_changed", stats.hp)
	emit_signal("player_health_changed", stats.hp, stats.max_hp)
	
	print("🩸 [Player] Dano recebido: ", actual_damage, " | Vida atual: ", stats.hp, "/", stats.max_hp)
	
	# Mostra o indicador de dano
	if damage_indicator_scene:
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
	
	# VERIFICA SE O PLAYER MORREU
	if stats.hp <= 0:
		print("💀 [Player] PLAYER MORREU! Iniciando Game Over...")
		die()

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

# === SISTEMA DE TIRO CONTÍNUO ===
func start_continuous_shooting():
	print("🔫 Iniciando tiro contínuo...")
	can_shoot_continuous = true
	# Dispara o primeiro tiro imediatamente
	shoot_first_person()

func stop_continuous_shooting():
	print("🛑 Parando tiro contínuo...")
	can_shoot_continuous = false
	current_target = null

# === FUNÇÃO LEGACY PARA COMPATIBILIDADE ===
func _on_attack_timer_timeout():
	# Função mantida para compatibilidade - não é mais usada no sistema de tiro contínuo
	# O sistema antigo de attack_timer foi substituído pelo sistema de tiro contínuo
	pass

# === CONTROLE DINÂMICO DO SISTEMA DE ANIMAÇÕES ===
func set_animation_blend_time(new_time: float):
	animation_blend_time = clamp(new_time, 0.1, 2.0)  # Entre 0.1 e 2 segundos
	print("🎭 Tempo de blend das animações alterado para: ", animation_blend_time, " segundos")
	# Reaplica as configurações
	setup_animations()

func get_animation_blend_time() -> float:
	return animation_blend_time

func force_animation_reset():
	"""Força o reset do sistema de animações para resolver problemas"""
	if animation_player:
		animation_player.stop()
		current_animation = ""
		target_animation = ""
		is_transitioning = false
		print("🔄 Sistema de animações resetado")

func is_animation_transitioning() -> bool:
	return is_transitioning
