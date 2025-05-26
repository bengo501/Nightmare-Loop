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
		battle_camera.current = true  # Ativa a câmera de batalha imediatamente
		# Desativa o processamento de input da câmera do player
		if player_ref and player_ref.has_node("ThirdPersonCamera"):
			player_ref.get_node("ThirdPersonCamera").current = false
		if player_ref and player_ref.has_node("FirstPersonCamera"):
			player_ref.get_node("FirstPersonCamera").current = false
	# UI principal
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
		# Posiciona o inimigo à frente da câmera de batalha
		if battle_camera:
			var cam_transform = battle_camera.global_transform
			var forward = -cam_transform.basis.z.normalized()
			var enemy_pos = cam_transform.origin + forward * 5.0 # 5 unidades à frente
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

	# Conectar sinais da UI já existente
	if battle_ui_instance:
		battle_ui_instance.visible = true
		print("Conectando sinais da BattleUI (fixa)")
		if battle_ui_instance.has_signal("flee_pressed"):
			battle_ui_instance.flee_pressed.connect(_on_flee_pressed)
		if battle_ui_instance.has_signal("skill_pressed"):
			battle_ui_instance.skill_pressed.connect(_on_skill_pressed)
		if battle_ui_instance.has_signal("skill_selected"):
			battle_ui_instance.skill_selected.connect(_on_skill_selected)
		if battle_ui_instance.has_signal("swap_pressed"):
			battle_ui_instance.swap_pressed.connect(_on_swap_pressed)
		if battle_ui_instance.has_signal("next_pressed"):
			battle_ui_instance.next_pressed.connect(_on_next_pressed)

	# Esconde a HUD normal se existir
	if UIManager.hud_instance:
		UIManager.hud_instance.visible = false

	# Atualiza a UI de batalha com os dados reais
	_update_battle_ui()

	# Ativa a UI e inicializa a batalha
	if battle_ui_instance and battle_ui_instance is Control:
		battle_ui_instance.visible = true
		# Conectar sinais dos botões
		if battle_ui_instance.has_signal("flee_pressed"):
			battle_ui_instance.connect("flee_pressed", Callable(self, "_on_flee_pressed"))
		if battle_ui_instance.has_signal("skill_pressed"):
			battle_ui_instance.connect("skill_pressed", Callable(self, "_on_skill_pressed"))
		if battle_ui_instance.has_signal("skill_selected"):
			battle_ui_instance.connect("skill_selected", Callable(self, "_on_skill_selected"))
		# Conectar comandos principais
		if "command_buttons" in battle_ui_instance:
			battle_ui_instance.command_buttons[0].connect("pressed", Callable(self, "_on_skill_pressed")) # Skill
			battle_ui_instance.command_buttons[1].connect("pressed", Callable(self, "_on_swap_pressed")) # Swap
			battle_ui_instance.command_buttons[2].connect("pressed", Callable(self, "_on_flee_pressed")) # Flee
			battle_ui_instance.command_buttons[3].connect("pressed", Callable(self, "_on_next_pressed")) # Next

	is_in_battle = true
	current_turn = TurnType.PLAYER
	update_hp_display()
	update_turn_indicator()
	
	# Desativa os controles do player
	if player_ref:
		player_ref.can_move = false
		player_ref.set_process_input(false)
		player_ref.set_physics_process(false)
	
	# Exemplo de atualização de status e turnos:
	# (REMOVIDO - agora só usamos _update_battle_ui())

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
	# Player
	if player_ref:
		var name = "Player"
		if "player_name" in player_ref:
			name = player_ref.player_name
		var hp = int(player_ref.current_health)
		var max_hp = int(player_ref.max_health)
		var mp = 0
		var max_mp = 0
		if "current_mp" in player_ref:
			mp = int(player_ref.current_mp)
		if "max_mp" in player_ref:
			max_mp = int(player_ref.max_mp)
		battle_ui_instance.update_status(0, name, hp, max_hp, mp, max_mp)
	# Inimigo (exemplo, pode ser expandido para party)
	if enemy_ref:
		var name = "Enemy"
		if "enemy_name" in enemy_ref:
			name = enemy_ref.enemy_name
		var hp = int(enemy_ref.current_health)
		var max_hp = int(enemy_ref.max_health)
		var mp = 0
		var max_mp = 0
		if "current_mp" in enemy_ref:
			mp = int(enemy_ref.current_mp)
		if "max_mp" in enemy_ref:
			max_mp = int(enemy_ref.max_mp)
		battle_ui_instance.update_status(1, name, hp, max_hp, mp, max_mp)
	# Atualiza turnos (exemplo: 3 turnos para o player)
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
	# Volta para o mundo ao fugir da batalha
	if UIManager.has_method("hide_ui"):
		UIManager.hide_ui("battle_ui")
	if UIManager.hud_instance:
		UIManager.hud_instance.visible = true
	SceneManager.change_scene("world")

func _on_skill_pressed():
	# Skill popup já aparece pela UI, mas aqui tratamos a escolha
	# O popup chama _on_skill_selected via signal
	print("Skill menu aberto!")

func _on_swap_pressed():
	# Placeholder para troca de personagem
	print("Troca de personagem não implementada.")

func _on_next_pressed():
	# Passa o turno para o inimigo
	if current_turn == TurnType.PLAYER:
		current_turn = TurnType.ENEMY
		update_turn_indicator()

# Skill popup handler
func _on_skill_selected(id):
	if current_turn != TurnType.PLAYER:
		return
	if id == 0:
		print("Ataque Normal!")
		_on_attack_pressed()
	elif id == 1:
		print("Ataque Especial!")
		_on_special_pressed()
	elif id == 2:
		print("Magia!")
		# Exemplo: dano mágico
		var magic_damage = player_ref.attack_damage * 2
		enemy_ref.take_damage(magic_damage)
		update_hp_display()
		if enemy_ref.current_health <= 0:
			end_battle()
			return
		current_turn = TurnType.ENEMY
		update_turn_indicator() 
