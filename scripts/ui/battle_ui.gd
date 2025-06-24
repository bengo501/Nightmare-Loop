extends CanvasLayer

# Sinais que podem ser usados para comunicação com o sistema de batalha
signal skill_chosen(skill_name)
signal talk_chosen(talk_option)
signal gift_chosen(gift_option)
signal flee_selected
signal next_turn_selected

# Referências principais
@onready var skills_menu = $MainPanel/SkillsMenu
@onready var talk_menu = $MainPanel/TalkMenu
@onready var gifts_menu = $MainPanel/GiftsMenu
@onready var message_label = $MainPanel/MessageBox/MessageLabel


func _ready():
	_close_all_menus()
	print("Battle UI carregada e pronta!")
	

# === Funções dos botões principais ===

func _on_skills_pressed():
	_toggle_menu(skills_menu)
	print("Botão Skills clicado!")

func _on_talk_pressed():
	_toggle_menu(talk_menu)
	print("Botão Talk clicado!")

func _on_gifts_pressed():
	_toggle_menu(gifts_menu)
	print("Botão Gifts clicado!")

func _on_flee_pressed():
	_close_all_menus()
	show_message("Você fugiu da batalha.")
	print("Botão Flee clicado!")
	emit_signal("flee_selected")

func _on_next_pressed():
	_close_all_menus()
	show_message("Você passou o turno.")
	print("Botão Next clicado!")
	emit_signal("next_turn_selected")


# === Funções do submenu Skills ===

func _on_atacar_pressed():
	_close_all_menus()
	show_message("Você atacou o inimigo!")
	print("Botão Atacar clicado!")
	emit_signal("skill_chosen", "Atacar")

func _on_presente_plus_pressed():
	_close_all_menus()
	show_message("Você usou Presente++!")
	print("Botão Presente++ clicado!")
	emit_signal("skill_chosen", "Presente++")


# === Funções do submenu Talk ===

func _on_fala1_pressed():
	_close_all_menus()
	show_message("Você disse algo amigável.")
	print("Botão Fala 1 clicado!")
	emit_signal("talk_chosen", "Fala1")

func _on_fala2_pressed():
	_close_all_menus()
	show_message("Você tentou entender o inimigo.")
	print("Botão Fala 2 clicado!")
	emit_signal("talk_chosen", "Fala2")

func _on_fala3_pressed():
	_close_all_menus()
	show_message("Você falou sobre sentimentos.")
	print("Botão Fala 3 clicado!")
	emit_signal("talk_chosen", "Fala3")


# === Funções do submenu Gifts ===

func _on_negacao_pressed():
	_close_all_menus()
	show_message("Você ofereceu Negação.")
	print("Botão Negação clicado!")
	emit_signal("gift_chosen", "Negação")

func _on_raiva_pressed():
	_close_all_menus()
	show_message("Você ofereceu Raiva.")
	print("Botão Raiva clicado!")
	emit_signal("gift_chosen", "Raiva")

func _on_barganha_pressed():
	_close_all_menus()
	show_message("Você ofereceu Barganha.")
	print("Botão Barganha clicado!")
	emit_signal("gift_chosen", "Barganha")

func _on_depressao_pressed():
	_close_all_menus()
	show_message("Você ofereceu Depressão.")
	print("Botão Depressão clicado!")
	emit_signal("gift_chosen", "Depressão")

func _on_aceitacao_pressed():
	_close_all_menus()
	show_message("Você ofereceu Aceitação.")
	print("Botão Aceitação clicado!")
	emit_signal("gift_chosen", "Aceitação")


# === Controle dos Menus ===

func _toggle_menu(menu: Control):
	if menu.visible:
		_close_all_menus()
	else:
		_close_all_menus()
		menu.visible = true


func _close_all_menus():
	skills_menu.visible = false
	talk_menu.visible = false
	gifts_menu.visible = false


# === Caixa de Mensagem ===

func show_message(text: String):
	message_label.text = text


# === Mouse Hover Prints ===

func _on_skills_button_mouse_entered():
	print("Mouse passou sobre Skills")

func _on_talk_button_mouse_entered():
	print("Mouse passou sobre Talk")

func _on_gifts_button_mouse_entered():
	print("Mouse passou sobre Gifts")

func _on_flee_button_mouse_entered():
	print("Mouse passou sobre Flee")

func _on_next_button_mouse_entered():
	print("Mouse passou sobre Next")
	
func update_player_status(hp: int, max_hp: int):
	$MainPanel/PlayerStatus/PlayerHPBar.value = hp
	$MainPanel/PlayerStatus/PlayerHPBar.max_value = max_hp
	$MainPanel/PlayerStatus/PlayerHPLabel.text = "HP: %d/%d" % [hp, max_hp]

func update_enemy_status(hp: int, max_hp: int):
	$MainPanel/EnemyStatus/EnemyHPBar.value = hp
	$MainPanel/EnemyStatus/EnemyHPBar.max_value = max_hp
	$MainPanel/EnemyStatus/EnemyHPLabel.text = "HP: %d/%d" % [hp, max_hp]

func update_turn_indicator(is_player_turn: bool):
	if is_player_turn:
		$MainPanel/TurnIndicator.text = "Seu Turno"
	else:
		$MainPanel/TurnIndicator.text = "Turno do Inimigo"
