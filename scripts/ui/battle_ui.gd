extends Control

signal flee_pressed
signal skill_pressed
signal skill_selected
signal swap_pressed
signal next_pressed

# Referências aos status dos personagens
@onready var player_status = [
	$StatusPanel/PlayerStatus1,
	$StatusPanel/PlayerStatus2,
	$StatusPanel/PlayerStatus3,
	$StatusPanel/PlayerStatus4
]

# Referências aos botões de comando
@onready var command_buttons = [
	$CommandBar/SkillButton,
	$CommandBar/SwapButton,
	$CommandBar/FleeButton,
	$CommandBar/NextButton
]

@onready var skill_button = $CommandBar/SkillButton
@onready var swap_button = $CommandBar/SwapButton
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
var skill_popup: PopupMenu = null

func _ready():
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for btn in command_buttons:
		btn.disabled = false
		btn.focus_mode = Control.FOCUS_ALL
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_update_command_highlight()
	skill_button.pressed.connect(_on_skill_pressed)
	swap_button.pressed.connect(_on_swap_pressed)
	flee_button.pressed.connect(_on_flee_pressed)
	next_button.pressed.connect(_on_next_pressed)
	# Mouse highlight
	for i in range(command_buttons.size()):
		command_buttons[i].mouse_entered.connect(_on_command_mouse_entered.bind(i))
		command_buttons[i].pressed.connect(_on_command_pressed.bind(i))

func _input(event):
	print("BattleUI _input", event)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_RIGHT:
			selected_command = (selected_command + 1) % command_buttons.size()
			_update_command_highlight()
		elif event.keycode == KEY_LEFT:
			selected_command = (selected_command - 1) % command_buttons.size()
			_update_command_highlight()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_command_pressed(selected_command)

func _on_command_mouse_entered(idx):
	selected_command = idx
	_update_command_highlight()

func _on_command_pressed(idx):
	selected_command = idx
	_update_command_highlight()
	match idx:
		0:
			_on_skill_pressed()
			return
		1:
			_on_swap_pressed()
			return
		2:
			_on_flee_pressed()
			return
		3:
			_on_next_pressed()
			return

func _on_flee_pressed():
	emit_signal("flee_pressed")

func _on_skill_pressed():
	if not skill_popup:
		skill_popup = PopupMenu.new()
		skill_popup.add_item("Ataque Normal", 0)
		skill_popup.add_item("Ataque Especial", 1)
		skill_popup.add_item("Magia", 2)
		skill_popup.id_pressed.connect(_on_skill_selected)
		add_child(skill_popup)
	skill_popup.popup_()
	emit_signal("skill_pressed")

func _on_skill_selected(id):
	emit_signal("skill_selected", id)

func _on_swap_pressed():
	emit_signal("swap_pressed")

func _on_next_pressed():
	emit_signal("next_pressed")

# Atualiza o status de um personagem na UI
func update_status(index: int, name: String, hp: int, max_hp: int, mp: int, max_mp: int):
	if index >= player_status.size():
		return
	var status = player_status[index]
	status.get_node("Name").text = name
	status.get_node("HPBar").max_value = max_hp
	status.get_node("HPBar").value = hp
	status.get_node("MPBar").max_value = max_mp
	status.get_node("MPBar").value = mp

# Atualiza os ícones de turno e o label
func update_turn_icons(turns: int, is_player: bool):
	for i in range(turn_icons.size()):
		turn_icons[i].visible = i < turns
	turn_label.text = "PLAYER" if is_player else "ENEMY"

func _update_command_highlight():
	for i in range(command_buttons.size()):
		command_buttons[i].add_theme_color_override("font_color", Color(1,1,1))
		command_buttons[i].add_theme_color_override("font_color_hover", Color(1,1,1))
		command_buttons[i].add_theme_color_override("font_color_pressed", Color(1,1,1))
		command_buttons[i].modulate = Color(1,1,1,1)
	if command_buttons.size() > 0:
		command_buttons[selected_command].add_theme_color_override("font_color", Color(0,1,1))
		command_buttons[selected_command].modulate = Color(0.7,1,1,1) 