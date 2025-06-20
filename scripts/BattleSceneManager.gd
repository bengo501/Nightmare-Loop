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

# Referência à UI
@onready var battle_ui = $BattleUI
@onready var player_status = $BattleUI/StatusPanel/PlayerStatus
@onready var battle_manager = $BattleManager

@onready var battle_ui_instance = get_node_or_null("BattleUI")

func _ready():
	print("[BattleSceneManager] Iniciando cena de batalha...")
	
	# Referenciar a câmera de batalha
	battle_camera = get_node_or_null("BattleCamera")
	if battle_camera:
		battle_camera.current = true
		print("[BattleSceneManager] Câmera de batalha ativada")
	else:
		push_error("[BattleSceneManager] Câmera de batalha não encontrada!")
	
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
		print("[BattleSceneManager] Dados do fantasma encontrados, instanciando...")
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
		print("[BattleSceneManager] Fantasma instanciado com sucesso!")
		BattleData.enemy_data = null
	else:
		print("[BattleSceneManager] Nenhum dado de fantasma encontrado!")
		enemy_ref = get_node_or_null("Ghost1")

	# Referenciar ou instanciar o player
	player_ref = get_node_or_null("Player")
	if not player_ref:
		print("[BattleSceneManager] Instanciando novo jogador...")
		var player_scene = preload("res://scenes/player/player.tscn")
		player_ref = player_scene.instantiate()
		player_ref.is_battle_mode = true
		add_child(player_ref)
		player_ref.global_position = Vector3(0, 0, -2)
		print("[BattleSceneManager] Jogador instanciado com sucesso!")

	# Mostra a UI de batalha
	print("[BattleSceneManager] Mostrando UI de batalha...")
	var ui_manager = get_node("/root/UIManager")
	if ui_manager:
		ui_manager.show_ui("battle_ui")
		battle_ui_instance = ui_manager.battle_ui_instance
		
		# Esconde a HUD normal se existir
		if ui_manager.hud_instance:
			ui_manager.hud_instance.visible = false
	else:
		push_error("[BattleSceneManager] UIManager não encontrado!")
	
	# Conecta os sinais da UI
	if battle_ui_instance:
		print("[BattleSceneManager] Conectando sinais da UI de batalha...")
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
		print("[BattleSceneManager] Sinais da UI conectados com sucesso!")

	# Atualiza a UI de batalha
	_update_battle_ui()

	# Inicializa o sistema de turnos
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

	print("[BattleSceneManager] Cena de batalha inicializada com sucesso!")

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
	
	# Esconde a UI de batalha e mostra a HUD normal
	var ui_manager = get_node("/root/UIManager")
	if ui_manager:
		ui_manager.hide_ui("battle_ui")
		if ui_manager.hud_instance:
			ui_manager.hud_instance.visible = true
	else:
		push_error("[BattleSceneManager] UIManager não encontrado!")
	
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
		turn_indicator.text = "Seu Turno"
		turn_indicator.modulate = Color(0, 1, 0)  # Verde para turno do jogador
		if attack_button:
			attack_button.disabled = false
			defend_button.disabled = false
			special_button.disabled = false
			print("[BattleSceneManager] Botões de ação habilitados")
	elif current_turn == TurnType.ENEMY:
		turn_indicator.text = "Turno do Fantasma"
		turn_indicator.modulate = Color(1, 0, 0)  # Vermelho para turno do inimigo
		if attack_button:
			attack_button.disabled = true
			defend_button.disabled = true
			special_button.disabled = true
			print("[BattleSceneManager] Botões de ação desabilitados")
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
			stage.hp,
			stage.max_hp,
			stage.mp,
			stage.max_mp,
		)
	
	# Atualiza turnos
	battle_ui_instance.update_turn_icons(3, current_turn == TurnType.PLAYER)

func _on_attack_pressed():
	if current_turn != TurnType.PLAYER:
		return
		
	print("[BattleSceneManager] Jogador atacou!")
	# Realiza o ataque
	var damage = player_ref.attack_damage
	enemy_ref.take_damage(damage)
	print("[BattleSceneManager] Fantasma tomou ", damage, " de dano!")
	
	# Atualiza o display de HP
	update_hp_display()
	
	# Verifica se o inimigo morreu
	if enemy_ref.current_health <= 0:
		print("[BattleSceneManager] Fantasma derrotado!")
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
		
	print("[BattleSceneManager] Turno do fantasma!")
	# Lógica simples de ataque do inimigo
	var damage = enemy_ref.attack_damage
	player_ref.take_damage(damage)
	print("[BattleSceneManager] Jogador tomou ", damage, " de dano!")
	
	# Atualiza o display de HP
	update_hp_display()
	
	# Verifica se o jogador morreu
	if player_ref.current_health <= 0:
		print("[BattleSceneManager] Jogador derrotado!")
		# Implementar lógica de game over
		end_battle()
		return
	
	# Muda para o turno do jogador
	current_turn = TurnType.PLAYER
	update_turn_indicator()

func _on_flee_pressed():
	print("[BattleSceneManager] Tentando fugir da batalha...")
	# 50% de chance de fugir com sucesso
	if randf() < 0.5:
		print("[BattleSceneManager] Fuga bem sucedida!")
		end_battle()
	else:
		print("[BattleSceneManager] Fuga falhou!")
		# Muda para o turno do inimigo como punição
		current_turn = TurnType.ENEMY
		update_turn_indicator()

func _on_skill_pressed():
	if current_turn != TurnType.PLAYER:
		return
		
	print("[BattleSceneManager] Abrindo menu de habilidades...")
	if battle_ui_instance and battle_ui_instance.has_method("show_skill_menu"):
		battle_ui_instance.show_skill_menu()
		# Desabilita os botões principais enquanto o submenu está aberto
		_set_main_buttons_enabled(false)

func _on_talk_pressed():
	if current_turn != TurnType.PLAYER:
		return
		
	print("[BattleSceneManager] Abrindo menu de conversas...")
	if battle_ui_instance and battle_ui_instance.has_method("show_talk_menu"):
		battle_ui_instance.show_talk_menu()
		# Desabilita os botões principais enquanto o submenu está aberto
		_set_main_buttons_enabled(false)

func _on_gift_pressed():
	if current_turn != TurnType.PLAYER:
		return
		
	print("[BattleSceneManager] Abrindo menu de presentes...")
	if battle_ui_instance and battle_ui_instance.has_method("show_gift_menu"):
		battle_ui_instance.show_gift_menu()
		# Desabilita os botões principais enquanto o submenu está aberto
		_set_main_buttons_enabled(false)

func _on_item_pressed():
	if current_turn != TurnType.PLAYER:
		return
		
	print("[BattleSceneManager] Abrindo menu de itens...")
	if battle_ui_instance and battle_ui_instance.has_method("show_item_menu"):
		battle_ui_instance.show_item_menu()
		# Desabilita os botões principais enquanto o submenu está aberto
		_set_main_buttons_enabled(false)

func _on_next_pressed():
	if current_turn != TurnType.PLAYER:
		return
		
	print("[BattleSceneManager] Passando para o próximo turno...")
	current_turn = TurnType.ENEMY
	update_turn_indicator()

# Função auxiliar para habilitar/desabilitar botões principais
func _set_main_buttons_enabled(enabled: bool):
	if attack_button:
		attack_button.disabled = not enabled
	if defend_button:
		defend_button.disabled = not enabled
	if special_button:
		special_button.disabled = not enabled

# Handlers para fechamento de submenus
func _on_skill_menu_closed():
	print("[BattleSceneManager] Menu de habilidades fechado")
	_set_main_buttons_enabled(true)

func _on_talk_menu_closed():
	print("[BattleSceneManager] Menu de conversas fechado")
	_set_main_buttons_enabled(true)

func _on_gift_menu_closed():
	print("[BattleSceneManager] Menu de presentes fechado")
	_set_main_buttons_enabled(true)

func _on_item_menu_closed():
	print("[BattleSceneManager] Menu de itens fechado")
	_set_main_buttons_enabled(true)

# Skill popup handler
func _on_skill_selected(skill_data):
	if current_turn != TurnType.PLAYER:
		return
		
	# Verifica se o jogador tem MP suficiente
	if player_ref.current_mp < skill_data.mp_cost:
		print("MP insuficiente para usar a habilidade: ", skill_data.name)
		return
		
	# Consome o MP
	player_ref.current_mp -= skill_data.mp_cost
	update_mp_display()
	
	match skill_data.type:
		"wind", "fire", "ice":  # Habilidades elementais
			var damage = player_ref.attack_damage * (skill_data.power / 100.0)
			enemy_ref.take_damage(damage)
			print("Usando habilidade elemental: ", skill_data.name)
			
			# Efeitos específicos por elemento
			match skill_data.type:
				"wind":
					enemy_ref.apply_status_effect("speed_down", 2)  # Reduz velocidade por 2 turnos
				"fire":
					enemy_ref.apply_status_effect("burn", 3)  # Queima por 3 turnos
				"ice":
					enemy_ref.apply_status_effect("frozen", 1)  # Congela por 1 turno
			
			# Se o inimigo morrer por dano de habilidade, aumenta o poder dos outros fantasmas
			if enemy_ref.current_health <= 0:
				_increase_remaining_ghosts_power()
		
		"gift":  # Habilidades de presente
			print("Usando presente: ", skill_data.name)
			# Aplica efeito baseado no estágio do luto
			match skill_data.name:
				"Presente da Negação":
					enemy_ref.apply_status_effect("denial", 2)
				"Presente da Raiva":
					enemy_ref.apply_status_effect("anger", 2)
				"Presente da Barganha":
					enemy_ref.apply_status_effect("bargaining", 2)
				"Presente da Depressão":
					enemy_ref.apply_status_effect("depression", 2)
				"Presente da Aceitação":
					enemy_ref.apply_status_effect("acceptance", 2)
		
		"support":  # Habilidades de suporte
			print("Usando habilidade de suporte: ", skill_data.name)
			match skill_data.name:
				"Barreira Espiritual":
					player_ref.apply_status_effect("defense_up", 3)  # Aumenta defesa por 3 turnos
				"Purificação":
					player_ref.remove_all_status_effects()  # Remove todos os efeitos negativos
					player_ref.current_health = min(player_ref.current_health + 30, player_ref.max_health)  # Cura 30 HP
				"Visão Espiritual":
					# Revela o estágio atual do luto do fantasma
					var ghost_stage = enemy_ref.current_grief_stage
					print("Estágio atual do fantasma: ", ghost_stage)
		
		"curse":  # Habilidades de maldição
			print("Usando maldição: ", skill_data.name)
			match skill_data.name:
				"Maldição do Silêncio":
					enemy_ref.apply_status_effect("silenced", 2)  # Impede uso de habilidades por 2 turnos
				"Pesadelo Eterno":
					var damage = player_ref.attack_damage * (skill_data.power / 100.0)
					enemy_ref.take_damage(damage)
					enemy_ref.apply_status_effect("nightmare", 3)  # Causa dano mental por 3 turnos
				"Correntes do Abismo":
					enemy_ref.apply_status_effect("chained", 2)  # Reduz velocidade por 2 turnos
	
	# Atualiza o display de HP
	update_hp_display()
	
	# Verifica se o inimigo morreu
	if enemy_ref.current_health <= 0:
		end_battle()
		return
	
	# Muda para o turno do inimigo
	current_turn = TurnType.ENEMY
	update_turn_indicator()

# Função para aumentar o poder dos fantasmas restantes
func _increase_remaining_ghosts_power():
	var remaining_ghosts = get_tree().get_nodes_in_group("ghosts")
	for ghost in remaining_ghosts:
		if ghost != enemy_ref and ghost.current_health > 0:
			# Aumenta atributos do fantasma
			ghost.max_health *= 1.2 # +20% de vida
			ghost.current_health = ghost.max_health
			ghost.attack_damage *= 1.15 # +15% de dano
			ghost.speed *= 1.1 # +10% de velocidade
			print("Fantasma restante fortalecido: ", ghost.name)

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

func update_mp_display():
	if player_status:
		player_status.update_mp(player_ref.current_mp, player_ref.max_mp)

# ... resto do código existente ...

func update_battle_ui():
	if battle_ui:
		battle_ui.update_status(
			battle_manager.player_stats.hp,
			battle_manager.player_stats.max_hp,
			battle_manager.player_stats.mp,
			battle_manager.player_stats.max_mp,
			battle_manager.ghost_stats.hp,
			battle_manager.ghost_stats.max_hp
		)
		battle_ui.update_turn_indicator(current_turn == TurnType.PLAYER)

func _on_player_turn_started():
	current_turn = TurnType.PLAYER
	update_battle_ui()
	emit_signal("turn_changed", current_turn)

func _on_ghost_turn_started():
	current_turn = TurnType.ENEMY
	update_battle_ui()
	emit_signal("turn_changed", current_turn)

func _on_battle_ended(victory):
	is_in_battle = false
	
	# Desativa a câmera de batalha
	if battle_camera:
		battle_camera.current = false
	
	# Restaura a câmera anterior
	if third_person_camera:
		third_person_camera.current = true
	
	# Reativa os controles do player
	if player_ref:
		player_ref.can_move = true
		player_ref.set_process_input(true)
		player_ref.set_physics_process(true)
	
	emit_signal("battle_ended", victory)
