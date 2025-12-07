extends Control

# Referencias a los botones (actualizadas para coincidir con la escena)
@onready var btn_continue = $VBoxContainer/Button
@onready var btn_menu = $VBoxContainer/Button2
@onready var btn_exit = $VBoxContainer/Button3

func _ready():
	# No ocultamos ni pausamos aquí porque al cambiar de escena, esta SERÁ la escena visible.
	# Si ocultamos, la pantalla se queda negra.
	pass

func _input(event):
	# Detectar cuando se presiona ESC 
	if event.is_action_pressed("ui_cancel"):
		_on_button_pressed() # Volver al juego

# --- Señales conectadas desde el editor (pausa.tscn) ---

# Botón "Continue"
func _on_button_pressed() -> void:
	# Como cambiaste de escena, necesitamos volver a cargar el nivel del jugador
	# OJO: Esto reiniciará el nivel. Si querías un menú de pausa sobre el juego,
	# no deberías usar change_scene_to_file, sino instanciar este menú sobre el jugador.
	# Por ahora, volvemos a cargar el player.tscn
	get_tree().change_scene_to_file("res://scenes/mapa.tscn")

# Botón "Menu"
func _on_button_2_pressed() -> void:
	# Ir al menú principal
	get_tree().change_scene_to_file("res://ui/menus/menú.tscn")

# Botón "Exit"
func _on_button_3_pressed() -> void:
	get_tree().quit()