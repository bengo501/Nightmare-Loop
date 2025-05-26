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
var turn_indicator: Label = null
var player_hp_label: Label = null
var enemy_hp_label: Label = null

@onready var battle_ui_instance = get_node_or_null("BattleUI")

func _ready():
	# Câmera
	battle_camera = get_node_or_null("BattleCamera")
	if battle_camera:
		battle_camera.current = true
		if player_ref and player_ref.has_node("ThirdPersonCamera"):
			player_ref.get_node("ThirdPersonCamera").current = false
		if player_ref and player_ref.has_node("FirstPersonCamera"):
			player_ref.get_node("FirstPersonCamera").current = false
	
	# UI principal
	attack_button = get_node_or_null("UI/BattleUI/ActionButtons/AttackButton")
	defend_button = get_node_or_null("UI/BattleUI/ActionButtons/DefendButton")
	special_button = get_node_or_null("UI/BattleUI/ActionButtons/SpecialButton")
	turn_indicator = get_node_or_null("UI/BattleUI/TurnIndicator")
	player_hp_label = get_node_or_null("UI/BattleUI/StatusPanel/PlayerStatus/PlayerHP")
	enemy_hp_label = get_node_or_null("UI/BattleUI/StatusPanel/EnemyStatus/EnemyHP")
	
	# Instancia o inimigo salvo em BattleData, se existir
	var enemy_data = BattleData.enemy_data
	if enemy_data:
		var enemy_scene = load(enemy_data.scene_path)
		enemy_ref = enemy_scene.instantiate()
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
		if battle_camera:
			var cam_transform = battle_camera.global_transform
			var forward = -cam_transform.basis.z.normalized()
			var enemy_pos = cam_transform.origin + forward * 5.0
			enemy_ref.global_position = enemy_pos
		else:
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
		player_ref.global_position = Vector3(0, 0, -2)

	# Conectar sinais da UI
	if battle_ui_instance:
		battle_ui_instance.visible = true
		if battle_ui_instance.has_signal("flee_pressed"):
			battle_ui_instance.flee_pressed.connect(_on_flee_pressed)
		if battle_ui_instance.has_signal("skill_pressed"):
			battle_ui_instance.skill_pressed.connect(_on_skill_pressed)
		if battle_ui_instance.has_signal("skill_selected"):
			battle_ui_instance.skill_selected.connect(_on_skill_selected)
		if battle_ui_instance.has_signal("item_pressed"):
			battle_ui_instance.item_pressed.connect(_on_item_pressed)
		if battle_ui_instance.has_signal("item_selected"):
			battle_ui_instance.item_selected.connect(_on_item_selected)
		if battle_ui_instance.has_signal("talk_pressed"):
			battle_ui_instance.talk_pressed.connect(_on_talk_pressed)
		if battle_ui_instance.has_signal("talk_option_selected"):
			battle_ui_instance.talk_option_selected.connect(_on_talk_option_selected)
		if battle_ui_instance.has_signal("gift_pressed"):
			battle_ui_instance.gift_pressed.connect(_on_gift_pressed)
		if battle_ui_instance.has_signal("gift_selected"):
			battle_ui_instance.gift_selected.connect(_on_gift_selected)
		if battle_ui_instance.has_signal("next_pressed"):
			battle_ui_instance.next_pressed.connect(_on_next_pressed)

	# Esconde a HUD normal se existir
	if UIManager.hud_instance:
		UIManager.hud_instance.visible = false

	# Atualiza a UI de batalha
	_update_battle_ui()

	is_in_battle = true
	current_turn = TurnType.PLAYER
	update_hp_display()
	update_turn_indicator()
	
	# Desativa os controles do player
	if player_ref:
		player_ref.can_move = false
		player_ref.set_process_input(false)
		player_ref.set_physics_process(false)
	
	emit_signal("battle_started")
	
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
	if battle_ui_instance:
		battle_ui_instance.visible = false
	
	# Reativa os controles do player
	if player_ref:
		player_ref.can_move = true
		player_ref.set_process_input(true)
		player_ref.set_physics_process(true)
	
	# Esconde a UI de batalha e mostra a HUD normal
	if UIManager.has_method("hide_ui"):
		UIManager.hide_ui("battle_ui")
	if UIManager.hud_instance:
		UIManager.hud_instance.visible = true
	
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
	_update_battle_ui()

func _update_battle_ui():
	if not battle_ui_instance:
		return
	# Garante que é a UI correta
	if not ("update_status" in battle_ui_instance and "update_turn_icons" in battle_ui_instance):
		return
		
	# Atualiza os status dos estágios do luto
	var grief_stages = [
		{"name": "Negação", "quantity": 3, "hp": 100, "max_hp": 100, "mp": 100, "max_mp": 100},
		{"name": "Raiva", "quantity": 2, "hp": 100, "max_hp": 100, "mp": 100, "max_mp": 100},
		{"name": "Barganha", "quantity": 4, "hp": 100, "max_hp": 100, "mp": 100, "max_mp": 100},
		{"name": "Depressão", "quantity": 1, "hp": 100, "max_hp": 100, "mp": 100, "max_mp": 100},
		{"name": "Aceitação", "quantity": 5, "hp": 100, "max_hp": 100, "mp": 100, "max_mp": 100}
	]
	
	for i in range(grief_stages.size()):
		var stage = grief_stages[i]
		battle_ui_instance.update_status(
			i,
			stage.name,
			stage.hp,
			stage.max_hp,
			stage.mp,
			stage.max_mp,
			stage.quantity
		)
	
	# Atualiza turnos
	battle_ui_instance.update_turn_icons(3, current_turn == TurnType.PLAYER)

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

func _on_flee_pressed():
	end_battle()

func _on_skill_pressed():
	# O menu de skills já é gerenciado pela UI
	pass

func _on_talk_pressed():
	# O menu de conversas já é gerenciado pela UI
	pass

func _on_gift_pressed():
	# O menu de presentes já é gerenciado pela UI
	pass

func _on_next_pressed():
	if current_turn == TurnType.PLAYER:
		current_turn = TurnType.ENEMY
		update_turn_indicator()

# Skill popup handler
func _on_skill_selected(id):
	if current_turn != TurnType.PLAYER:
		return
		
	match id:
		0: # Ataque Normal
			var damage = player_ref.attack_damage
			enemy_ref.take_damage(damage)
		1: # Ataque Especial
			var damage = player_ref.attack_damage * 1.5
			enemy_ref.take_damage(damage)
		2: # Magia de Fogo
			var damage = player_ref.attack_damage * 2.0
			enemy_ref.take_damage(damage)
		3: # Magia de Gelo
			var damage = player_ref.attack_damage * 1.8
			enemy_ref.take_damage(damage)
		4: # Magia de Raio
			var damage = player_ref.attack_damage * 2.2
			enemy_ref.take_damage(damage)
	
	update_hp_display()
	
	if enemy_ref.current_health <= 0:
		end_battle()
		return
	
	current_turn = TurnType.ENEMY
	update_turn_indicator()

func _on_talk_option_selected(id):
	if current_turn != TurnType.PLAYER:
		return
		
	match id:
		0: # Perguntar sobre o passado
			print("O fantasma conta sobre seu passado...")
		1: # Perguntar sobre o presente
			print("O fantasma fala sobre sua situação atual...")
		2: # Perguntar sobre o futuro
			print("O fantasma faz uma previsão...")
		3: # Tentar convencer
			print("Tentando convencer o fantasma...")
	
	# Após a conversa, passa para o turno do inimigo
	current_turn = TurnType.ENEMY
	update_turn_indicator()

func _on_gift_selected(id):
	if current_turn != TurnType.PLAYER:
		return
		
	match id:
		0: # Flor
			print("Oferecendo uma flor ao fantasma...")
		1: # Chocolate
			print("Oferecendo chocolate ao fantasma...")
		2: # Livro
			print("Oferecendo um livro ao fantasma...")
		3: # Jóia
			print("Oferecendo uma jóia ao fantasma...")
	
	# Após dar o presente, passa para o turno do inimigo
	current_turn = TurnType.ENEMY
	update_turn_indicator()

func _on_item_pressed():
	# O menu de itens já é gerenciado pela UI
	pass

func _on_item_selected(id):
	if current_turn != TurnType.PLAYER:
		return
		
	match id:
		0: # Negação
			print("Usando Negação...")
			# Implementar efeito do item
		1: # Raiva
			print("Usando Raiva...")
			# Implementar efeito do item
		2: # Barganha
			print("Usando Barganha...")
			# Implementar efeito do item
		3: # Depressão
			print("Usando Depressão...")
			# Implementar efeito do item
		4: # Aceitação
			print("Usando Aceitação...")
			# Implementar efeito do item
	
	# Após usar o item, passa para o turno do inimigo
	current_turn = TurnType.ENEMY
	update_turn_indicator()

# ... resto do código existente ...
