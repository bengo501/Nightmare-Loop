extends Control

signal flee_pressed
signal skill_pressed
signal skill_selected(skill_data)
signal item_pressed
signal item_selected(item_id)
signal talk_pressed
signal talk_option_selected(option_id)
signal gift_pressed
signal gift_selected(gift_id)
signal next_pressed

# Referências aos submenus
@onready var skill_menu = $SubMenus/SkillMenu
@onready var item_menu = $SubMenus/ItemMenu
@onready var talk_menu = $SubMenus/TalkMenu
@onready var gift_menu = $SubMenus/GiftMenu

# Referências aos botões principais
@onready var attack_button = $ActionButtons/AttackButton
@onready var defend_button = $ActionButtons/DefendButton
@onready var special_button = $ActionButtons/SpecialButton
@onready var talk_button = $ActionButtons/TalkButton
@onready var gift_button = $ActionButtons/GiftButton
@onready var item_button = $ActionButtons/ItemButton
@onready var flee_button = $ActionButtons/FleeButton
@onready var next_button = $ActionButtons/NextButton

# Referências aos painéis de status
@onready var player_status = $StatusPanel/PlayerStatus
@onready var enemy_status = $StatusPanel/EnemyStatus

func _ready():
	# Conecta os sinais dos botões principais
	attack_button.pressed.connect(_on_attack_pressed)
	defend_button.pressed.connect(_on_defend_pressed)
	special_button.pressed.connect(_on_special_pressed)
	talk_button.pressed.connect(_on_talk_pressed)
	gift_button.pressed.connect(_on_gift_pressed)
	item_button.pressed.connect(_on_item_pressed)
	flee_button.pressed.connect(_on_flee_pressed)
	next_button.pressed.connect(_on_next_pressed)
	
	# Inicializa os submenus como invisíveis
	hide_all_submenus()

func hide_all_submenus():
	skill_menu.visible = false
	item_menu.visible = false
	talk_menu.visible = false
	gift_menu.visible = false

func show_skill_menu():
	hide_all_submenus()
	skill_menu.visible = true
	skill_menu.populate_skills() # Implementar este método no SkillMenu

func show_item_menu():
	hide_all_submenus()
	item_menu.visible = true
	item_menu.populate_items() # Implementar este método no ItemMenu

func show_talk_menu():
	hide_all_submenus()
	talk_menu.visible = true
	talk_menu.populate_options() # Implementar este método no TalkMenu

func show_gift_menu():
	hide_all_submenus()
	gift_menu.visible = true
	gift_menu.populate_gifts() # Implementar este método no GiftMenu

func update_status(player_hp: int, player_max_hp: int, player_mp: int, player_max_mp: int,
				 enemy_hp: int, enemy_max_hp: int, enemy_mp: int, enemy_max_mp: int):
	if player_status:
		player_status.update_hp(player_hp, player_max_hp)
		player_status.update_mp(player_mp, player_max_mp)
	if enemy_status:
		enemy_status.update_hp(enemy_hp, enemy_max_hp)
		enemy_status.update_mp(enemy_mp, enemy_max_mp)

func update_turn_icons(turn_count: int, is_player_turn: bool):
	# Implementar atualização dos ícones de turno
	pass

# Handlers dos botões principais
func _on_attack_pressed():
	# Implementar lógica de ataque
	pass

func _on_defend_pressed():
	# Implementar lógica de defesa
	pass

func _on_special_pressed():
	# Implementar lógica de ataque especial
	pass

func _on_talk_pressed():
	talk_pressed.emit()

func _on_gift_pressed():
	gift_pressed.emit()

func _on_item_pressed():
	item_pressed.emit()

func _on_flee_pressed():
	flee_pressed.emit()

func _on_next_pressed():
	next_pressed.emit()

# Handlers dos submenus
func _on_skill_selected(skill_data):
	skill_selected.emit(skill_data)
	hide_all_submenus()

func _on_item_selected(item_id):
	item_selected.emit(item_id)
	hide_all_submenus()

func _on_talk_option_selected(option_id):
	talk_option_selected.emit(option_id)
	hide_all_submenus()

func _on_gift_selected(gift_id):
	gift_selected.emit(gift_id)
	hide_all_submenus() 