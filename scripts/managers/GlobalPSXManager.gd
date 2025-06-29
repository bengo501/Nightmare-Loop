extends Node

# Global PSX Manager - Implementa a estrutura:
# Root > PSXEffect > GameContent > CRTOverlay

# Cenas dos efeitos
var psx_effect_scene = preload("res://scenes/effects/PSXGlobalEffect.tscn")
var crt_overlay_scene = preload("res://scenes/effects/CRTOverlay.tscn")

# Referências
var psx_effect_node: Control = null
var crt_overlay_node: CanvasLayer = null
var game_content_node: Node = null

# Controle de interceptação
var is_intercepting: bool = false

# Lista de autoloads que devem ficar no Root
var root_autoloads = [
	"GlobalPSXManager",  # Este manager
	"SceneManager",      # Manager principal de cenas
	"GameStateManager"   # Manager de estado do jogo
]

# Lista de managers que devem ir para GameContent
var game_content_managers = [
	"UIManager",         # Gerenciador de UI
	"GameManager",       # Gerenciador do jogo
	"LucidityManager",   # Sistema de lucidez
	"GiftManager",       # Sistema de presentes
	"SkillManager",      # Sistema de habilidades
	"PlayerReferenceManager", # Referências do player
	"TransitionManager"  # Sistema de transições
]

func _ready():
	print("🎮 Global PSX Manager inicializado!")
	
	# Aguarda um frame para garantir que tudo está carregado
	await get_tree().process_frame
	
	# Implementa a estrutura solicitada
	setup_global_structure()
	
	# Conecta ao sinal de nós adicionados para interceptar novas cenas
	get_tree().node_added.connect(_on_node_added)
	
	print("✅ Estrutura PSX Global implementada!")
	print("📺 Estrutura: Root > PSXEffect > GameContent > CRTOverlay")
	print("🔄 Interceptação de novas cenas ativada!")

func setup_global_structure():
	"""Configura a estrutura global: Root > PSXEffect > GameContent + CRTOverlay"""
	
	# 1. Instancia o PSXEffect e adiciona ao Root
	if psx_effect_scene:
		psx_effect_node = psx_effect_scene.instantiate()
		get_tree().root.add_child(psx_effect_node)
		print("🎮 PSXEffect adicionado ao Root")
		
		# Obtém referência ao GameContent
		game_content_node = psx_effect_node.get_node("SubViewportContainer/SubViewport/GameContent")
		if game_content_node:
			print("📁 GameContent encontrado no PSXEffect")
		
	# 2. Move todas as cenas e managers para dentro do GameContent
	move_existing_scenes_to_game_content()
	move_managers_to_game_content()
	
	# 3. Instancia o CRTOverlay e adiciona ao PSXEffect (não ao Root)
	if crt_overlay_scene:
		crt_overlay_node = crt_overlay_scene.instantiate()
		psx_effect_node.add_child(crt_overlay_node)
		print("📺 CRTOverlay adicionado ao PSXEffect")
	
	# 4. Ativa a interceptação
	is_intercepting = true

func _on_node_added(node: Node):
	"""Intercepta quando novos nós são adicionados à árvore"""
	if not is_intercepting or not game_content_node:
		return
	
	# Verifica se o nó foi adicionado diretamente ao root
	if node.get_parent() == get_tree().root:
		# Verifica se não é um dos nossos nós ou um autoload do root
		if node != psx_effect_node and node != crt_overlay_node and not is_root_autoload(node) and node != self:
			print("🔄 Nova cena/nó detectado no Root: ", node.name)
			
			# Aguarda um frame para garantir que está completamente carregado
			await get_tree().process_frame
			
			# Move para GameContent
			if node.get_parent() == get_tree().root:  # Verifica novamente se ainda está no root
				print("🎬 Movendo para GameContent: ", node.name)
				get_tree().root.remove_child(node)
				game_content_node.add_child(node)
				
				# Atualiza current_scene se necessário
				if get_tree().current_scene == node:
					print("🎯 Atualizando current_scene para a nova localização")

func move_existing_scenes_to_game_content():
	"""Move todas as cenas existentes para o GameContent"""
	if not game_content_node:
		print("⚠️ GameContent não encontrado!")
		return
	
	var root = get_tree().root
	var scenes_to_move = []
	
	# Coleta todas as cenas que devem ser movidas
	for child in root.get_children():
		# Não move o próprio manager, PSXEffect, CRTOverlay ou autoloads do root
		if child != self and child != psx_effect_node and child != crt_overlay_node and not is_root_autoload(child):
			scenes_to_move.append(child)
	
	# Move as cenas coletadas
	for scene in scenes_to_move:
		print("🎬 Movendo cena para GameContent: ", scene.name)
		root.remove_child(scene)
		game_content_node.add_child(scene)
	
	print("✅ ", scenes_to_move.size(), " cenas movidas para GameContent")

func move_managers_to_game_content():
	"""Move os managers específicos para o GameContent"""
	if not game_content_node:
		print("⚠️ GameContent não encontrado!")
		return
	
	var root = get_tree().root
	var managers_moved = 0
	
	# Move cada manager que deve estar no GameContent
	for manager_name in game_content_managers:
		var manager = root.get_node_or_null(manager_name)
		if manager:
			print("🎮 Movendo manager para GameContent: ", manager_name)
			root.remove_child(manager)
			game_content_node.add_child(manager)
			managers_moved += 1
	
	print("✅ ", managers_moved, " managers movidos para GameContent")

func is_root_autoload(node: Node) -> bool:
	"""Verifica se um nó é um autoload que deve ficar no Root"""
	return node.name in root_autoloads

func add_scene_to_game_content(scene: Node):
	"""Adiciona uma nova cena ao GameContent"""
	if game_content_node and scene:
		game_content_node.add_child(scene)
		print("🎬 Cena adicionada ao GameContent: ", scene.name)

func get_psx_effect() -> Control:
	"""Retorna referência ao PSXEffect"""
	return psx_effect_node

func get_crt_overlay() -> CanvasLayer:
	"""Retorna referência ao CRTOverlay"""
	return crt_overlay_node

func get_game_content() -> Node:
	"""Retorna referência ao GameContent"""
	return game_content_node

# Debug da estrutura
func debug_structure():
	"""Mostra a estrutura atual no console"""
	print("========================================")
	print("🔍 DEBUG - ESTRUTURA GLOBAL")
	print("========================================")
	
	var root = get_tree().root
	print("Root (", root.name, "):")
	
	# Lista autoloads no Root
	print("\n📌 Autoloads no Root:")
	for child in root.get_children():
		if is_root_autoload(child):
			print("  ├── ", child.name, " (Autoload)")
	
	# Lista PSXEffect e seu conteúdo
	if psx_effect_node:
		print("\n🎮 PSXEffect:")
		print("  └── SubViewportContainer")
		print("      └── SubViewport")
		print("          └── GameContent:")
		
		if game_content_node:
			# Lista managers no GameContent
			print("\n            📊 Managers:")
			for child in game_content_node.get_children():
				if child.name in game_content_managers:
					print("              ├── ", child.name, " (Manager)")
			
			# Lista cenas no GameContent
			print("\n            🎬 Cenas:")
			for child in game_content_node.get_children():
				if not child.name in game_content_managers:
					print("              ├── ", child.name)
	
	# Lista CRTOverlay
	if crt_overlay_node:
		print("\n📺 CRTOverlay")
	
	print("\n========================================")
	print("🎯 Current Scene: ", get_tree().current_scene.name if get_tree().current_scene else "Nenhuma")
	print("📍 Current Scene Parent: ", get_tree().current_scene.get_parent().name if get_tree().current_scene and get_tree().current_scene.get_parent() else "Nenhum")
	print("========================================")

# Input para debug
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F5:
				debug_structure() 