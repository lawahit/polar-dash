extends TextureRect

func _ready():
    texture = load("res://assets/gameover.png")
    stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    custom_minimum_size = Vector2(600, 400) # Ajusta según necesites
    
    # Centrar en la pantalla
    anchor_left = 0.5
    anchor_top = 0.5
    anchor_right = 0.5
    anchor_bottom = 0.5
    offset_left = -300 # Mitad del ancho
    offset_top = -200 # Mitad del alto
    offset_right = 300
    offset_bottom = 200