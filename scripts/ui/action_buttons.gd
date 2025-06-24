extends HBoxContainer

signal skills_pressed
signal talk_pressed
signal gifts_pressed
signal flee_pressed
signal next_pressed

@onready var skills_button = $SkillsButton
@onready var talk_button = $TalkButton
@onready var gifts_button = $GiftsButton
@onready var flee_button = $FleeButton
@onready var next_button = $NextButton

func _ready():
	skills_button.pressed.connect(emit_signal.bind("skills_pressed"))
	talk_button.pressed.connect(emit_signal.bind("talk_pressed"))
	gifts_button.pressed.connect(emit_signal.bind("gifts_pressed"))
	flee_button.pressed.connect(emit_signal.bind("flee_pressed"))
	next_button.pressed.connect(emit_signal.bind("next_pressed"))

func set_buttons_enabled(enabled: bool):
	skills_button.disabled = not enabled
	talk_button.disabled = not enabled
	gifts_button.disabled = not enabled
	flee_button.disabled = not enabled
	next_button.disabled = not enabled
