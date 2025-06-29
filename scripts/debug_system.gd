extends Node

# Script de debug para testar sistemas de presentes e fantasmas

func _ready():
	print("🐛 [DEBUG] Sistema de debug inicializado")
	call_deferred("debug_systems")

func debug_systems():
	await get_tree().process_frame
	
	print("🔍 [DEBUG] ===== INICIANDO DIAGNÓSTICO =====")
	
	# Debug do player
	debug_player()
	
	# Debug dos presentes
	debug_gifts()
	
	# Debug dos fantasmas
	debug_ghosts()
	
	print("🔍 [DEBUG] ===== DIAGNÓSTICO CONCLUÍDO =====")

func debug_player():
	print("👤 [DEBUG] === DIAGNÓSTICO DO PLAYER ===")
	
	var players = get_tree().get_nodes_in_group("player")
	print("👤 [DEBUG] Players encontrados: ", players.size())
	
	for player in players:
		print("👤 [DEBUG] Player: ", player.name)
		print("👤 [DEBUG] Collision Layer: ", player.collision_layer)
		print("👤 [DEBUG] Collision Mask: ", player.collision_mask)
		print("👤 [DEBUG] Grupos: ", player.get_groups())
		print("👤 [DEBUG] Posição: ", player.global_position)

func debug_gifts():
	print("🎁 [DEBUG] === DIAGNÓSTICO DOS PRESENTES ===")
	
	# Procura por CollectibleItems
	var collectibles = find_nodes_by_script("scripts/items/CollectibleItem.gd")
	print("🎁 [DEBUG] CollectibleItems encontrados: ", collectibles.size())
	
	for item in collectibles:
		print("🎁 [DEBUG] Item: ", item.name)
		print("🎁 [DEBUG] Collision Layer: ", item.collision_layer)
		print("🎁 [DEBUG] Collision Mask: ", item.collision_mask)
		print("🎁 [DEBUG] Monitoring: ", item.monitoring)
		print("🎁 [DEBUG] Posição: ", item.global_position)
		print("🎁 [DEBUG] Estágio: ", item.grief_stage if item.has_method("get") else "N/A")
	
	# Procura por Gifts
	var gifts = find_nodes_by_script("scripts/items/Gift.gd")
	print("🎁 [DEBUG] Gifts encontrados: ", gifts.size())
	
	for gift in gifts:
		print("🎁 [DEBUG] Gift: ", gift.name)
		print("🎁 [DEBUG] Collision Layer: ", gift.collision_layer)
		print("🎁 [DEBUG] Collision Mask: ", gift.collision_mask)
		print("🎁 [DEBUG] Monitoring: ", gift.monitoring)
		print("🎁 [DEBUG] Posição: ", gift.global_position)
	
	# Verifica GiftManager
	var gift_manager = get_node_or_null("/root/GiftManager")
	if gift_manager:
		print("🎁 [DEBUG] GiftManager encontrado: ✅")
		print("🎁 [DEBUG] Gifts atuais: ", gift_manager.get_all_gifts())
	else:
		print("🎁 [DEBUG] GiftManager encontrado: ❌")

func debug_ghosts():
	print("👻 [DEBUG] === DIAGNÓSTICO DOS FANTASMAS ===")
	
	# Procura por GhostBase
	var ghosts = find_nodes_by_script("scripts/enemies/GhostBase.gd")
	print("👻 [DEBUG] GhostBase encontrados: ", ghosts.size())
	
	for ghost in ghosts:
		print("👻 [DEBUG] Ghost: ", ghost.name)
		print("👻 [DEBUG] Collision Layer: ", ghost.collision_layer)
		print("👻 [DEBUG] Collision Mask: ", ghost.collision_mask)
		print("👻 [DEBUG] Posição: ", ghost.global_position)
		print("👻 [DEBUG] Velocidade: ", ghost.velocity)
		print("👻 [DEBUG] Speed: ", ghost.speed)
		print("👻 [DEBUG] NavigationAgent3D: ", ghost.navigation_agent != null)
		if ghost.navigation_agent:
			print("👻 [DEBUG] Nav Target: ", ghost.navigation_agent.target_position)
			print("👻 [DEBUG] Nav Finished: ", ghost.navigation_agent.is_navigation_finished())
		print("👻 [DEBUG] Movement State: ", ghost.movement_state if ghost.has_method("get") else "N/A")
	
	# Procura por ghost.gd (antigo)
	var old_ghosts = find_nodes_by_script("scripts/enemies/ghost.gd")
	print("👻 [DEBUG] Ghost antigos encontrados: ", old_ghosts.size())
	
	# Verifica NavigationRegion3D
	var nav_regions = get_tree().get_nodes_in_group("navigation")
	if nav_regions.size() == 0:
		# Procura manualmente
		nav_regions = []
		_find_navigation_regions(get_tree().current_scene, nav_regions)
	
	print("👻 [DEBUG] NavigationRegion3D encontrados: ", nav_regions.size())
	for region in nav_regions:
		print("👻 [DEBUG] NavRegion: ", region.name)
		print("👻 [DEBUG] Navigation Mesh: ", region.navigation_mesh != null)

func find_nodes_by_script(script_path: String) -> Array:
	var nodes = []
	var current_scene = get_tree().current_scene
	if current_scene:
		_find_nodes_by_script_recursive(current_scene, script_path, nodes)
	return nodes

func _find_nodes_by_script_recursive(node: Node, script_path: String, result: Array):
	if not node:
		return
		
	var script = node.get_script()
	if script and script.resource_path.ends_with(script_path):
		result.append(node)
	
	for child in node.get_children():
		if child:
			_find_nodes_by_script_recursive(child, script_path, result)

func _find_navigation_regions(node: Node, result: Array):
	if not node:
		return
		
	if node is NavigationRegion3D:
		result.append(node)
	
	for child in node.get_children():
		if child:
			_find_navigation_regions(child, result) 
