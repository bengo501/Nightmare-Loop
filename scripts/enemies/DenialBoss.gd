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

# === SISTEMA DE DIÁLOGO ===
@export var dialog_trigger_distance: float = 8.0  # Distância para mostrar prompt de diálogo
var player_in_dialog_area: bool = false
var dialog_active: bool = false
var first_encounter: bool = true
var confrontation_dialog_completed: bool = false
var victory_dialog_completed: bool = false
var interaction_prompt: Node3D = null
var dialog_area: Area3D = null

# Referência ao sistema de diálogo
var dialog_system_scene = preload("res://scenes/ui/dialog_system.tscn")

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
signal dialog_started
signal dialog_finished

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
	dialog_started.connect(_on_dialog_started)
	dialog_finished.connect(_on_dialog_finished)
	
	# Procura pela barra de vida do boss
	_setup_boss_health_bar()
	
	# Configura sistema de diálogo
	_setup_dialog_system()
	
	# Emite sinal inicial de vida
	emit_signal("boss_health_changed", current_health, max_health)

func _setup_boss_health_bar():
	# Não mostra a barra de vida imediatamente - apenas prepara a referência
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager:
		print("🎯 Sistema de barra de vida do boss encontrado - aguardando primeiro diálogo")
	else:
		print("⚠️ Sistema de barra de vida do boss não encontrado")

func _show_boss_health_bar_after_dialog():
	"""Mostra a barra de vida do boss após o primeiro diálogo terminar"""
	print("👑 Mostrando barra de vida do boss após diálogo de confronto")
	
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager and ui_manager.has_method("show_boss_health_bar"):
		ui_manager.show_boss_health_bar("Chefe da Negação", max_health)
		boss_health_bar = ui_manager.get_boss_health_bar()
		print("✅ Barra de vida do boss mostrada com sucesso!")
	else:
		print("❌ Erro: Sistema de barra de vida do boss não encontrado")

func _setup_dialog_system():
	print("💬 Configurando sistema de diálogo do Boss Negação...")
	
	# Cria área de diálogo ao redor do boss
	dialog_area = Area3D.new()
	dialog_area.name = "DialogArea"
	add_child(dialog_area)
	
	# Configura colisão da área de diálogo
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = dialog_trigger_distance
	collision_shape.shape = sphere_shape
	dialog_area.add_child(collision_shape)
	
	# Conecta sinais da área de diálogo
	dialog_area.body_entered.connect(_on_dialog_area_entered)
	dialog_area.body_exited.connect(_on_dialog_area_exited)
	
	# Obtém referência ao prompt de interação da cena
	interaction_prompt = get_node_or_null("InteractionPrompt")
	if not interaction_prompt:
		_create_interaction_prompt()
	
	print("✅ Sistema de diálogo configurado com sucesso!")

func _create_interaction_prompt():
	# Cria um Label3D para mostrar o prompt de interação
	interaction_prompt = Label3D.new()
	interaction_prompt.name = "InteractionPrompt"
	interaction_prompt.text = "Pressione E para conversar\ncom o Chefe da Negação"
	interaction_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	interaction_prompt.font_size = 24
	# Usar outline_size sem outline_color (Godot 4 compatibility)
	interaction_prompt.outline_size = 4
	interaction_prompt.modulate = Color(1, 0.8, 0.4, 1)  # Cor dourada
	interaction_prompt.position = Vector3(0, 6, 0)  # Acima do boss
	interaction_prompt.visible = false
	add_child(interaction_prompt)

func _physics_process(delta):
	# Atualiza timers dos ataques especiais (apenas se não estiver em diálogo)
	if not dialog_active:
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
	# Método de compatibilidade - chama o método com crítico como false
	take_damage_with_critical(amount, false)

func take_damage_with_critical(amount: int, is_critical: bool = false):
	if is_dying or dialog_active:
		return
	
	# Boss resiste a dano durante estado de negação
	if is_in_denial_state:
		amount = int(amount * 0.3)  # Reduz dano em 70%
		if is_critical:
			print("🛡️ Boss em estado de negação! Dano crítico reduzido para: ", amount)
		else:
			print("🛡️ Boss em estado de negação! Dano reduzido para: ", amount)
	
	current_health -= amount
	
	if is_critical:
		print("👑💥 BOSS tomou DANO CRÍTICO de ", amount, "! Vida restante: ", current_health, "/", max_health)
	else:
		print("👑 BOSS tomou ", amount, " de dano! Vida restante: ", current_health, "/", max_health)
	
	# Emite sinal de mudança de vida
	emit_signal("boss_health_changed", current_health, max_health)
	
	# Mostra label de dano (maior para boss)
	if damage_label_scene:
		var label = damage_label_scene.instantiate()
		add_child(label)
		label.setup(amount, true, is_critical)
		label.scale = Vector3(1.5, 1.5, 1.5)  # Label maior para boss
	
	# Efeito visual de dano mais intenso para críticos
	var flash_color = Vector4(1.0, 0.0, 0.0, 1.0)  # Vermelho normal
	var flash_duration = 0.3
	
	if is_critical:
		flash_color = Vector4(1.0, 1.0, 0.0, 1.0)  # Amarelo para crítico
		flash_duration = 0.6  # Boss dura ainda mais tempo
	
	if ghost_cylinder:
		var original_color = ghost_cylinder.material.get_shader_parameter("ghost_color")
		ghost_cylinder.material.set_shader_parameter("ghost_color", flash_color)
		await get_tree().create_timer(flash_duration).timeout
		ghost_cylinder.material.set_shader_parameter("ghost_color", original_color)
	
	# Chance aumentada de entrar em estado de negação quando recebe dano crítico
	var denial_chance = 0.25  # 25% chance normal
	if is_critical:
		denial_chance = 0.5  # 50% chance com dano crítico
	
	if not is_in_denial_state and randf() < denial_chance:
		if is_critical:
			print("🛡️💥 Boss ENFURECIDO pelo dano crítico! Entrando em estado de negação!")
		_enter_denial_state()
	
	# Verifica mudança de fase
	_check_phase_change()
	
	# Verifica se morreu
	if current_health <= 0:
		if is_critical:
			print("👑💥 CHEFE DA NEGAÇÃO FOI ANIQUILADO COM DANO CRÍTICO!")
		else:
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
	print("👑 BOSS DA NEGAÇÃO DERROTADO - INICIANDO DIÁLOGO DE SUPERAÇÃO...")
	
	# Remove todos os fantasmas invocados
	for ghost in summoned_ghosts:
		if is_instance_valid(ghost):
			ghost.queue_free()
	summoned_ghosts.clear()
	
	# Efeito especial de "morte" do boss (mas não remove ainda)
	await _boss_death_sequence()
	
	# Inicia o diálogo de superação final
	start_boss_victory_dialog()
	
	# Aguarda o diálogo de vitória terminar antes de finalizar
	await dialog_finished
	
	# Concede muitos pontos de lucidez
	var lucidity_manager = get_node("/root/LucidityManager")
	if lucidity_manager:
		lucidity_manager.add_lucidity_point(15)  # 15 pontos por completar o arco da negação!
		print("🎯 NEGAÇÃO SUPERADA! +15 pontos de lucidez concedidos!")
	
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

# === SISTEMA DE DIÁLOGO ===
func _on_dialog_area_entered(body):
	if body.is_in_group("player") and not confrontation_dialog_completed and not dialog_active:
		player_in_dialog_area = true
		player_ref = body
		print("💬 Jogador entrou na área de diálogo do Boss Negação")
		
		# Inicia o diálogo automaticamente (sem precisar pressionar E)
		call_deferred("start_boss_confrontation_dialog")

func _on_dialog_area_exited(body):
	if body.is_in_group("player"):
		player_in_dialog_area = false
		if interaction_prompt and is_instance_valid(interaction_prompt):
			interaction_prompt.visible = false
		print("💬 Jogador saiu da área de diálogo do Boss Negação")

func start_boss_confrontation_dialog():
	if dialog_active or confrontation_dialog_completed:
		return
	
	print("💬 Iniciando diálogo com o Boss da Negação...")
	dialog_active = true
	first_encounter = false
	
	# Esconde o prompt de interação
	if interaction_prompt and is_instance_valid(interaction_prompt):
		interaction_prompt.visible = false
	
	# Pausa o jogador
	if player_ref:
		player_ref.set_physics_process(false)
		player_ref.set_process_input(false)
		print("💬 Jogador pausado para diálogo com boss")
	
	# Esconde a HUD principal
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager and ui_manager.hud_instance and is_instance_valid(ui_manager.hud_instance):
		ui_manager.hud_instance.visible = false
		print("💬 HUD escondida para diálogo")
	
	# Cria e mostra o sistema de diálogo
	var dialog_instance = dialog_system_scene.instantiate()
	if not dialog_instance:
		print("💬 ERRO: Falha ao instanciar sistema de diálogo!")
		return
	
	get_tree().current_scene.add_child(dialog_instance)
	
	# Conecta o sinal de fim do diálogo
	dialog_instance.connect("dialog_sequence_finished", _on_boss_confrontation_finished)
	
	# Pausa o jogo
	get_tree().paused = true
	
	# Inicia os diálogos específicos do boss (confronto)
	dialog_instance.start_denial_boss_confrontation_dialog()
	
	# Libera o cursor
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Emite sinal
	emit_signal("dialog_started")
	
	print("💬 Diálogo com Boss da Negação iniciado com sucesso!")

func _on_boss_confrontation_finished():
	print("💬 Diálogo de confronto com Boss da Negação finalizado")
	
	dialog_active = false
	confrontation_dialog_completed = true
	
	# Libera o jogador
	if player_ref:
		player_ref.set_physics_process(true)
		player_ref.set_process_input(true)
	
	# Mostra a HUD principal
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager and ui_manager.hud_instance and is_instance_valid(ui_manager.hud_instance):
		ui_manager.hud_instance.visible = true
		print("💬 HUD restaurada após diálogo")
	
	# Despausa o jogo
	get_tree().paused = false
	
	# Restaura o modo do cursor
	if player_ref and player_ref.has_method("get") and player_ref.get("first_person_mode"):
		if player_ref.first_person_mode:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Emite sinal
	emit_signal("dialog_finished")
	
	print("💬 Boss da Negação agora está pronto para o combate!")

func _on_dialog_started():
	print("💬 Sinal de início de diálogo recebido")

func start_boss_victory_dialog():
	if dialog_active or victory_dialog_completed:
		return
	
	print("💬 Iniciando diálogo de superação com o Boss da Negação...")
	dialog_active = true
	
	# Pausa o jogador
	if player_ref:
		player_ref.set_physics_process(false)
		player_ref.set_process_input(false)
		print("💬 Jogador pausado para diálogo de superação")
	
	# Esconde a HUD principal
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager and ui_manager.hud_instance and is_instance_valid(ui_manager.hud_instance):
		ui_manager.hud_instance.visible = false
		print("💬 HUD escondida para diálogo")
	
	# Cria e mostra o sistema de diálogo
	var dialog_instance = dialog_system_scene.instantiate()
	if not dialog_instance:
		print("💬 ERRO: Falha ao instanciar sistema de diálogo!")
		return
	
	get_tree().current_scene.add_child(dialog_instance)
	
	# Conecta o sinal de fim do diálogo
	dialog_instance.connect("dialog_sequence_finished", _on_boss_victory_finished)
	
	# Pausa o jogo
	get_tree().paused = true
	
	# Inicia os diálogos de superação
	dialog_instance.start_denial_boss_victory_dialog()
	
	# Libera o cursor
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	print("💬 Diálogo de superação iniciado com sucesso!")

func _on_boss_victory_finished():
	print("💬 Diálogo de superação finalizado - NEGAÇÃO SUPERADA!")
	
	dialog_active = false
	victory_dialog_completed = true
	
	# Libera o jogador
	if player_ref:
		player_ref.set_physics_process(true)
		player_ref.set_process_input(true)
	
	# Mostra a HUD principal
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager and ui_manager.hud_instance and is_instance_valid(ui_manager.hud_instance):
		ui_manager.hud_instance.visible = true
		print("💬 HUD restaurada após diálogo de superação")
	
	# Despausa o jogo
	get_tree().paused = false
	
	# Restaura o modo do cursor
	if player_ref and player_ref.has_method("get") and player_ref.get("first_person_mode"):
		if player_ref.first_person_mode:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Emite sinal para finalizar sequência
	emit_signal("dialog_finished")
	
	print("💬 Protagonista superou o primeiro estágio do luto!")

func _on_dialog_finished():
	print("💬 Sinal de fim de diálogo recebido")
	
	# AGORA MOSTRA A BARRA DE VIDA DO BOSS APÓS O PRIMEIRO DIÁLOGO
	_show_boss_health_bar_after_dialog()
	
	# Após o diálogo de confronto, o boss se enfraquece significativamente
	# Representa que aceitar a verdade diminui o poder da negação
	current_health = max_health * 0.3  # Fica com apenas 30% da vida
	emit_signal("boss_health_changed", current_health, max_health)
	print("💬 Boss da Negação enfraquecido pela aceitação da verdade!")
	
	# Muda a aparência para mostrar que foi "derrotado" pelo diálogo
	if ghost_cylinder and ghost_cylinder.material is ShaderMaterial:
		ghost_cylinder.material.set_shader_parameter("ghost_color", Vector4(0.3, 0.6, 0.3, 0.6))
		ghost_cylinder.material.set_shader_parameter("fuwafuwa_speed", 1.0)
	
	# Remove os fantasmas invocados já que o boss está enfraquecido
	for ghost in summoned_ghosts:
		if is_instance_valid(ghost):
			ghost.queue_free()
	summoned_ghosts.clear()
	
	# Remove a área de diálogo já que não será mais necessária
	if dialog_area and is_instance_valid(dialog_area):
		dialog_area.queue_free()
		dialog_area = null
	
	# Remove o prompt de interação
	if interaction_prompt and is_instance_valid(interaction_prompt):
		interaction_prompt.queue_free()
		interaction_prompt = null
	
	print("💬 Área de diálogo removida - Boss pronto para combate final!")
