extends Control

@onready var music = $AudioStreamPlayer

func _ready():
	# Asegurarse de que el juego no esté pausado
	get_tree().paused = false
	music.play()
	$FinalScore.text = "SCORE: " + str(int(Global.score))

func _on_reintentar_button_pressed() -> void: #Que regrese al mapa para evitar ver la animación
	pass # Replace with function body.
	get_tree().change_scene_to_file("res://scenes/mapa.tscn")


func _on_menu_button_pressed() -> void: #Redirige al menú
	pass # Replace with function body.
	get_tree().change_scene_to_file("res://ui/menus/menú.tscn")
