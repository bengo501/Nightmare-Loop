extends Control

# Referências visuais
@onready var background = $Background
@onready var ghost_sprite = $GhostSprite

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

func _ready():
	# Busca o BattleManager diretamente na root
	if get_tree().has_node("/root/BattleManager"):
		battle_manager = get_node("/root/BattleManager")
		battle_manager.player_turn_started.connect(_on_player_turn_started)
		battle_manager.ghost_turn_started.connect(_on_ghost_turn_started)
		battle_manager.battle_ended.connect(_on_battle_ended)
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

	show_main_commands()
	update_status()
	update_turn_indicator()

# === VISIBILIDADE DOS PAINÉIS ===
func show_main_commands():
	main_commands.visible = true
	skill_commands.visible = false
	talk_commands.visible = false
	gift_commands.visible = false
	status_panel.visible = true
	turn_indicator.visible = true

func show_skill_commands():
	main_commands.visible = false
	skill_commands.visible = true
	talk_commands.visible = false
	gift_commands.visible = false

func show_talk_commands():
	main_commands.visible = false
	skill_commands.visible = false
	talk_commands.visible = true
	gift_commands.visible = false

func show_gift_commands():
	main_commands.visible = false
	skill_commands.visible = false
	talk_commands.visible = false
	gift_commands.visible = true

func hide_all_interface():
	main_commands.visible = false
	skill_commands.visible = false
	talk_commands.visible = false
	gift_commands.visible = false
	status_panel.visible = false
	turn_indicator.visible = false

# === STATUS ===
func update_status():
	if not battle_manager:
		return
	player_status.text = "HP: %d/%d\nMP: %d/%d" % [
		battle_manager.player_stats.hp,
		battle_manager.player_stats.max_hp,
		battle_manager.player_stats.mp,
		battle_manager.player_stats.max_mp
	]
	enemy_status.text = "HP: %d/%d" % [
		battle_manager.ghost_stats.hp,
		battle_manager.ghost_stats.max_hp
	]

func update_turn_indicator():
	if not battle_manager:
		return
	turn_label.text = "Seu Turno" if battle_manager.is_player_turn else "Turno do Fantasma"
	turn_label.modulate = Color(0, 1, 0) if battle_manager.is_player_turn else Color(1, 0, 0)

# === HANDLERS DOS TURNOS ===
func _on_player_turn_started():
	update_turn_indicator()
	update_status()
	show_main_commands()

func _on_ghost_turn_started():
	update_turn_indicator()
	update_status()

func _on_battle_ended(victory):
	hide_all_interface()

# === BOTÕES PRINCIPAIS ===
func _on_skill_pressed():
	show_skill_commands()

func _on_talk_pressed():
	show_talk_commands()

func _on_gift_pressed():
	show_gift_commands()

func _on_flee_pressed():
	if battle_manager:
		battle_manager.player_flee()
	hide_all_interface()

func _on_next_pressed():
	if battle_manager:
		battle_manager.end_player_turn()
	hide_all_interface()

# === BOTÕES DE SKILL ===
func _on_damage_boost_pressed():
	if battle_manager:
		battle_manager.use_damage_boost()
	hide_all_interface()

func _on_heal_pressed():
	if battle_manager:
		battle_manager.use_heal()
	hide_all_interface()

func _on_gift_boost_pressed():
	if battle_manager:
		battle_manager.use_gift_boost()
	hide_all_interface()

func _on_back_from_skills_pressed():
	show_main_commands()

# === BOTÕES DE TALK ===
func _on_talk_option1_pressed():
	if battle_manager:
		battle_manager.use_talk_option(1)
	hide_all_interface()

func _on_talk_option2_pressed():
	if battle_manager:
		battle_manager.use_talk_option(2)
	hide_all_interface()

func _on_talk_option3_pressed():
	if battle_manager:
		battle_manager.use_talk_option(3)
	hide_all_interface()

func _on_back_from_talk_pressed():
	show_main_commands()

# === BOTÕES DE GIFT ===
func _on_negacao_pressed():
	if battle_manager:
		battle_manager.use_gift("negacao")
	hide_all_interface()

func _on_raiva_pressed():
	if battle_manager:
		battle_manager.use_gift("raiva")
	hide_all_interface()

func _on_barganha_pressed():
	if battle_manager:
		battle_manager.use_gift("barganha")
	hide_all_interface()

func _on_depressao_pressed():
	if battle_manager:
		battle_manager.use_gift("depressao")
	hide_all_interface()

func _on_aceitacao_pressed():
	if battle_manager:
		battle_manager.use_gift("aceitacao")
	hide_all_interface()

func _on_back_from_gifts_pressed():
	show_main_commands() 