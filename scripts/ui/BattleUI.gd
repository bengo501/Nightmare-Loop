extends Control

# Referências aos painéis principais
@onready var main_commands = $MainCommands
@onready var skill_commands = $SkillCommands
@onready var talk_commands = $TalkCommands
@onready var gift_commands = $GiftCommands
@onready var status_panel = $StatusPanel
@onready var turn_indicator = $TurnIndicator

# Referências aos botões principais
@onready var skill_button = $MainCommands/SkillButton
@onready var talk_button = $MainCommands/TalkButton
@onready var gift_button = $MainCommands/GiftButton
@onready var flee_button = $MainCommands/FleeButton
@onready var next_button = $MainCommands/NextButton

# Referências aos botões de skill
@onready var damage_boost_button = $SkillCommands/DamageBoostButton
@onready var heal_button = $SkillCommands/HealButton
@onready var gift_boost_button = $SkillCommands/GiftBoostButton
@onready var back_from_skills_button = $SkillCommands/BackButton

# Referências aos botões de talk
@onready var talk_option1_button = $TalkCommands/TalkOption1
@onready var talk_option2_button = $TalkCommands/TalkOption2
@onready var talk_option3_button = $TalkCommands/TalkOption3
@onready var back_from_talk_button = $TalkCommands/BackButton

# Referências aos botões de gift
@onready var negacao_button = $GiftCommands/NegacaoButton
@onready var raiva_button = $GiftCommands/RaivaButton
@onready var barganha_button = $GiftCommands/BarganhaButton
@onready var depressao_button = $GiftCommands/DepressaoButton
@onready var aceitacao_button = $GiftCommands/AceitacaoButton
@onready var back_from_gifts_button = $GiftCommands/BackButton

# Referências aos painéis de status
@onready var player_status = $StatusPanel/PlayerStatus
@onready var enemy_status = $StatusPanel/EnemyStatus

# Referência ao indicador de turno
@onready var turn_label = $TurnIndicator/TurnLabel

# Referência ao BattleManager
var battle_manager = null

# Referência ao BattleData
@onready var battle_data = get_node("/root/BattleData")

# Cena da label de dano
var damage_label_scene = preload("res://scenes/ui/DamageLabel.tscn")

func _ready():
	# Conecta os sinais dos botões principais
	skill_button.pressed.connect(_on_skill_pressed)
	talk_button.pressed.connect(_on_talk_pressed)
	gift_button.pressed.connect(_on_gift_pressed)
	flee_button.pressed.connect(_on_flee_pressed)
	next_button.pressed.connect(_on_next_pressed)
	
	# Conecta os sinais dos botões de skill
	damage_boost_button.pressed.connect(_on_damage_boost_pressed)
	heal_button.pressed.connect(_on_heal_pressed)
	gift_boost_button.pressed.connect(_on_gift_boost_pressed)
	back_from_skills_button.pressed.connect(_on_back_from_skills_pressed)
	
	# Conecta os sinais dos botões de talk
	talk_option1_button.pressed.connect(_on_talk_option1_pressed)
	talk_option2_button.pressed.connect(_on_talk_option2_pressed)
	talk_option3_button.pressed.connect(_on_talk_option3_pressed)
	back_from_talk_button.pressed.connect(_on_back_from_talk_pressed)
	
	# Conecta os sinais dos botões de gift
	negacao_button.pressed.connect(_on_negacao_pressed)
	raiva_button.pressed.connect(_on_raiva_pressed)
	barganha_button.pressed.connect(_on_barganha_pressed)
	depressao_button.pressed.connect(_on_depressao_pressed)
	aceitacao_button.pressed.connect(_on_aceitacao_pressed)
	back_from_gifts_button.pressed.connect(_on_back_from_gifts_pressed)
	
	# Inicializa mostrando apenas os comandos principais
	show_main_commands()

# Funções para mostrar/esconder painéis
func show_main_commands():
	$MainCommands.visible = true
	$SkillCommands.visible = false
	$TalkCommands.visible = false
	$GiftCommands.visible = false
	$StatusPanel.visible = true
	$TurnIndicator.visible = true

func show_skill_commands():
	$MainCommands.visible = false
	$SkillCommands.visible = true
	$TalkCommands.visible = false
	$GiftCommands.visible = false
	$StatusPanel.visible = true
	$TurnIndicator.visible = true

func show_talk_commands():
	$MainCommands.visible = false
	$SkillCommands.visible = false
	$TalkCommands.visible = true
	$GiftCommands.visible = false
	$StatusPanel.visible = true
	$TurnIndicator.visible = true

func show_gift_commands():
	$MainCommands.visible = false
	$SkillCommands.visible = false
	$TalkCommands.visible = false
	$GiftCommands.visible = true
	$StatusPanel.visible = true
	$TurnIndicator.visible = true

func hide_all_interface():
	$MainCommands.visible = false
	$SkillCommands.visible = false
	$TalkCommands.visible = false
	$GiftCommands.visible = false
	$StatusPanel.visible = false
	$TurnIndicator.visible = false

func update_status():
	if not battle_manager:
		return
		
	if player_status:
		player_status.text = "HP: %d/%d\nMP: %d/%d" % [
			battle_manager.player_stats.hp,
			battle_manager.player_stats.max_hp,
			battle_manager.player_stats.mp,
			battle_manager.player_stats.max_mp
		]
	if enemy_status:
		enemy_status.text = "HP: %d/%d" % [
			battle_manager.ghost_stats.hp,
			battle_manager.ghost_stats.max_hp
		]

func update_turn_indicator():
	if not battle_manager:
		return
		
	turn_label.text = "Seu Turno" if battle_manager.is_player_turn else "Turno do Fantasma"
	turn_label.modulate = Color(0, 1, 0) if battle_manager.is_player_turn else Color(1, 0, 0)

# Handlers dos sinais do BattleManager
func _on_player_turn_started():
	update_turn_indicator()
	show_main_commands()

func _on_ghost_turn_started():
	update_turn_indicator()

func _on_battle_ended(victory):
	hide_all_interface()
	# O UiManager irá gerenciar a transição para a próxima tela

# Handlers dos botões principais
func _on_skill_pressed():
	show_skill_commands()

func _on_talk_pressed():
	show_talk_commands()

func _on_gift_pressed():
	show_gift_commands()

func _on_flee_pressed():
	hide_all_interface()

func _on_next_pressed():
	hide_all_interface()

# Handlers dos botões de skill
func _on_damage_boost_pressed():
	hide_all_interface()

func _on_heal_pressed():
	hide_all_interface()

func _on_gift_boost_pressed():
	hide_all_interface()

func _on_back_from_skills_pressed():
	show_main_commands()

# Handlers dos botões de talk
func _on_talk_option1_pressed():
	hide_all_interface()

func _on_talk_option2_pressed():
	hide_all_interface()

func _on_talk_option3_pressed():
	hide_all_interface()

func _on_back_from_talk_pressed():
	show_main_commands()

# Handlers dos botões de gift
func _on_negacao_pressed():
	hide_all_interface()

func _on_raiva_pressed():
	hide_all_interface()

func _on_barganha_pressed():
	hide_all_interface()

func _on_depressao_pressed():
	hide_all_interface()

func _on_aceitacao_pressed():
	hide_all_interface()

func _on_back_from_gifts_pressed():
	show_main_commands()

func show_damage_label(damage: int, is_damage: bool = true):
	var label = damage_label_scene.instantiate()
	add_child(label)
	label.setup(damage, is_damage)
	# Posiciona a label na parte superior da UI
	label.position = Vector3(get_viewport_rect().size.x / 2, 100, 0) 
