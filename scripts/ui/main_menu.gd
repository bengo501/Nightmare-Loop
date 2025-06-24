extends Control

# Referências para autoloads
@onready var state_manager = get_node("/root/GameStateManager")
@onready var scene_manager = get_node("/root/SceneManager")
@onready var ui_manager = get_node("/root/UIManager")
@onready var game_manager = get_node("/root/GameManager")

var fade_rect: ColorRect = null

func _ready():
	if has_node("NewGameButton"):
		$NewGameButton.pressed.connect(_on_new_game_pressed)
	if has_node("OptionsButton"):
		$OptionsButton.pressed.connect(_on_options_pressed)
	if has_node("CreditsButton"):
		$CreditsButton.pressed.connect(_on_credits_pressed)
	if has_node("QuitButton"):
		$QuitButton.pressed.connect(_on_quit_pressed)

func _on_new_game_pressed():
	# Primeiro reseta o jogo
	game_manager.reset_game()
	# Exibe os slides da história antes de iniciar o jogo
	get_tree().change_scene_to_file("res://scenes/ui/story_slides.tscn")

func _show_fade_and_start_game():
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0,0,0,0)
	fade_rect.anchor_right = 1.0
	fade_rect.anchor_bottom = 1.0
	fade_rect.z_index = 1000
	add_child(fade_rect)
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.8)
	tween.tween_callback(Callable(self, "_on_fade_complete"))

func _on_fade_complete():
	queue_free()
	scene_manager.change_scene("world")
	state_manager.change_state(state_manager.GameState.PLAYING)

func _on_options_pressed():
	ui_manager.hide_ui("main_menu")
	ui_manager.show_ui("options_menu")

func _on_credits_pressed():
	ui_manager.show_ui("credits")

func _on_quit_pressed():
	get_tree().quit() 
