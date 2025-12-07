# Terreno Procedural con Curvas Suaves
# ------------------------------------------------------------------------------
# Genera un suelo infinito utilizando ruido aleatorio suavizado y ondas sinusoidales
# para crear colinas orgánicas y navegables.
# Utiliza Polygon2D con texturas tileables y gestión de memoria (pool) para rendimiento.
# ------------------------------------------------------------------------------
extends Line2D

# --- Parámetros de Generación de Terreno ---
# Controlan la suavidad y forma del terreno
var slice := 11 # Ancho de cada segmento en píxeles. Mayor = más polígonos pero menos puntos.
var max_dy := 3.0 # Variación máxima de altura aleatoria por segmento.
var segments_per_batch := 120 # Cantidad de puntos generados por cada "tramo" de terreno.
var smoothness := 0.85 # Factor de suavizado (lerp). Mayor (cercano a 1.0) = terreno más liso.
var terrain_height_limit := 1000 # Límite inferior de la altura del polígono (zona visual de tierra).
var bottom_margin := 8 # Margen de seguridad en la parte inferior de la pantalla.

# --- Control de Ondulación ---
# Define la forma general de las colinas usando ondas sinusoidales
var wave_amplitude := 1.5 # Altura de las ondas base.
var wave_frequency := 800.0 # Frecuencia de la onda. Mayor = colinas más anchas.
var random_influence := 0.4 # Peso de la aleatoriedad vs la onda suave (0.0 a 1.0).

var ground_texture: Texture2D = preload("res://assets/ice desert background/ground_textura_final.png") # Ruta a tu textura tileable (nieve/hierba). Renombrado para evitar conflicto con Line2D.texture.
var screensize: Vector2
var terrin: Array[Vector2] = []
var poly: PackedVector2Array # Array para polígono: usa PackedVector2Array (Godot 4 estándar).
var static_body: StaticBody2D
var shape: CollisionPolygon2D
var ground: Polygon2D
@onready var player = get_node("../CharacterBody2D")

# Variables para optimización
var barrels_pool: Array = [] # Pool de barriles reutilizables
var max_barrels_in_pool: int = 20 # Máximo de barriles en pool
var active_barrels: Array = [] # Barriles activos en escena
var barrel_scene = preload("res://entities/barrel/Barrel.tscn") # Precargar una vez
var last_cleanup_x: float = 0.0 # Última posición X donde se hizo limpieza
var cleanup_distance: float = 500.0 # Distancia entre limpiezas
var max_terrain_points: int = 1000 # Máximo de puntos de terreno a mantener
var terrain_cleanup_threshold: int = 500 # Cuántos puntos eliminar cuando se excede el máximo
var needs_polygon_rebuild: bool = false # Bandera para indicar que necesita reconstrucción

# Inicializa: aleatoriedad, pantalla, colisión estática y Polygon2D con textura tiled (eficiente, Godot 4).
func _ready():
	randomize()
	screensize = get_viewport().get_visible_rect().size
	static_body = StaticBody2D.new()
	shape = CollisionPolygon2D.new()
	static_body.add_child(shape)
	add_child(static_body)
	
	# Configura Polygon2D para textura: tiling vía texture_scale (pequeño = más tiles), offset para scroll infinito.
	ground = Polygon2D.new()
	ground.texture = ground_texture
	# Godot 4: no texture_mode; usa scale para tiling (0.08 = tiles ~12px si textura 96px).
	ground.texture_scale = Vector2(0.08, 0.08) # Ajusta para tu textura (más pequeño = tiles más finos/detallados).
	add_child(ground)
	
	# Precalentar pool de barriles
	prewarm_barrel_pool()
	
	generate_initial_terrain()

# Por frame: genera más si jugador cerca (lookahead 120% pantalla para cero pop-in).
func _process(_delta):
	if terrin.size() == 0 or player == null: return
	
	# Limpieza periódica de terreno y barriles fuera de pantalla
	if player.position.x - last_cleanup_x > cleanup_distance:
		cleanup_off_screen_elements()
		last_cleanup_x = player.position.x
	
	if terrin[-1].x < player.position.x + screensize.x * 1.2:
		add_hills()
	
	# Reconstruir polígono si es necesario (hacerlo en _process para evitar problemas de concurrencia)
	if needs_polygon_rebuild:
		rebuild_polygon_from_terrain()
		needs_polygon_rebuild = false

# Precalentar pool de barriles para reutilización
func prewarm_barrel_pool():
	for i in range(5): # Crear algunos barriles iniciales
		var barrel = barrel_scene.instantiate()
		barrel.visible = false
		barrel.process_mode = Node.PROCESS_MODE_DISABLED
		barrels_pool.append(barrel)
		get_tree().current_scene.add_child.call_deferred(barrel)

# Obtener un barril del pool o crear uno nuevo
func get_barrel_from_pool() -> Node:
	if barrels_pool.size() > 0:
		var barrel = barrels_pool.pop_back()
		barrel.process_mode = Node.PROCESS_MODE_INHERIT
		return barrel
	else:
		var barrel = barrel_scene.instantiate()
		get_tree().current_scene.add_child.call_deferred(barrel)
		return barrel

# Devolver un barril al pool cuando ya no se necesita
func return_barrel_to_pool(barrel: Node):
	if barrels_pool.size() < max_barrels_in_pool:
		barrel.visible = false
		barrel.process_mode = Node.PROCESS_MODE_DISABLED
		barrels_pool.append(barrel)
	else:
		barrel.queue_free() # Eliminar si el pool está lleno

# Limpiar elementos fuera de pantalla
func cleanup_off_screen_elements():
	if player == null:
		return
	
	var cleanup_x = player.position.x - screensize.x * 2 # 2 pantallas atrás
	
	# 1. Limpiar barriles fuera de pantalla
	for i in range(active_barrels.size() - 1, -1, -1):
		var barrel = active_barrels[i]
		if barrel and is_instance_valid(barrel):
			if barrel.position.x < cleanup_x:
				return_barrel_to_pool(barrel)
				active_barrels.remove_at(i)
	
	# 2. Limpiar puntos de terreno antiguos (mantener solo los últimos max_terrain_points)
	if terrin.size() > max_terrain_points:
		var points_to_remove = terrin.size() - max_terrain_points
		if points_to_remove > terrain_cleanup_threshold:
			points_to_remove = terrain_cleanup_threshold
		
		# Eliminar puntos del principio
		var removed_points = 0
		while removed_points < points_to_remove and terrin.size() > 10: # Mantener al menos 10 puntos
			terrin.remove_at(0)
			remove_point(0) # Line2D
			removed_points += 1
		
		# Marcar que necesitamos reconstruir el polígono
		needs_polygon_rebuild = true

# Reconstruir polígono después de eliminar puntos antiguos
func rebuild_polygon_from_terrain():
	if terrin.size() < 2:
		return
	
	# Limpiar polígono actual
	poly.clear()
	
	# Añadir todos los puntos de terreno
	for point in terrin:
		poly.append(point)
	
	# Cerrar polígono CORRECTAMENTE: desde el último punto hasta el fondo, luego al primer punto
	var left_x = terrin[0].x
	var right_x = terrin[-1].x
	var left_bottom = Vector2(left_x, screensize.y)
	var right_bottom = Vector2(right_x, screensize.y)
	
	# IMPORTANTE: El orden de los puntos debe ser correcto para un polígono cerrado
	# 1. Puntos de terreno (ya están en poly)
	# 2. Esquina inferior derecha
	poly.append(right_bottom)
	# 3. Esquina inferior izquierda
	poly.append(left_bottom)
	
	# Actualizar colisión y visual
	shape.polygon = poly
	ground.polygon = poly

# Inicial: limpia, Y start clamped, primer lote.
func generate_initial_terrain():
	terrin.clear()
	clear_points()
	poly.clear()
	active_barrels.clear()
	
	var min_y = screensize.y - terrain_height_limit
	var max_y = screensize.y - bottom_margin
	# Para inicio más plano: menos variación aleatoria inicial
	var start_y = clamp(screensize.y * 0.75 + (-50 + randi() % 100), min_y, max_y)
	var start = Vector2(0, start_y)
	terrin.append(start)
	add_point(start)
	poly.append(start)
	last_cleanup_x = start.x
	add_hills()

# Agrega terreno: random walk suavizado + onda para naturalidad, clamp Y, scroll textura, cierra colisión.
# Offset textura -= added para suelo "estacionario" en mundo infinito.
func add_hills():
	var min_y = screensize.y - terrain_height_limit
	var max_y = screensize.y - bottom_margin
	var start_x = terrin[-1].x # Para calcular added_length (scroll textura).
	var last = terrin[-1]
	var current_pos = last
	var prev_dy := 0.0 # Inicial para suavizado.
	
	# Limpiar puntos de cierre anteriores del polígono si existen
	# Buscar y eliminar puntos de cierre (puntos con Y en screensize.y)
	var cleanup_index = poly.size() - 1
	while cleanup_index >= 0 and poly.size() > terrin.size():
		if poly[cleanup_index].y == screensize.y:
			poly.remove_at(cleanup_index)
		cleanup_index -= 1
	
	for i in range(segments_per_batch):
		# Onda base más suave: frecuencia mayor y amplitud menor
		var wave = sin(current_pos.x / wave_frequency * 2 * PI) * wave_amplitude
		
		# Random con menos influencia para terreno más liso
		var random_component = randf_range(-max_dy, max_dy) * random_influence
		var target_dy = random_component + wave
		
		# Suavizado más fuerte para transiciones más graduales
		var dy = lerp(prev_dy, target_dy, smoothness)
		prev_dy = dy
		
		var y = current_pos.y + dy
		y = clamp(y, min_y, max_y)
		var x = current_pos.x + slice
		var p = Vector2(x, y)
		terrin.append(p)
		add_point(p)
		poly.append(p)
		current_pos = p
		
		# Generación de barriles: ~5% probabilidad por segmento
		if randi() % 50 == 0: # ~5% probabilidad
			var spawn_pos = p - Vector2(0, 20) # justo encima del piso
			spawn_barrel_at(spawn_pos)
	
	# Scroll textura: mueve offset X para tiles continuos sin costuras (ajusta factor si escala cambia).
	var added_length = terrin[-1].x - start_x
	ground.texture_offset.x -= added_length * ground.texture_scale.x # Factor escala para scroll preciso.
	
	# Cerrar polígono CORRECTAMENTE (mismo método que en rebuild_polygon_from_terrain)
	close_polygon()

# Función auxiliar para cerrar el polígono correctamente
func close_polygon():
	if terrin.size() < 2:
		return
	
	# Asegurarnos de que poly solo tiene puntos de terreno
	while poly.size() > terrin.size():
		poly.remove_at(poly.size() - 1)
	
	# Cerrar polígono
	var left_x = terrin[0].x
	var right_x = terrin[-1].x
	var left_bottom = Vector2(left_x, screensize.y)
	var right_bottom = Vector2(right_x, screensize.y)
	
	# Añadir puntos de cierre en el orden correcto
	poly.append(right_bottom)
	poly.append(left_bottom)
	
	# Actualizar colisión y visual
	shape.polygon = poly
	ground.polygon = poly

# Instancia un barril en la posición especificada (usando pool)
func spawn_barrel_at(pos: Vector2):
	var barrel = get_barrel_from_pool()
	barrel.position = pos
	barrel.visible = true
	active_barrels.append(barrel)

# Limpiar todo cuando la escena termina
func _exit_tree():
	# Limpiar todos los barriles
	for barrel in active_barrels:
		if is_instance_valid(barrel):
			barrel.queue_free()
	
	for barrel in barrels_pool:
		if is_instance_valid(barrel):
			barrel.queue_free()
	
	active_barrels.clear()
	barrels_pool.clear()
