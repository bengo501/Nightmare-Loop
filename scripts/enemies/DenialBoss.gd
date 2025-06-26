extends GhostBase
class_name DenialBoss

# === PROPRIEDADES DO BOSS ===
@export var boss_max_health: float = 500.0  # Vida muito alta para boss
@export var boss_speed: float = 2.5  # Mais lento mas imponente
@export var boss_attack_damage: float = 40.0  # Dano alto
@export var boss_scale: Vector3 = Vector3(2.5, 2.5, 2.5)  # Muito maior que fantasmas normais
@export var phase_change_threshold: float = 0.5  # Muda de fase aos 50% de vida

# === MECÂNICAS ESPECIAIS DO BOSS ===
@export var denial_phase_duration: float = 3.0  # Duração da fase de negação
@export var summon_cooldown: float = 8.0  # Tempo entre invocações
@export var teleport_cooldown: float = 6.0  # Tempo entre teletransportes
@export var area_attack_cooldown: float = 12.0  # Tempo entre ataques em área

# === ESTADOS DO BOSS ===
enum BossPhase {
	PHASE_1_DENIAL,      # Fase 1: Negação básica
	PHASE_2_DESPERATE    # Fase 2: Negação desesperada (50% vida)
}

var current_boss_phase: BossPhase = BossPhase.PHASE_1_DENIAL
var is_in_denial_state: bool = false
var last_summon_time: float = 0.0
var last_teleport_time: float = 0.0
var last_area_attack_time: float = 0.0
var denial_state_timer: float = 0.0

# === REFERÊNCIAS PARA UI ===
var boss_health_bar: Control = null
var initial_position: Vector3

# === FANTASMAS INVOCADOS ===
var summoned_ghosts: Array[Node3D] = []
var max_summoned_ghosts: int = 3

# === SINAIS DO BOSS ===
signal boss_phase_changed(new_phase: BossPhase)
signal boss_defeated
signal boss_health_changed(current_health: float, max_health: float)

func _ready():
	# Configura propriedades específicas do boss
	grief_stage = GriefStage.DENIAL
	max_health = boss_max_health
	current_health = boss_max_health
	speed = boss_speed
	attack_damage = boss_attack_damage
	scale = boss_scale
	
	# Sobrescreve as propriedades do estágio para o boss
	stage_properties[GriefStage.DENIAL] = {
		"color": Vector4(0.1, 0.8, 0.1, 0.9),  # Verde mais intenso
		"texture": "res://assets/textures/greenGhost.png",
		"speed_multiplier": 1.0,
		"health_multiplier": 1.0,
		"special_ability": "boss_denial_powers",
		"scale": boss_scale
	}
	
	initial_position = global_position
	
	# Chama o _ready da classe pai
	super._ready()
	
	# Configurações específicas do boss
	print("👑 BOSS DA NEGAÇÃO DESPERTOU!")
	print("🩸 Vida: ", current_health, "/", max_health)
	print("⚡ Fase atual: ", BossPhase.keys()[current_boss_phase])
	
	# Conecta sinais
	boss_health_changed.connect(_on_boss_health_changed)
	boss_phase_changed.connect(_on_boss_phase_changed)
	
	# Procura pela barra de vida do boss
	_setup_boss_health_bar()
	
	# Emite sinal inicial de vida
	emit_signal("boss_health_changed", current_health, max_health)

func _setup_boss_health_bar():
	# Procura pela barra de vida do boss na UI
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager and ui_manager.has_method("show_boss_health_bar"):
		ui_manager.show_boss_health_bar("Chefe da Negação", max_health)
		boss_health_bar = ui_manager.get_boss_health_bar()
	else:
		print("⚠️ Sistema de barra de vida do boss não encontrado")

func _physics_process(delta):
	# Atualiza timers dos ataques especiais
	_update_special_attack_timers(delta)
	
	# Atualiza estado de negação
	if is_in_denial_state:
		denial_state_timer -= delta
		if denial_state_timer <= 0:
			_end_denial_state()
	
	# Executa ataques especiais baseados na fase
	_execute_boss_special_attacks()
	
	# Chama o _physics_process da classe pai
	super._physics_process(delta)

func _update_special_attack_timers(delta):
	last_summon_time += delta
	last_teleport_time += delta
	last_area_attack_time += delta

func _execute_boss_special_attacks():
	if is_dying or not player_ref:
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	# Ataque de invocação
	if last_summon_time >= summon_cooldown and summoned_ghosts.size() < max_summoned_ghosts:
		_summon_denial_ghosts()
	
	# Teletransporte quando jogador está muito próximo
	if distance_to_player < 3.0 and last_teleport_time >= teleport_cooldown:
		_denial_teleport()
	
	# Ataque em área quando jogador está em distância média
	if distance_to_player >= 3.0 and distance_to_player <= 8.0 and last_area_attack_time >= area_attack_cooldown:
		_denial_wave_attack()

# === MECÂNICAS ESPECIAIS DO BOSS ===
func _summon_denial_ghosts():
	print("👑 BOSS: Invocando fantasmas da negação!")
	last_summon_time = 0.0
	
	var ghost_scene = preload("res://scenes/enemies/GhostDenial.tscn")
	var spawn_positions = [
		global_position + Vector3(3, 0, 3),
		global_position + Vector3(-3, 0, 3),
		global_position + Vector3(0, 0, -3)
	]
	
	for i in range(min(max_summoned_ghosts - summoned_ghosts.size(), 3)):
		var ghost = ghost_scene.instantiate()
		ghost.global_position = spawn_positions[i]
		ghost.scale = Vector3(0.8, 0.8, 0.8)  # Menores que o boss
		get_tree().current_scene.add_child(ghost)
		summoned_ghosts.append(ghost)
		
		# Conecta sinal de morte para remover da lista
		if ghost.has_signal("ghost_defeated"):
			ghost.ghost_defeated.connect(_on_summoned_ghost_defeated.bind(ghost))
	
	print("👻 ", summoned_ghosts.size(), " fantasmas invocados!")

func _denial_teleport():
	print("👑 BOSS: Negando a realidade! Teletransporte!")
	last_teleport_time = 0.0
	
	# Efeito visual de desaparecimento
	if ghost_cylinder:
		var tween = create_tween()
		tween.tween_property(ghost_cylinder, "modulate:a", 0.0, 0.3)
		await tween.finished
	
	# Teletransporta para uma posição aleatória longe do jogador
	var teleport_positions = [
		initial_position + Vector3(8, 0, 8),
		initial_position + Vector3(-8, 0, 8),
		initial_position + Vector3(8, 0, -8),
		initial_position + Vector3(-8, 0, -8)
	]
	
	global_position = teleport_positions[randi() % teleport_positions.size()]
	
	# Efeito visual de reaparecimento
	if ghost_cylinder:
		var tween = create_tween()
		tween.tween_property(ghost_cylinder, "modulate:a", 1.0, 0.3)
	
	print("💨 Boss teletransportou para: ", global_position)

func _denial_wave_attack():
	print("👑 BOSS: Onda de negação!")
	last_area_attack_time = 0.0
	
	# Cria múltiplas ondas de dano em círculo
	var wave_count = 3
	var wave_radius = 2.0
	
	for i in range(wave_count):
		await get_tree().create_timer(0.5).timeout
		_create_denial_wave(wave_radius * (i + 1))

func _create_denial_wave(radius: float):
	# Cria área de dano em círculo
	var wave_area = Area3D.new()
	var shape = SphereShape3D.new()
	shape.radius = radius
	var collision = CollisionShape3D.new()
	collision.shape = shape
	wave_area.add_child(collision)
	wave_area.global_position = global_position
	get_tree().current_scene.add_child(wave_area)
	
	# Verifica colisão com jogador
	await get_tree().process_frame  # Espera um frame para área ser processada
	
	for body in wave_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			var wave_damage = attack_damage * 0.6  # 60% do dano normal
			body.take_damage(wave_damage)
			print("🌊 Onda de negação atingiu o jogador! Dano: ", wave_damage)
	
	# Remove a área após um tempo
	await get_tree().create_timer(0.1).timeout
	wave_area.queue_free()

# === SISTEMA DE FASES ===
func _check_phase_change():
	var health_percentage = current_health / max_health
	
	if health_percentage <= phase_change_threshold and current_boss_phase == BossPhase.PHASE_1_DENIAL:
		_change_to_phase_2()

func _change_to_phase_2():
	current_boss_phase = BossPhase.PHASE_2_DESPERATE
	emit_signal("boss_phase_changed", current_boss_phase)
	
	print("👑 BOSS ENTROU NA FASE 2: NEGAÇÃO DESESPERADA!")
	
	# Aumenta velocidade e diminui cooldowns
	speed *= 1.3
	summon_cooldown *= 0.7
	teleport_cooldown *= 0.8
	area_attack_cooldown *= 0.6
	max_summoned_ghosts = 5  # Pode invocar mais fantasmas
	
	# Muda cor para mais intensa
	if ghost_cylinder and ghost_cylinder.material is ShaderMaterial:
		ghost_cylinder.material.set_shader_parameter("ghost_color", Vector4(0.0, 1.0, 0.0, 1.0))
	
	# Cura parcial na mudança de fase
	var heal_amount = max_health * 0.15  # Cura 15%
	current_health = min(current_health + heal_amount, max_health)
	emit_signal("boss_health_changed", current_health, max_health)
	
	print("💚 Boss se curou em ", heal_amount, " pontos!")

# === OVERRIDE DAS FUNÇÕES DA CLASSE PAI ===
func take_damage(amount: int):
	if is_dying:
		return
	
	# Boss resiste a dano durante estado de negação
	if is_in_denial_state:
		amount = int(amount * 0.3)  # Reduz dano em 70%
		print("🛡️ Boss em estado de negação! Dano reduzido para: ", amount)
	
	current_health -= amount
	print("👑 BOSS tomou ", amount, " de dano! Vida restante: ", current_health, "/", max_health)
	
	# Emite sinal de mudança de vida
	emit_signal("boss_health_changed", current_health, max_health)
	
	# Mostra label de dano (maior para boss)
	if damage_label_scene:
		var label = damage_label_scene.instantiate()
		add_child(label)
		label.setup(amount, true)
		label.scale = Vector3(1.5, 1.5, 1.5)  # Label maior para boss
	
	# Efeito visual de dano mais intenso
	if ghost_cylinder:
		var original_color = ghost_cylinder.material.get_shader_parameter("ghost_color")
		ghost_cylinder.material.set_shader_parameter("ghost_color", Vector4(1.0, 0.0, 0.0, 1.0))
		await get_tree().create_timer(0.3).timeout
		ghost_cylinder.material.set_shader_parameter("ghost_color", original_color)
	
	# Chance de entrar em estado de negação quando recebe dano
	if not is_in_denial_state and randf() < 0.25:  # 25% de chance
		_enter_denial_state()
	
	# Verifica mudança de fase
	_check_phase_change()
	
	# Verifica se morreu
	if current_health <= 0:
		print("👑 CHEFE DA NEGAÇÃO FOI DERROTADO!")
		die()

func _enter_denial_state():
	is_in_denial_state = true
	denial_state_timer = denial_phase_duration
	
	print("🌫️ BOSS ENTROU EM ESTADO DE NEGAÇÃO! Resistência aumentada!")
	
	# Efeito visual de negação
	if ghost_cylinder and ghost_cylinder.material is ShaderMaterial:
		ghost_cylinder.material.set_shader_parameter("fuwafuwa_speed", 6.0)
		ghost_cylinder.material.set_shader_parameter("outline_ratio", 4.0)

func _end_denial_state():
	is_in_denial_state = false
	
	print("✨ Boss saiu do estado de negação")
	
	# Restaura efeitos visuais
	if ghost_cylinder and ghost_cylinder.material is ShaderMaterial:
		ghost_cylinder.material.set_shader_parameter("fuwafuwa_speed", 2.0)
		ghost_cylinder.material.set_shader_parameter("outline_ratio", 2.0)

func die():
	if is_dying:
		return
	
	is_dying = true
	print("👑 INICIANDO SEQUÊNCIA DE MORTE DO CHEFE DA NEGAÇÃO...")
	
	# Remove todos os fantasmas invocados
	for ghost in summoned_ghosts:
		if is_instance_valid(ghost):
			ghost.queue_free()
	summoned_ghosts.clear()
	
	# Efeito especial de morte do boss
	await _boss_death_sequence()
	
	# Concede muitos pontos de lucidez
	var lucidity_manager = get_node("/root/LucidityManager")
	if lucidity_manager:
		lucidity_manager.add_lucidity_point(10)  # 10 pontos por derrotar o boss!
		print("🎯 BOSS DERROTADO! +10 pontos de lucidez concedidos!")
	
	# Emite sinais
	emit_signal("boss_defeated")
	emit_signal("ghost_defeated")
	
	# Esconde barra de vida do boss
	if boss_health_bar:
		boss_health_bar.visible = false
	
	# Remove o boss
	queue_free()

func _boss_death_sequence():
	print("💀 Executando sequência épica de morte do boss...")
	
	# Sequência dramática de morte
	for i in range(5):
		if ghost_cylinder:
			var tween = create_tween()
			tween.tween_property(ghost_cylinder, "modulate:a", 0.2, 0.2)
			tween.tween_property(ghost_cylinder, "modulate:a", 1.0, 0.2)
			await tween.finished
		await get_tree().create_timer(0.3).timeout
	
	# Explosão final
	print("💥 EXPLOSÃO FINAL DO CHEFE DA NEGAÇÃO!")

# === CALLBACKS ===
func _on_summoned_ghost_defeated(ghost: Node3D):
	summoned_ghosts.erase(ghost)
	print("👻 Fantasma invocado foi derrotado. Restam: ", summoned_ghosts.size())

func _on_boss_health_changed(current: float, maximum: float):
	# Atualiza barra de vida do boss
	if boss_health_bar and boss_health_bar.has_method("update_health"):
		boss_health_bar.update_health(current, maximum)

func _on_boss_phase_changed(new_phase: BossPhase):
	print("🔄 Boss mudou para fase: ", BossPhase.keys()[new_phase])

# === OVERRIDE DA HABILIDADE ESPECIAL ===
func _execute_special_ability():
	# Boss não usa habilidade especial normal, usa mecânicas próprias
	print("👑 Boss da Negação recusa-se a aceitar a realidade!")
	
	# Força entrada em estado de negação
	if not is_in_denial_state:
		_enter_denial_state()
