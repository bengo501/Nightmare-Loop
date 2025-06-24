extends Control

# Sinal para quando uma habilidade for melhorada
signal skill_upgraded(branch, level)

# Estado da interface
var is_visible := false

# Referências aos managers
@onready var state_manager = get_node("/root/GameStateManager")
@onready var skill_manager = get_node("/root/SkillManager")

func _ready():
	# Conecta aos sinais do SkillManager
	if skill_manager:
		skill_manager.skill_points_changed.connect(_on_skill_points_changed)
	
	# Atualiza o texto dos pontos de habilidade
	update_skill_points_display()

	# Conecta o botão de fechar
	$Panel/CloseButton.pressed.connect(_on_close_pressed)

	# Conecta os botões de cada ramo
	$Panel/ScrollContainer/SkillTreeContainer/SpeedBranch/Speed1.pressed.connect(_on_speed1_pressed)
	$Panel/ScrollContainer/SkillTreeContainer/SpeedBranch/Speed2.pressed.connect(_on_speed2_pressed)
	$Panel/ScrollContainer/SkillTreeContainer/SpeedBranch/Speed3.pressed.connect(_on_speed3_pressed)

	$Panel/ScrollContainer/SkillTreeContainer/DamageBranch/Damage1.pressed.connect(_on_damage1_pressed)
	$Panel/ScrollContainer/SkillTreeContainer/DamageBranch/Damage2.pressed.connect(_on_damage2_pressed)
	$Panel/ScrollContainer/SkillTreeContainer/DamageBranch/Damage3.pressed.connect(_on_damage3_pressed)

	$Panel/ScrollContainer/SkillTreeContainer/HealthBranch/Health1.pressed.connect(_on_health1_pressed)
	$Panel/ScrollContainer/SkillTreeContainer/HealthBranch/Health2.pressed.connect(_on_health2_pressed)
	$Panel/ScrollContainer/SkillTreeContainer/HealthBranch/Health3.pressed.connect(_on_health3_pressed)

	hide()
	set_process_input(true)

# Input removido - agora controlado pela TV
# func _input(event):
# 	if event.is_action_pressed("skill_tree"):
# 		toggle_skill_tree()

func toggle_skill_tree():
	if is_visible:
		hide()
		get_tree().paused = false
		is_visible = false
		state_manager.change_state(state_manager.GameState.PLAYING)
		# Mostra a HUD do player se existir
		var hud = get_node_or_null("/root/UIManager/hud_instance")
		if hud and is_instance_valid(hud):
			hud.visible = true
	else:
		show()
		get_tree().paused = true
		is_visible = true
		state_manager.change_state(state_manager.GameState.SKILL_TREE)
		# Esconde a HUD do player se existir
		var hud = get_node_or_null("/root/UIManager/hud_instance")
		if hud and is_instance_valid(hud):
			hud.visible = false

func _on_close_pressed():
	hide()
	get_tree().paused = false
	is_visible = false
	state_manager.change_state(state_manager.GameState.PLAYING)
	# Mostra a HUD do player se existir
	var hud = get_node_or_null("/root/UIManager/hud_instance")
	if hud and is_instance_valid(hud):
		hud.visible = true

# Exemplo de handlers para cada botão de skill
func _on_speed1_pressed():
	_upgrade_skill("speed", 1)

func _on_speed2_pressed():
	_upgrade_skill("speed", 2)

func _on_speed3_pressed():
	_upgrade_skill("speed", 3)

func _on_damage1_pressed():
	_upgrade_skill("damage", 1)

func _on_damage2_pressed():
	_upgrade_skill("damage", 2)

func _on_damage3_pressed():
	_upgrade_skill("damage", 3)

func _on_health1_pressed():
	_upgrade_skill("health", 1)

func _on_health2_pressed():
	_upgrade_skill("health", 2)

func _on_health3_pressed():
	_upgrade_skill("health", 3)

# Função para atualizar a exibição dos pontos de habilidade
func update_skill_points_display():
	if skill_manager:
		$Panel/SkillPoints.text = "Pontos de Habilidade: %d" % skill_manager.get_skill_points()

# Callback para quando os pontos de habilidade mudam
func _on_skill_points_changed(new_points: int):
	$Panel/SkillPoints.text = "Pontos de Habilidade: %d" % new_points

# Função para melhorar uma habilidade
func _upgrade_skill(branch: String, level: int):
	if skill_manager and skill_manager.upgrade_skill(branch, level):
		emit_signal("skill_upgraded", branch, level)
		# Aqui você pode adicionar lógica para desabilitar o botão, aplicar efeito, etc.
		update_button_states()
	else:
		# Sem pontos suficientes ou erro
		print("Não foi possível melhorar a habilidade!")

# Atualiza o estado dos botões baseado nas habilidades disponíveis
func update_button_states():
	if not skill_manager:
		return
	
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

# Atualiza um botão específico de habilidade
func update_skill_button(branch: String, level: int, button: Button):
	if not skill_manager or not button:
		return
	
	var current_level = skill_manager.get_skill_level(branch)
	var can_upgrade = skill_manager.can_upgrade_skill(branch, level)
	
	if current_level >= level:
		# Habilidade já adquirida
		button.disabled = true
		button.text = button.text.replace("(", "(ADQUIRIDO) (")
	elif can_upgrade:
		# Pode ser adquirida
		button.disabled = false
	else:
		# Não pode ser adquirida ainda
		button.disabled = true

# Função para mostrar o menu (pode ser chamada pelo UIManager)
func show_menu():
	show()
	get_tree().paused = true
	is_visible = true
	state_manager.change_state(state_manager.GameState.SKILL_TREE)
	update_skill_points_display()
	update_button_states()
	# Esconde a HUD do player se existir
	var hud = get_node_or_null("/root/UIManager/hud_instance")
	if hud and is_instance_valid(hud):
		hud.visible = false
