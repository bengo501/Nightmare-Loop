extends Control

# Sinal para quando uma habilidade for melhorada
signal skill_upgraded(branch, level)

# Pontos de habilidade do jogador
var skill_points := 3
var is_visible := false

func _ready():
	# Atualiza o texto dos pontos de habilidade
	$Panel/SkillPoints.text = "Pontos de Habilidade: %d" % skill_points

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

func _input(event):
	if event.is_action_pressed("skill_tree"):
		toggle_skill_tree()

func toggle_skill_tree():
	if is_visible:
		hide()
		get_tree().paused = false
		is_visible = false
		# Mostra a HUD do player se existir
		var hud = get_node_or_null("/root/UIManager/hud_instance")
		if hud:
			hud.visible = true
	else:
		show()
		move_to_front()
		get_tree().paused = true
		is_visible = true
		# Esconde a HUD do player se existir
		var hud = get_node_or_null("/root/UIManager/hud_instance")
		if hud:
			hud.visible = false

func _on_close_pressed():
	hide()
	get_tree().paused = false
	is_visible = false

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

# Função para melhorar uma habilidade
func _upgrade_skill(branch: String, level: int):
	if skill_points > 0:
		skill_points -= 1
		$Panel/SkillPoints.text = "Pontos de Habilidade: %d" % skill_points
		emit_signal("skill_upgraded", branch, level)
		# Aqui você pode adicionar lógica para desabilitar o botão, aplicar efeito, etc.
	else:
		# Sem pontos suficientes
		print("Sem pontos de habilidade!")

# Função para mostrar o menu (pode ser chamada pelo UIManager)
func show_menu():
	show()
	move_to_front()
	get_tree().paused = true
	$Panel/SkillPoints.text = "Pontos de Habilidade: %d" % skill_points
	# Esconde a HUD do player se existir
	var hud = get_node_or_null("/root/UIManager/hud_instance")
	if hud:
		hud.visible = false
