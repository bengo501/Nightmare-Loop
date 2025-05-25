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
var pending_enemy_data = null

# Referências corretas conforme a hierarquia
var attack_button: Button = null
var defend_button: Button = null
var special_button: Button = null
var battle_ui: Control = null
var turn_indicator: Label = null
var player_hp_label: Label = null
var enemy_hp_label: Label = null

func _ready():
	# Câmera
	battle_camera = get_node_or_null("BattleCamera")
	if battle_camera:
		battle_camera.current = true  # Ativa a câmera de batalha imediatamente
		# Desativa o processamento de input da câmera do player
		if player_ref and player_ref.has_node("ThirdPersonCamera"):
			player_ref.get_node("ThirdPersonCamera").current = false
		if player_ref and player_ref.has_node("FirstPersonCamera"):
			player_ref.get_node("FirstPersonCamera").current = false
	# UI principal
	battle_ui = get_node_or_null("UI/BattleUI")
	# Botões de ação
	attack_button = get_node_or_null("UI/BattleUI/ActionButtons/AttackButton")
	defend_button = get_node_or_null("UI/BattleUI/ActionButtons/DefendButton")
	special_button = get_node_or_null("UI/BattleUI/ActionButtons/SpecialButton")
	turn_indicator = get_node_or_null("UI/BattleUI/TurnIndicator")
	player_hp_label = get_node_or_null("UI/BattleUI/StatusPanel/PlayerStatus/PlayerHP")
	enemy_hp_label = get_node_or_null("UI/BattleUI/StatusPanel/EnemyStatus/EnemyHP")
	
	# Conecta os sinais dos botões de forma segura
	if attack_button:
		attack_button.pressed.connect(_on_attack_pressed)
	if defend_button:
		defend_button.pressed.connect(_on_defend_pressed)
	if special_button:
		special_button.pressed.connect(_on_special_pressed)
	
	# Instancia o ghost salvo em BattleData, se existir
	var enemy_data = BattleData.enemy_data
	if enemy_data:
		var ghost_scene = preload("res://scenes/enemies/ghost1.tscn")
		enemy_ref = ghost_scene.instantiate()
		enemy_ref.ghost_type = enemy_data.ghost_type
		enemy_ref.max_health = enemy_data.max_health
		enemy_ref.current_health = enemy_data.current_health
		enemy_ref.speed = enemy_data.speed
		enemy_ref.attack_range = enemy_data.attack_range
		enemy_ref.attack_damage = enemy_data.attack_damage
		enemy_ref.attack_cooldown = enemy_data.attack_cooldown
		enemy_ref.ghost_color = enemy_data.ghost_color
		enemy_ref.ghost_scale = enemy_data.ghost_scale
		add_child(enemy_ref)
		enemy_ref.global_position = Vector3(0, 0, 0)
		BattleData.enemy_data = null
	else:
		enemy_ref = get_node_or_null("Ghost1")

	# Referenciar ou instanciar o player
	player_ref = get_node_or_null("Player")
	if not player_ref:
		var player_scene = preload("res://scenes/player/player.tscn")
		player_ref = player_scene.instantiate()
		player_ref.is_battle_mode = true
		add_child(player_ref)
		player_ref.global_position = Vector3(0, 0, -2) # Posição inicial do player

	# Debug: Verificar player_ref e enemy_ref
	if not player_ref:
		push_error("[BattleSceneManager] player_ref é null! Não foi possível instanciar ou encontrar o player.")
		return
	if not enemy_ref:
		push_error("[BattleSceneManager] enemy_ref é null! Não foi possível instanciar ou encontrar o inimigo.")
		return
	# Verificar métodos essenciais
	var player_ok = player_ref.has_method("take_damage") and player_ref.has_method("die") and player_ref.has_method("set_health_multiplier")
	var enemy_ok = enemy_ref.has_method("take_damage")
	if not player_ok:
		push_error("[BattleSceneManager] player_ref não possui todos os métodos/atributos necessários para a batalha!")
		return
	if not enemy_ok:
		push_error("[BattleSceneManager] enemy_ref não possui todos os métodos/atributos necessários para a batalha!")
		return

	# Ativa a UI e inicializa a batalha
	if battle_ui:
		battle_ui.visible = true

	is_in_battle = true
	current_turn = TurnType.PLAYER
	update_hp_display()
	update_turn_indicator()
	
	# Desativa os controles do player
	if player_ref:
		player_ref.can_move = false
		player_ref.set_process_input(false)
		player_ref.set_physics_process(false)
	
	# Emite o sinal de início de batalha
	emit_signal("battle_started")
	
	# Força a atualização da interface do jogador
	if player_ref.has_method("_on_battle_started"):
		player_ref._on_battle_started()

func start_battle(enemy_instance = null):
	if is_in_battle:
		return
	pending_enemy_data = enemy_instance
	# Troca para a cena de batalha
	get_node("/root/SceneManager").change_scene("battle")

func end_battle():
	if not is_in_battle:
		return
		
	is_in_battle = false
	
	# Desativa a câmera de batalha
	if battle_camera:
		battle_camera.current = false
	
	# Restaura a câmera anterior
	if third_person_camera:
		third_person_camera.current = true
	
	# Esconde a UI
	if battle_ui:
		battle_ui.visible = false
	
	# Reativa os controles do player
	if player_ref:
		player_ref.can_move = true
		player_ref.set_process_input(true)
		player_ref.set_physics_process(true)
	
	# Emite sinal de fim de batalha
	emit_signal("battle_ended")
	
	print("Battle Scene finalizada!")

func update_turn_indicator():
	if not turn_indicator:
		print("[BattleSceneManager] turn_indicator não encontrado!")
		return
	if current_turn == TurnType.PLAYER:
		turn_indicator.text = "Turno do Jogador"
		if attack_button:
			attack_button.disabled = false
			defend_button.disabled = false
			special_button.disabled = false
	elif current_turn == TurnType.ENEMY:
		turn_indicator.text = "Turno do Inimigo"
		if attack_button:
			attack_button.disabled = true
			defend_button.disabled = true
			special_button.disabled = true
		await get_tree().create_timer(1.0).timeout
		enemy_turn()

func update_hp_display():
	if player_ref and enemy_ref:
		if player_hp_label:
			player_hp_label.text = "HP: %d/%d" % [player_ref.current_health, player_ref.max_health]
		else:
			print("[BattleSceneManager] player_hp_label não encontrado!")
		if enemy_hp_label:
			enemy_hp_label.text = "HP: %d/%d" % [enemy_ref.current_health, enemy_ref.max_health]
		else:
			print("[BattleSceneManager] enemy_hp_label não encontrado!")

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
