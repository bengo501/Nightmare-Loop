extends CanvasLayer

func _ready():
    await get_tree().create_timer(2.0).timeout
    get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn") 