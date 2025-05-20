extends Control

# Referências aos elementos da UI
@onready var menu_container = $MenuContainer
@onready var master_slider = $MenuContainer/VolumeSection/MasterVolume/MasterSlider
@onready var music_slider = $MenuContainer/VolumeSection/MusicVolume/MusicSlider
@onready var sfx_slider = $MenuContainer/VolumeSection/SFXVolume/SFXSlider
@onready var fullscreen_toggle = $MenuContainer/GraphicsSection/FullscreenToggle
@onready var invert_y_toggle = $MenuContainer/GameplaySection/InvertYToggle
@onready var sensitivity_slider = $MenuContainer/GameplaySection/MouseSensitivity/SensitivitySlider
@onready var apply_button = $MenuContainer/ButtonsContainer/ApplyButton
@onready var back_button = $MenuContainer/ButtonsContainer/BackButton

# Configurações padrão
var default_settings = {
	"master_volume": 1.0,
	"music_volume": 1.0,
	"sfx_volume": 1.0,
	"fullscreen": false,
	"invert_y": false,
	"mouse_sensitivity": 1.0
}

# Configurações atuais
var current_settings = {}

func _ready():
	load_settings()
	apply_button.pressed.connect(_on_apply_pressed)
	back_button.pressed.connect(_on_back_pressed)
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	invert_y_toggle.toggled.connect(_on_invert_y_toggled)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	apply_settings()

func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		current_settings = {
			"master_volume": config.get_value("audio", "master_volume", default_settings.master_volume),
			"music_volume": config.get_value("audio", "music_volume", default_settings.music_volume),
			"sfx_volume": config.get_value("audio", "sfx_volume", default_settings.sfx_volume),
			"fullscreen": config.get_value("graphics", "fullscreen", default_settings.fullscreen),
			"invert_y": config.get_value("gameplay", "invert_y", default_settings.invert_y),
			"mouse_sensitivity": config.get_value("gameplay", "mouse_sensitivity", default_settings.mouse_sensitivity)
		}
	else:
		current_settings = default_settings.duplicate()
	update_ui()

func save_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", current_settings.master_volume)
	config.set_value("audio", "music_volume", current_settings.music_volume)
	config.set_value("audio", "sfx_volume", current_settings.sfx_volume)
	config.set_value("graphics", "fullscreen", current_settings.fullscreen)
	config.set_value("gameplay", "invert_y", current_settings.invert_y)
	config.set_value("gameplay", "mouse_sensitivity", current_settings.mouse_sensitivity)
	config.save("user://settings.cfg")

func update_ui():
	master_slider.value = current_settings.master_volume
	music_slider.value = current_settings.music_volume
	sfx_slider.value = current_settings.sfx_volume
	fullscreen_toggle.button_pressed = current_settings.fullscreen
	invert_y_toggle.button_pressed = current_settings.invert_y
	sensitivity_slider.value = current_settings.mouse_sensitivity

func apply_settings():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(current_settings.master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(current_settings.music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(current_settings.sfx_volume))
	if current_settings.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	# A sensibilidade do mouse e inversão do eixo Y devem ser aplicadas no script do jogador

func _on_master_volume_changed(value):
	current_settings.master_volume = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _on_music_volume_changed(value):
	current_settings.music_volume = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

func _on_sfx_volume_changed(value):
	current_settings.sfx_volume = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))

func _on_fullscreen_toggled(button_pressed):
	current_settings.fullscreen = button_pressed
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_invert_y_toggled(button_pressed):
	current_settings.invert_y = button_pressed

func _on_sensitivity_changed(value):
	current_settings.mouse_sensitivity = value

func _on_apply_pressed():
	apply_settings()
	save_settings()

func _on_back_pressed():
	get_node("/root/UIManager").hide_ui("options_menu") 
