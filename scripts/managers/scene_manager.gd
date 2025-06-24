var scenes = {
	"splash_screen": "res://scenes/ui/splash_screen.tscn",
	"main_menu": "res://scenes/ui/main_menu.tscn",
	"world": "res://scenes/world.tscn",
	"battle": "res://scenes/BattleScene.tscn",
	"options_menu": "res://scenes/ui/options_menu.tscn",
	"pause_menu": "res://scenes/ui/pause_menu.tscn",
	"hud": "res://scenes/ui/hud.tscn",
	"game_over": "res://scenes/ui/game_over.tscn",
	"credits": "res://scenes/ui/credits.tscn"
}

func start_battle():
	# Troca para a cena de batalha
	if scenes.has("battle"):
		get_tree().change_scene_to_file(scenes["battle"])
	else:
		push_error("[SceneManager] Caminho da cena de batalha não encontrado!")
	# Atualiza o estado do jogo para BATTLE
	var state_manager = get_tree().get_root().get_node("/root/GameStateManager")
	if state_manager:
		state_manager.change_state(state_manager.GameState.BATTLE)
	else:
		push_error("[SceneManager] GameStateManager não encontrado no autoload/root!") 