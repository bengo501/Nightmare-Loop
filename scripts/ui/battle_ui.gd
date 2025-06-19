extends CanvasLayer

signal attack_pressed
signal defend_pressed
signal special_pressed
signal item_pressed
signal flee_pressed
signal skill_chosen(skill_data)

@onready var player_hp_label = $MainPanel/StatusPanel/PlayerStatus/PlayerHP
@onready var player_mp_label = $MainPanel/StatusPanel/PlayerStatus/PlayerMP
@onready var enemy_hp_label = $MainPanel/StatusPanel/EnemyStatus/EnemyHP
@onready var turn_indicator = $MainPanel/TurnIndicator
@onready var message_area = $MainPanel/MessageArea
@onready var enemy_sprite = $MainPanel/EnemySprite

@onready var action_buttons = $MainPanel/ActionButtons
@onready var skills_button = $MainPanel/ActionButtons/SkillsButton
@onready var skills_menu = $MainPanel/ActionButtons/SkillsButton/skillsMenu
@onready var skills_menu_atacar = $MainPanel/ActionButtons/SkillsButton/skillsMenu/VBoxContainer/AtacarButton
@onready var skills_menu_presente = $MainPanel/ActionButtons/SkillsButton/skillsMenu/VBoxContainer/PresenteButton

# --- Gifts UI ---
@onready var gifts_panel = $MainPanel/GiftsPanel if has_node("MainPanel/GiftsPanel") else null
@onready var negacao_label = gifts_panel.get_node("NegacaoLabel") if gifts_panel else null
@onready var raiva_label = gifts_panel.get_node("RaivaLabel") if gifts_panel else null
@onready var barganha_label = gifts_panel.get_node("BarganhaLabel") if gifts_panel else null
@onready var depressao_label = gifts_panel.get_node("DepressaoLabel") if gifts_panel else null
@onready var aceitacao_label = gifts_panel.get_node("AceitacaoLabel") if gifts_panel else null

var float_time := 0.0
var enemy_base_y: float = 0.0

func _ready():
	set_action_buttons_enabled(true)
	enemy_sprite.visible = true
	skills_menu.visible = false
	skills_button.pressed.connect(_show_skills_menu)
	skills_menu_atacar.pressed.connect(_on_skills_menu_atacar)
	skills_menu_presente.pressed.connect(_on_skills_menu_presente)

func update_player_status(hp: int, max_hp: int, mp: int, max_mp: int):
	player_hp_label.text = "HP: %d/%d" % [hp, max_hp]
	player_mp_label.text = "MP: %d/%d" % [mp, max_mp]

func update_enemy_status(hp: int, max_hp: int):
	enemy_hp_label.text = "Inimigo HP: %d/%d" % [hp, max_hp]

func update_turn_indicator(is_player_turn: bool):
	if is_player_turn:
		turn_indicator.text = "Seu Turno"
	else:
		turn_indicator.text = "Turno do Inimigo"

func show_message(msg: String):
	message_area.text = msg

func set_action_buttons_enabled(enabled: bool):
	action_buttons.set_buttons_enabled(enabled)

func set_enemy_texture(texture: Texture2D):
	enemy_sprite.texture = texture

func _process(delta):
	# Animação de levitação suave
	float_time += delta
	var float_offset = sin(float_time * 2.0) * 10.0
	enemy_sprite.position.y = enemy_base_y + float_offset

func update_gifts_quantities(gifts: Dictionary):
	if negacao_label:
		negacao_label.text = "x%d" % gifts.get("negacao", 0)
	if raiva_label:
		raiva_label.text = "x%d" % gifts.get("raiva", 0)
	if barganha_label:
		barganha_label.text = "x%d" % gifts.get("barganha", 0)
	if depressao_label:
		depressao_label.text = "x%d" % gifts.get("depressao", 0)
	if aceitacao_label:
		aceitacao_label.text = "x%d" % gifts.get("aceitacao", 0)

func _on_skills_menu_atacar():
	skills_menu.visible = false
	action_buttons.set_buttons_enabled(true)
	emit_signal("skill_chosen", {"name": "Atacar"})

func _on_skills_menu_presente():
	skills_menu.visible = false
	action_buttons.set_buttons_enabled(true)
	emit_signal("skill_chosen", {"name": "Presente++"})

func _show_skills_menu():
	skills_menu.visible = true
	action_buttons.set_buttons_enabled(false)
