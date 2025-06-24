extends Node

# Dados do player
var player_hp := 100
var player_max_hp := 100

# Dados do inimigo
var enemy_hp := 100
var enemy_max_hp := 100

var enemy_present_needed := 5
var enemy_present_received := 0

# Controle de turno
var is_player_turn := true

# Referência à interface
@onready var ui = $BattleUI


func _ready():
	# Conectar sinais da interface
	ui.skill_chosen.connect(_on_skill_chosen)
	ui.talk_chosen.connect(_on_talk_chosen)
	ui.gift_chosen.connect(_on_gift_chosen)
	ui.flee_selected.connect(_on_flee)
	ui.next_turn_selected.connect(_on_next_turn)

	_start_battle()


# === Início da batalha ===
func _start_battle():
	ui.show_message("Um inimigo apareceu!")
	is_player_turn = true
	_update_ui_status()


# === Skills ===
func _on_skill_chosen(skill_name):
	if not is_player_turn:
		return

	match skill_name:
		"Atacar":
			var damage = 20
			enemy_hp -= damage
			ui.show_message("Você atacou! Causou %d de dano." % damage)

		"Presente++":
			enemy_present_received += 2
			ui.show_message("Você ofereceu uqm super presente! (+2)")

	_check_enemy_defeat()
	_end_player_turn()


# === Conversar ===
func _on_talk_chosen(talk_option):
	if not is_player_turn:
		return

	ui.show_message("Você tentou conversar... (%s)" % talk_option)
	enemy_present_received += 1
	_check_enemy_defeat()
	_end_player_turn()


# === Presentear ===
func _on_gift_chosen(gift_option):
	if not is_player_turn:
		return

	ui.show_message("Você ofereceu o presente: %s" % gift_option)
	enemy_present_received += 1
	_check_enemy_defeat()
	_end_player_turn()


# === Fugir ===
func _on_flee():
	ui.show_message("Você fugiu da batalha!")
	await get_tree().create_timer(2).timeout
	get_tree().change_scene_to_file("res://path_to_your_exploration_scene.tscn")


# === Próximo Turno ===
func _on_next_turn():
	_end_player_turn()


# === Encerrar turno do player ===
func _end_player_turn():
	is_player_turn = false
	_update_ui_status()
	await get_tree().create_timer(1).timeout
	_enemy_turn()


# === Turno do inimigo ===
func _enemy_turn():
	if enemy_hp <= 0:
		return
	if player_hp <= 0:
		return

	ui.show_message("O inimigo te atacou!")
	await get_tree().create_timer(1).timeout

	var damage = 10
	player_hp -= damage
	ui.show_message("Você recebeu %d de dano!" % damage)

	if await _check_player_defeat():
		return

	await get_tree().create_timer(1).timeout
	is_player_turn = true
	_update_ui_status()
	ui.show_message("Seu turno.")


# === Verificar derrota do inimigo ===
func _check_enemy_defeat():
	if enemy_hp <= 0:
		enemy_hp = 0
		_update_ui_status()
		ui.show_message("Você derrotou o inimigo!")
		await get_tree().create_timer(2).timeout
		_end_battle(true)
		return true

	elif enemy_present_received >= enemy_present_needed:
		_update_ui_status()
		ui.show_message("O inimigo aceitou seus presentes... Paz alcançada.")
		await get_tree().create_timer(2).timeout
		_end_battle(true)
		return true

	return false


# === Verificar derrota do player ===
func _check_player_defeat():
	if player_hp <= 0:
		player_hp = 0
		_update_ui_status()
		ui.show_message("Você foi derrotado...")
		await get_tree().create_timer(2).timeout
		_end_battle(false)
		return true

	return false


# === Encerrar batalha ===
func _end_battle(victory):
	if victory:
		ui.show_message("Vitória! A batalha acabou.")
	else:
		ui.show_message("Game Over...")

	await get_tree().create_timer(3).timeout
	get_tree().change_scene_to_file("res://path_to_your_exploration_scene.tscn")


# === Atualizar UI ===
func _update_ui_status():
	ui.update_player_status(player_hp, player_max_hp)
	ui.update_enemy_status(enemy_hp, enemy_max_hp)
	ui.update_turn_indicator(is_player_turn)
