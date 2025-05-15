extends Node

signal battle_started
signal battle_ended
signal turn_changed(turn_type)

enum TurnType { PLAYER, ENEMY }
var current_turn: TurnType = TurnType.PLAYER

var is_in_battle = false
var battle_camera: Camera3D
var player_camera: Camera3D
var third_person_camera: Camera3D
var player_ref: Node3D
var enemy_ref: Node3D

# Referências da UI
@onready var turn_indicator = $UI/BattleUI/TurnIndicator
@onready var action_buttons = $UI/BattleUI/ActionButtons
@onready var player_hp_label = $UI/BattleUI/StatusPanel/PlayerStatus/PlayerHP
@onready var enemy_hp_label = $UI/BattleUI/StatusPanel/EnemyStatus/EnemyHP
@onready var attack_button = $UI/BattleUI/ActionButtons/AttackButton
@onready var defend_button = $UI/BattleUI/ActionButtons/DefendButton
@onready var special_button = $UI/BattleUI/ActionButtons/SpecialButton
@onready var UI = $"../UI"
func _ready():
	# Encontra as câmeras necessárias
	battle_camera = get_node("BattleCamera")
	player_camera = null
	third_person_camera = null
	if has_node("/root/Main/FirstPersonCamera"):
		player_camera = get_node("/root/Main/FirstPersonCamera")
	if has_node("/root/Main/ThirdPersonCamera"):
		third_person_camera = get_node("/root/Main/ThirdPersonCamera")
	
	# Conecta os sinais dos botões de forma segura
	if attack_button:
		attack_button.pressed.connect(_on_attack_pressed)
	if defend_button:
		defend_button.pressed.connect(_on_defend_pressed)
	if special_button:
		special_button.pressed.connect(_on_special_pressed)
	
	# Inicialmente esconde a UI
	$"../UI".visible = false

func start_battle():
	if is_in_battle:
		return
		
	is_in_battle = true
	
	# Encontra referências do jogador e inimigo
	player_ref = get_node("/root/Main/Player")
	enemy_ref = get_node("Ghost1")
	
	# Desativa as câmeras normais
	player_camera.current = false
	third_person_camera.current = false
	
	# Ativa a câmera de batalha
	battle_camera.current = true
	
	# Mostra a UI
	UI.visible = true
	
	# Inicia com o turno do jogador
	current_turn = TurnType.PLAYER
	update_turn_indicator()
	
	# Emite sinal de início de batalha
	emit_signal("battle_started")
	
	print("Battle Scene iniciada!")

func end_battle():
	if not is_in_battle:
		return
		
	is_in_battle = false
	
	# Desativa a câmera de batalha
	battle_camera.current = false
	
	# Restaura a câmera anterior
	third_person_camera.current = true
	
	# Esconde a UI
	$UI.visible = false
	
	# Emite sinal de fim de batalha
	emit_signal("battle_ended")
	
	print("Battle Scene finalizada!")

func update_turn_indicator():
	if current_turn == TurnType.PLAYER:
		turn_indicator.text = "Turno do Jogador"
		action_buttons.visible = true
	else:
		turn_indicator.text = "Turno do Inimigo"
		action_buttons.visible = false
		# Inicia o turno do inimigo após um pequeno delay
		await get_tree().create_timer(1.0).timeout
		enemy_turn()

func update_hp_display():
	if player_ref and enemy_ref:
		player_hp_label.text = "HP: %d/%d" % [player_ref.current_health, player_ref.max_health]
		enemy_hp_label.text = "HP: %d/%d" % [enemy_ref.current_health, enemy_ref.max_health]

func _on_attack_pressed():
	if current_turn != TurnType.PLAYER:
		return
		
	# Realiza o ataque
	var damage = player_ref.attack_damage
	enemy_ref.take_damage(damage)
	
	# Atualiza o display de HP
	update_hp_display()
	
	# Verifica se o inimigo morreu
	if enemy_ref.current_health <= 0:
		end_battle()
		return
	
	# Muda para o turno do inimigo
	current_turn = TurnType.ENEMY
	update_turn_indicator()

func _on_defend_pressed():
	if current_turn != TurnType.PLAYER:
		return
		
	# Implementar lógica de defesa
	player_ref.defense_bonus = 1.5  # Aumenta a defesa em 50%
	
	# Muda para o turno do inimigo
	current_turn = TurnType.ENEMY
	update_turn_indicator()

func _on_special_pressed():
	if current_turn != TurnType.PLAYER:
		return
		
	# Implementar ataque especial
	var special_damage = player_ref.attack_damage * 1.5
	enemy_ref.take_damage(special_damage)
	
	# Atualiza o display de HP
	update_hp_display()
	
	# Verifica se o inimigo morreu
	if enemy_ref.current_health <= 0:
		end_battle()
		return
	
	# Muda para o turno do inimigo
	current_turn = TurnType.ENEMY
	update_turn_indicator()

func enemy_turn():
	if not is_in_battle or current_turn != TurnType.ENEMY:
		return
		
	# Lógica simples de ataque do inimigo
	var damage = enemy_ref.attack_damage
	player_ref.take_damage(damage)
	
	# Atualiza o display de HP
	update_hp_display()
	
	# Verifica se o jogador morreu
	if player_ref.current_health <= 0:
		# Implementar lógica de game over
		print("Game Over!")
		end_battle()
		return
	
	# Muda para o turno do jogador
	current_turn = TurnType.PLAYER
	update_turn_indicator() 
