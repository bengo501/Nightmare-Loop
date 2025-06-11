extends Control

signal flee_pressed
signal skill_pressed
signal skill_selected(skill_data)
signal talk_pressed
signal gift_pressed
signal gift_selected(gift_id)
signal next_pressed

# Referências aos botões principais
@onready var skill_button = $CommandBar/SkillButton
@onready var talk_button = $CommandBar/TalkButton
@onready var gift_button = $CommandBar/GiftButton
@onready var flee_button = $CommandBar/FleeButton
@onready var next_button = $CommandBar/NextButton

# Referências aos painéis de status
@onready var player_status = $StatusPanel/PlayerStatus
@onready var enemy_status = $StatusPanel/EnemyStatus

# Referência ao indicador de turno
@onready var turn_label = $TurnIndicator/TurnLabel

func _ready():
	# Conecta os sinais dos botões
	skill_button.pressed.connect(_on_skill_pressed)
	talk_button.pressed.connect(_on_talk_pressed)
	gift_button.pressed.connect(_on_gift_pressed)
	flee_button.pressed.connect(_on_flee_pressed)
	next_button.pressed.connect(_on_next_pressed)

func update_status(player_hp: int, player_max_hp: int, player_mp: int, player_max_mp: int,
				 enemy_hp: int, enemy_max_hp: int):
	if player_status:
		player_status.update_hp(player_hp, player_max_hp)
		player_status.update_mp(player_mp, player_max_mp)
	if enemy_status:
		enemy_status.update_hp(enemy_hp, enemy_max_hp)

func update_turn_indicator(is_player_turn: bool):
	turn_label.text = "Seu Turno" if is_player_turn else "Turno do Fantasma"
	turn_label.modulate = Color(0, 1, 0) if is_player_turn else Color(1, 0, 0)

func _on_skill_pressed():
	skill_pressed.emit()

func _on_talk_pressed():
	talk_pressed.emit()

func _on_gift_pressed():
	gift_pressed.emit()

func _on_flee_pressed():
	flee_pressed.emit()

func _on_next_pressed():
	next_pressed.emit() 