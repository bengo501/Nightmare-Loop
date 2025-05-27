extends Control

# Referências para autoloads
@onready var game_manager = get_node("/root/GameManager")

# Referências aos controles
# VOLUME
@onready var master_volume_slider = $MenuContainer/VolumeSection/MasterVolume/MasterSlider
@onready var music_volume_slider = $MenuContainer/VolumeSection/MusicVolume/MusicSlider
@onready var sfx_volume_slider = $MenuContainer/VolumeSection/SFXVolume/SFXSlider
# GRAPHICS
@onready var fullscreen_checkbox = $MenuContainer/GraphicsSection/FullscreenToggle
# GAMEPLAY
@onready var invert_y_toggle = $MenuContainer/GameplaySection/InvertYToggle
@onready var mouse_sensitivity_slider = $MenuContainer/GameplaySection/MouseSensitivity/SensitivitySlider

# Button Container
@onready var apply_button = $MenuContainer/ButtonsContainer/ApplyButton
@onready var back_button = $MenuContainer/ButtonsContainer/BackButton

func _ready():
	connect_controls()
	load_settings()

func connect_controls():
	if master_volume_slider:
		master_volume_slider.value_changed.connect(_on_master_volume_changed)
	if music_volume_slider:
		music_volume_slider.value_changed.connect(_on_music_volume_changed)
	if sfx_volume_slider:
		sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	if fullscreen_checkbox:
		fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	if invert_y_toggle:
		invert_y_toggle.toggled.connect(_on_invert_y_toggled)
	if mouse_sensitivity_slider:
		mouse_sensitivity_slider.value_changed.connect(_on_mouse_sensitivity_changed)
	if apply_button:
		apply_button.pressed.connect(_on_apply_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func load_settings():
	var settings = game_manager.get_settings()
	if master_volume_slider:
		master_volume_slider.value = settings.get("master_volume", 1.0)
	if music_volume_slider:
		music_volume_slider.value = settings.get("music_volume", 1.0)
	if sfx_volume_slider:
		sfx_volume_slider.value = settings.get("sfx_volume", 1.0)
	if fullscreen_checkbox:
		fullscreen_checkbox.button_pressed = settings.get("fullscreen", false)
	if invert_y_toggle:
		invert_y_toggle.button_pressed = settings.get("invert_y", false)
	if mouse_sensitivity_slider:
		mouse_sensitivity_slider.value = settings.get("mouse_sensitivity", 1.0)

func _on_master_volume_changed(value: float):
	game_manager.set_master_volume(value)

func _on_music_volume_changed(value: float):
	game_manager.set_music_volume(value)

func _on_sfx_volume_changed(value: float):
	game_manager.set_sfx_volume(value)

func _on_fullscreen_toggled(button_pressed: bool):
	game_manager.set_fullscreen(button_pressed)

func _on_invert_y_toggled(button_pressed: bool):
	game_manager.set_invert_y(button_pressed)

func _on_mouse_sensitivity_changed(value: float):
	game_manager.set_mouse_sensitivity(value)

func _on_apply_pressed():
	game_manager.save_settings()
	print("[OptionsMenu] Configurações aplicadas!")

func _on_back_pressed():
	game_manager.save_settings()
	print("[OptionsMenu] Saindo do menu de opções!")
	# Aqui você pode chamar o UIManager para fechar o menu, se desejar:
	var ui_manager = get_node("/root/UIManager")
	ui_manager.hide_ui("options_menu") 
