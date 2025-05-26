extends Control

signal flee_pressed
signal skill_pressed
signal skill_selected
signal item_pressed
signal item_selected
signal talk_pressed
signal talk_option_selected
signal gift_pressed
signal gift_selected
signal next_pressed

# Referência ao status do player
@onready var player_status = $StatusPanel/PlayerStatus

# Referência aos estágios do luto
@onready var grief_stages = {
	"negacao": $GriefStages/Negacao,
	"raiva": $GriefStages/Raiva,
	"barganha": $GriefStages/Barganha,
	"depressao": $GriefStages/Depressao,
	"aceitacao": $GriefStages/Aceitacao
}

# Referências aos botões de comando
@onready var command_buttons = [
	$CommandBar/SkillButton,
	$CommandBar/ItemButton,
	$CommandBar/TalkButton,
	$CommandBar/GiftButton,
	$CommandBar/FleeButton,
	$CommandBar/NextButton
]

@onready var skill_button = $CommandBar/SkillButton
@onready var item_button = $CommandBar/ItemButton
@onready var talk_button = $CommandBar/TalkButton
@onready var gift_button = $CommandBar/GiftButton
@onready var flee_button = $CommandBar/FleeButton
@onready var next_button = $CommandBar/NextButton

# Referência ao indicador de turno
@onready var turn_icons = [
	$TurnIndicator/TurnIcons/Icon1,
	$TurnIndicator/TurnIcons/Icon2,
	$TurnIndicator/TurnIcons/Icon3
]
@onready var turn_label = $TurnIndicator/TurnLabel

var selected_command := 0
var grief_quantities = {
	"negacao": 3,
	"raiva": 2,
	"barganha": 4,
	"depressao": 1,
	"aceitacao": 5
}

# Cenas dos menus
var skill_menu_scene = preload("res://scenes/ui/SkillMenu.tscn")
var item_menu_scene = preload("res://scenes/ui/ItemMenu.tscn")
var talk_menu_scene = preload("res://scenes/ui/TalkMenu.tscn")

# Variáveis para controlar os menus ativos
var active_menu = null

func _ready():
	print("BattleUI: Inicializando...")
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Configura os botões
	for btn in command_buttons:
		btn.disabled = false
		btn.focus_mode = Control.FOCUS_ALL
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		print("BattleUI: Botão configurado: ", btn.name)
	
	# Conecta os sinais dos botões
	skill_button.pressed.connect(_on_skill_pressed)
	item_button.pressed.connect(_on_item_pressed)
	talk_button.pressed.connect(_on_talk_pressed)
	gift_button.pressed.connect(_on_gift_pressed)
	flee_button.pressed.connect(_on_flee_pressed)
	next_button.pressed.connect(_on_next_pressed)
	print("BattleUI: Sinais dos botões conectados")
	
	# Mouse highlight
	for i in range(command_buttons.size()):
		command_buttons[i].mouse_entered.connect(_on_command_mouse_entered.bind(i))
		command_buttons[i].pressed.connect(_on_command_pressed.bind(i))
	
	_update_command_highlight()
	_update_grief_stages_display()
	print("BattleUI: Inicialização concluída")
	
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("battle_skill_menu"):
		get_node("/root/UIManager").show_battle_menu("skill_menu")
	elif event.is_action_pressed("battle_item_menu"):
		get_node("/root/UIManager").show_battle_menu("item_menu")
	elif event.is_action_pressed("battle_talk_menu"):
		get_node("/root/UIManager").show_battle_menu("talk_menu")
	elif event.is_action_pressed("battle_gift_menu"):
		get_node("/root/UIManager").show_battle_menu("gifts_menu") # Certifique-se que existe esse menu
	elif event.is_action_pressed("battle_flee"):
		emit_signal("flee_pressed")
	elif event.is_action_pressed("battle_pass_turn"):
		emit_signal("pass_turn_pressed")
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_RIGHT:
			selected_command = (selected_command + 1) % command_buttons.size()
			_update_command_highlight()
			print("BattleUI: Navegando para direita, comando selecionado: ", command_buttons[selected_command].name)
		elif event.keycode == KEY_LEFT:
			selected_command = (selected_command - 1) % command_buttons.size()
			_update_command_highlight()
			print("BattleUI: Navegando para esquerda, comando selecionado: ", command_buttons[selected_command].name)
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			print("BattleUI: Enter pressionado, executando comando: ", command_buttons[selected_command].name)
			_on_command_pressed(selected_command)
		elif event.keycode == KEY_ESCAPE:
			print("BattleUI: ESC pressionado, fechando menu ativo")
			_close_active_menu()

func _close_active_menu():
	if active_menu != null:
		print("BattleUI: Fechando menu ativo: ", active_menu.name)
		active_menu.queue_free()
		active_menu = null
	else:
		print("BattleUI: Nenhum menu ativo para fechar")

func _on_command_mouse_entered(idx):
	selected_command = idx
	_update_command_highlight()
	print("BattleUI: Mouse entrou no botão: ", command_buttons[idx].name)

func _on_command_pressed(idx):
	selected_command = idx
	_update_command_highlight()
	print("BattleUI: Botão pressionado: ", command_buttons[idx].name)
	match idx:
		0:
			_on_skill_pressed()
			return
		1:
			_on_item_pressed()
			return
		2:
			_on_talk_pressed()
			return
		3:
			_on_gift_pressed()
			return
		4:
			_on_flee_pressed()
			return
		5:
			_on_next_pressed()
			return

func _on_flee_pressed():
	print("BattleUI: Botão Flee pressionado")
	_close_active_menu()
	emit_signal("flee_pressed")

func _on_skill_pressed():
	print("BattleUI: Botão Skill pressionado")
	_close_active_menu()
	get_node("/root/UIManager").show_battle_menu("skill_menu")
	print("BattleUI: Menu de habilidades aberto")
	emit_signal("skill_pressed")

func _on_skill_selected(skill_data):
	print("BattleUI: Habilidade selecionada: ", skill_data.name)
	_close_active_menu()
	emit_signal("skill_selected", skill_data)

func _on_item_pressed():
	print("BattleUI: Botão Item pressionado")
	_close_active_menu()
	get_node("/root/UIManager").show_battle_menu("item_menu")
	print("BattleUI: Menu de itens aberto")
	emit_signal("item_pressed")

func _on_item_selected(item_data):
	print("BattleUI: Item selecionado: ", item_data.name)
	_close_active_menu()
	emit_signal("item_selected", item_data)

func _on_talk_pressed():
	print("BattleUI: Botão Talk pressionado")
	_close_active_menu()
	get_node("/root/UIManager").show_battle_menu("talk_menu")
	print("BattleUI: Menu de conversa aberto")
	emit_signal("talk_pressed")

func _on_talk_option_selected(option_data):
	print("BattleUI: Opção de conversa selecionada: ", option_data.text)
	_close_active_menu()
	emit_signal("talk_option_selected", option_data)

func _on_gift_pressed():
	print("BattleUI: Botão Gift pressionado")
	_close_active_menu()
	_update_grief_stages_display()
	print("BattleUI: Exibição dos estágios do luto atualizada")
	emit_signal("gift_pressed")

func _on_gift_selected(id):
	print("BattleUI: Gift selecionado, ID: ", id)
	if id < grief_stages.size():  # Se for um estágio do luto
		var stage = grief_stages.keys()[id]
		if grief_quantities[stage] > 0:
			grief_quantities[stage] -= 1
			_update_grief_stages_display()
			print("BattleUI: Estágio do luto usado: ", stage, ", quantidade restante: ", grief_quantities[stage])
			emit_signal("gift_selected", id, {"type": "grief_stage", "stage": stage})
	else:  # Se for um presente especial
		print("BattleUI: Presente especial selecionado")
		emit_signal("gift_selected", id, {"type": "special_gift", "gift_id": id})

func _on_next_pressed():
	print("BattleUI: Botão Next pressionado")
	_close_active_menu()
	emit_signal("next_pressed")

# Atualiza o status do player na UI
func update_status(hp: int, max_hp: int, mp: int, max_mp: int):
	player_status.get_node("HPBar").max_value = max_hp
	player_status.get_node("HPBar").value = hp
	player_status.get_node("MPBar").max_value = max_mp
	player_status.get_node("MPBar").value = mp
	player_status.get_node("HPValue").text = "HP: %d/%d" % [hp, max_hp]
	player_status.get_node("MPValue").text = "MP: %d/%d" % [mp, max_mp]
	print("BattleUI: Status atualizado - HP: %d/%d, MP: %d/%d" % [hp, max_hp, mp, max_mp])

# Atualiza a exibição dos estágios do luto
func _update_grief_stages_display():
	for stage in grief_stages:
		var quantity = grief_quantities[stage]
		grief_stages[stage].get_node("Quantity").text = "x%d" % quantity
		# Desabilita visualmente se não tiver quantidade
		grief_stages[stage].modulate = Color(1, 1, 1, 1) if quantity > 0 else Color(0.5, 0.5, 0.5, 0.5)
	print("BattleUI: Exibição dos estágios do luto atualizada")

# Atualiza os ícones de turno e o label
func update_turn_icons(turns: int, is_player: bool):
	for i in range(turn_icons.size()):
		turn_icons[i].visible = i < turns
	turn_label.text = "PLAYER" if is_player else "ENEMY"
	print("BattleUI: Turno atualizado - Turnos: %d, É jogador: %s" % [turns, "Sim" if is_player else "Não"])

func _update_command_highlight():
	for i in range(command_buttons.size()):
		command_buttons[i].add_theme_color_override("font_color", Color(1,1,1))
		command_buttons[i].add_theme_color_override("font_color_hover", Color(1,1,1))
		command_buttons[i].add_theme_color_override("font_color_pressed", Color(1,1,1))
		command_buttons[i].modulate = Color(1,1,1,1)
	if command_buttons.size() > 0:
		command_buttons[selected_command].add_theme_color_override("font_color", Color(0,1,1))
		command_buttons[selected_command].modulate = Color(0.7,1,1,1)
	print("BattleUI: Destaque do comando atualizado para: ", command_buttons[selected_command].name) 
