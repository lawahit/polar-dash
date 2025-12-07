extends Control


# Función llamada cuando el primer botón ("Start Game") es presionado.
func _on_button_pressed() -> void:
	# Carga la escena 'mapa.tscn' y la convierte en la escena principal.
	# get_tree() obtiene el árbol de la escena actual.
	# change_scene_to_file() cambia a la nueva escena.
	get_tree().change_scene_to_file("res://intro.tscn")
	# NOTA IMPORTANTE: Asegúrate de que la ruta sea correcta. Si 'mapa.tscn' 
	# está en una subcarpeta, la ruta sería algo como "res://Scenes/mapa.tscn"

# Función llamada cuando el segundo botón ("Options") es presionado.
func _on_button_2_pressed() -> void:
	# Dejamos esta función vacía por ahora, tal como lo solicitaste.
	pass 

# Función llamada cuando el tercer botón ("Exit") es presionado.
func _on_button_3_pressed() -> void:
	# Sale del juego. Esto solo funciona en el juego exportado o ejecutado
	# desde Godot, no en el editor.
	get_tree().quit()
