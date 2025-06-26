extends Control

# Sinal para quando uma habilidade for melhorada
signal skill_upgraded(branch, level)
signal skill_tree_closed

# Estado da interface
var is_visible := false
var is_tv_mode := false  # Novo: indica se está sendo usado na TV

# Referências aos managers
@onready var state_manager = get_node("/root/GameStateManager")
@onready var skill_manager = get_node("/root/SkillManager")

# Cores para os botões
var button_colors = {
	"available": Color(0.2, 0.8, 0.2, 1.0),      # Verde para disponível
	"locked": Color(0.5, 0.5, 0.5, 1.0),         # Cinza para bloqueado
	"acquired": Color(0.1, 0.3, 0.8, 1.0),       # Azul para adquirido
	"insufficient": Color(0.8, 0.4, 0.2, 1.0)    # Laranja para sem pontos
}

func _ready():
	print("[SkillTree] Inicializando skill tree...")
	
	# Verifica se está sendo usado na TV
	is_tv_mode = get_parent().name == "TV_fbx_Scene"
	if is_tv_mode:
		print("[SkillTree] Modo TV detectado")
	
	# Conecta aos sinais do SkillManager
	if skill_manager:
		skill_manager.skill_points_changed.connect(_on_skill_points_changed)
		skill_manager.skill_upgraded.connect(_on_skill_manager_upgraded)
		print("[SkillTree] ✓ Conectado ao SkillManager")
	else:
		print("[SkillTree] ❌ SkillManager não encontrado!")
	
	# Atualiza o texto dos pontos de habilidade
	update_skill_points_display()

	# Conecta o botão de fechar
	var close_button = $Panel/CloseButton
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
		print("[SkillTree] ✓ Botão X conectado")
	else:
		print("[SkillTree] ❌ Botão X não encontrado!")

	# Conecta os botões de cada ramo
	setup_skill_buttons()

	hide()
	set_process_input(true)
	print("[SkillTree] Skill tree inicializada com sucesso")

func setup_skill_buttons():
	print("[SkillTree] Configurando botões de habilidades...")
	
	# Conecta botões de velocidade
	var speed1 = $Panel/ScrollContainer/SkillTreeContainer/SpeedBranch/Speed1
	var speed2 = $Panel/ScrollContainer/SkillTreeContainer/SpeedBranch/Speed2
	var speed3 = $Panel/ScrollContainer/SkillTreeContainer/SpeedBranch/Speed3
	
	if speed1: speed1.pressed.connect(_on_speed1_pressed)
	if speed2: speed2.pressed.connect(_on_speed2_pressed)
	if speed3: speed3.pressed.connect(_on_speed3_pressed)

	# Conecta botões de dano
	var damage1 = $Panel/ScrollContainer/SkillTreeContainer/DamageBranch/Damage1
	var damage2 = $Panel/ScrollContainer/SkillTreeContainer/DamageBranch/Damage2
	var damage3 = $Panel/ScrollContainer/SkillTreeContainer/DamageBranch/Damage3
	
	if damage1: damage1.pressed.connect(_on_damage1_pressed)
	if damage2: damage2.pressed.connect(_on_damage2_pressed)
	if damage3: damage3.pressed.connect(_on_damage3_pressed)

	# Conecta botões de vida
	var health1 = $Panel/ScrollContainer/SkillTreeContainer/HealthBranch/Health1
	var health2 = $Panel/ScrollContainer/SkillTreeContainer/HealthBranch/Health2
	var health3 = $Panel/ScrollContainer/SkillTreeContainer/HealthBranch/Health3
	
	if health1: health1.pressed.connect(_on_health1_pressed)
	if health2: health2.pressed.connect(_on_health2_pressed)
	if health3: health3.pressed.connect(_on_health3_pressed)
	
	print("[SkillTree] ✓ Botões de habilidades conectados")

func _input(event):
	# Permite fechar com ESC quando a skill tree está aberta
	if is_visible and event.is_action_pressed("ui_cancel"):
		print("[SkillTree] ESC pressionado - fechando skill tree")
		_on_close_pressed()
		get_viewport().set_input_as_handled()  # Marca o input como processado

func toggle_skill_tree():
	if is_visible:
		hide_skill_tree()
	else:
		show_skill_tree()

func show_skill_tree():
	print("[SkillTree] Abrindo skill tree...")
	show()
	is_visible = true
	
	# Se não estiver no modo TV, gerencia o pause e estado
	if not is_tv_mode:
		get_tree().paused = true
		if state_manager:
			state_manager.change_state(state_manager.GameState.SKILL_TREE)
			print("[SkillTree] Estado alterado para SKILL_TREE")
		
		# Esconde a HUD do player se existir
		var hud = get_node_or_null("/root/UIManager/hud_instance")
		if not hud:
			hud = get_tree().get_first_node_in_group("hud")
		if hud and is_instance_valid(hud):
			hud.visible = false
			print("[SkillTree] HUD escondida")
		else:
			print("[SkillTree] AVISO: HUD não encontrada")
	
	# Atualiza a interface
	update_skill_points_display()
	update_button_states()
	update_skill_descriptions()
	
	# Garante que o mouse está visível
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	print("[SkillTree] Árvore de habilidades aberta com sucesso")

func hide_skill_tree():
	print("[SkillTree] Fechando skill tree...")
	hide()
	is_visible = false
	
	# Se não estiver no modo TV, gerencia o pause e estado
	if not is_tv_mode:
		get_tree().paused = false
		if state_manager:
			state_manager.change_state(state_manager.GameState.PLAYING)
			print("[SkillTree] Estado alterado para PLAYING")
		
		# Mostra a HUD do player se existir
		var hud = get_node_or_null("/root/UIManager/hud_instance")
		if not hud:
			hud = get_tree().get_first_node_in_group("hud")
		if hud and is_instance_valid(hud):
			hud.visible = true
			print("[SkillTree] HUD restaurada")
		else:
			print("[SkillTree] AVISO: HUD não encontrada para restaurar")
	
	# Emite sinal para notificar que foi fechada (útil para a TV)
	skill_tree_closed.emit()
	
	print("[SkillTree] Árvore de habilidades fechada com sucesso")

func _on_close_pressed():
	print("[SkillTree] Botão X pressionado - fechando skill tree")
	hide_skill_tree()

# Handlers para cada botão de skill
func _on_speed1_pressed():
	print("[SkillTree] Botão Speed1 pressionado")
	_upgrade_skill("speed", 1)

func _on_speed2_pressed():
	print("[SkillTree] Botão Speed2 pressionado")
	_upgrade_skill("speed", 2)

func _on_speed3_pressed():
	print("[SkillTree] Botão Speed3 pressionado")
	_upgrade_skill("speed", 3)

func _on_damage1_pressed():
	print("[SkillTree] Botão Damage1 pressionado")
	_upgrade_skill("damage", 1)

func _on_damage2_pressed():
	print("[SkillTree] Botão Damage2 pressionado")
	_upgrade_skill("damage", 2)

func _on_damage3_pressed():
	print("[SkillTree] Botão Damage3 pressionado")
	_upgrade_skill("damage", 3)

func _on_health1_pressed():
	print("[SkillTree] Botão Health1 pressionado")
	_upgrade_skill("health", 1)

func _on_health2_pressed():
	print("[SkillTree] Botão Health2 pressionado")
	_upgrade_skill("health", 2)

func _on_health3_pressed():
	print("[SkillTree] Botão Health3 pressionado")
	_upgrade_skill("health", 3)

# Função para atualizar a exibição dos pontos de lucidez
func update_skill_points_display():
	if skill_manager:
		var points = skill_manager.get_skill_points()
		$Panel/SkillPoints.text = "Pontos de Lucidez: %d" % points
		
		# Muda a cor baseado na quantidade de pontos
		if points > 0:
			$Panel/SkillPoints.modulate = Color(0.2, 0.8, 1.0)  # Azul ciano (cor da lucidez)
		else:
			$Panel/SkillPoints.modulate = Color(1.0, 0.5, 0.2)  # Laranja
		
		print("[SkillTree] Pontos atualizados na interface: ", points)
	else:
		print("[SkillTree] ERRO: SkillManager não disponível para atualizar pontos")

# Callback para quando os pontos de habilidade mudam
func _on_skill_points_changed(new_points: int):
	print("[SkillTree] Callback: Pontos alterados para ", new_points)
	update_skill_points_display()
	update_button_states()

# Callback para quando uma habilidade é melhorada via SkillManager
func _on_skill_manager_upgraded(branch: String, level: int):
	print("[SkillTree] Habilidade melhorada detectada: ", branch, " nível ", level)
	update_button_states()
	update_skill_descriptions()
	show_upgrade_feedback(branch, level)

# Função para melhorar uma habilidade
func _upgrade_skill(branch: String, level: int):
	print("\n[SkillTree] ====== TENTATIVA DE COMPRA ======")
	print("[SkillTree] Tentando melhorar habilidade: ", branch, " para nível ", level)
	
	if not skill_manager:
		print("[SkillTree] ERRO: SkillManager não encontrado!")
		return
	
	var current_points = skill_manager.get_skill_points()
	var cost = skill_manager.get_skill_cost(branch, level)
	var can_upgrade = skill_manager.can_upgrade_skill(branch, level)
	var current_level = skill_manager.get_skill_level(branch)
	
	print("[SkillTree] Estado atual:")
	print("  - Pontos disponíveis: ", current_points)
	print("  - Custo da habilidade: ", cost)
	print("  - Nível atual: ", current_level)
	print("  - Pode melhorar: ", can_upgrade)
	
	if skill_manager.upgrade_skill(branch, level):
		emit_signal("skill_upgraded", branch, level)
		print("[SkillTree] ✅ COMPRA REALIZADA COM SUCESSO!")
		print("[SkillTree] Nova situação:")
		print("  - Pontos restantes: ", skill_manager.get_skill_points())
		print("  - Novo nível: ", skill_manager.get_skill_level(branch))
		
		# Atualiza a interface imediatamente
		update_skill_points_display()
		update_button_states()
		show_upgrade_feedback(branch, level)
	else:
		print("[SkillTree] ❌ COMPRA FALHOU!")
		# Mostra feedback de erro
		show_error_feedback(branch, level)
	
	print("[SkillTree] ====== FIM DA TENTATIVA ======\n")

# Mostra feedback visual quando uma habilidade é melhorada
func show_upgrade_feedback(branch: String, level: int):
	if not skill_manager:
		return
	
	var skill_name = skill_manager.get_skill_name(branch)
	var description = skill_manager.get_skill_description(branch, level)
	
	print("✅ SUCESSO: ", skill_name, " melhorada para nível ", level, ": ", description)
	
	# Aqui você pode adicionar efeitos visuais como:
	# - Animação do botão
	# - Som de sucesso
	# - Partículas
	# - Popup de confirmação

# Mostra feedback de erro quando não é possível melhorar
func show_error_feedback(branch: String, level: int):
	if not skill_manager:
		return
	
	var cost = skill_manager.get_skill_cost(branch, level)
	var available = skill_manager.get_skill_points()
	var skill_name = skill_manager.get_skill_name(branch)
	var current_level = skill_manager.get_skill_level(branch)
	
	print("❌ ERRO na compra de ", skill_name, ":")
	
	if available < cost:
		print("  - Pontos insuficientes (necessário: ", cost, ", disponível: ", available, ")")
	elif level != current_level + 1:
		print("  - Nível inválido (atual: ", current_level, ", tentando: ", level, ")")
	else:
		print("  - Erro desconhecido")

# Atualiza o estado dos botões baseado nas habilidades disponíveis
func update_button_states():
	if not skill_manager:
		print("[SkillTree] ERRO: SkillManager não disponível para atualizar botões")
		return
	
	print("[SkillTree] Atualizando estado dos botões...")
	
	# Atualiza títulos dos ramos
	update_branch_title("speed", $Panel/ScrollContainer/SkillTreeContainer/SpeedBranch/SpeedTitle)
	update_branch_title("damage", $Panel/ScrollContainer/SkillTreeContainer/DamageBranch/DamageTitle)
	update_branch_title("health", $Panel/ScrollContainer/SkillTreeContainer/HealthBranch/HealthTitle)
	
	# Atualiza botões de velocidade
	update_skill_button("speed", 1, $Panel/ScrollContainer/SkillTreeContainer/SpeedBranch/Speed1)
	update_skill_button("speed", 2, $Panel/ScrollContainer/SkillTreeContainer/SpeedBranch/Speed2)
	update_skill_button("speed", 3, $Panel/ScrollContainer/SkillTreeContainer/SpeedBranch/Speed3)
	
	# Atualiza botões de dano
	update_skill_button("damage", 1, $Panel/ScrollContainer/SkillTreeContainer/DamageBranch/Damage1)
	update_skill_button("damage", 2, $Panel/ScrollContainer/SkillTreeContainer/DamageBranch/Damage2)
	update_skill_button("damage", 3, $Panel/ScrollContainer/SkillTreeContainer/DamageBranch/Damage3)
	
	# Atualiza botões de vida
	update_skill_button("health", 1, $Panel/ScrollContainer/SkillTreeContainer/HealthBranch/Health1)
	update_skill_button("health", 2, $Panel/ScrollContainer/SkillTreeContainer/HealthBranch/Health2)
	update_skill_button("health", 3, $Panel/ScrollContainer/SkillTreeContainer/HealthBranch/Health3)
	
	print("[SkillTree] Estado dos botões atualizado")

# Atualiza o título de um ramo de habilidades
func update_branch_title(branch: String, title_label: Label):
	if not skill_manager or not title_label:
		return
	
	var skill_name = skill_manager.get_skill_name(branch)
	var current_level = skill_manager.get_skill_level(branch)
	
	title_label.text = "%s (Nível %d/3)" % [skill_name, current_level]

# Atualiza um botão específico de habilidade
func update_skill_button(branch: String, level: int, button: Button):
	if not skill_manager or not button:
		return
	
	var current_level = skill_manager.get_skill_level(branch)
	var can_upgrade = skill_manager.can_upgrade_skill(branch, level)
	var cost = skill_manager.get_skill_cost(branch, level)
	var description = skill_manager.get_skill_description(branch, level)
	var available_points = skill_manager.get_skill_points()
	
	# Atualiza o texto do botão
	button.text = "Nível %d (%d pontos)\n%s" % [level, cost, description]
	
	if current_level >= level:
		# Habilidade já adquirida
		button.disabled = true
		button.modulate = button_colors.acquired
		button.text = "Nível %d - ADQUIRIDO\n%s" % [level, description]
	elif can_upgrade:
		# Pode ser adquirida
		button.disabled = false
		button.modulate = button_colors.available
	elif available_points < cost:
		# Sem pontos suficientes
		button.disabled = true
		button.modulate = button_colors.insufficient
	else:
		# Não pode ser adquirida ainda (pré-requisitos)
		button.disabled = true
		button.modulate = button_colors.locked

# Atualiza as descrições das habilidades
func update_skill_descriptions():
	# Esta função pode ser expandida para mostrar descrições detalhadas
	# em tooltips ou painéis laterais
	pass

# Função para mostrar o menu (pode ser chamada pelo UIManager ou TV)
func show_menu():
	show_skill_tree()
