# GroundGenerator.gd (Godot 4) - Corregido para errores de consola
extends Node2D

@export var curve: Curve2D                     # ← CORRECTO
@export var segment_width: int = 1024
@export var points_per_segment: int = 64
@export var ground_depth: int = 400
@export var segment_scene: PackedScene
@export var pool_size: int = 6

var pool: Array = []
var active_segments: Array = []
var player_node: Node = null

func _ready():
	assert(segment_scene != null, "Asigna segment_scene en el Inspector (GroundSegment.tscn)")

	# Crear curva con SOLO colinas (puntos fijos para relieve)
	if not curve or curve.get_point_count() == 0:
		curve = Curve2D.new()
		curve.clear_points()
		
		# Puntos SOLO para colinas suaves (X=avance, Y=altura positiva para ↑)
		# Colina 1: Subida y bajada suave
		curve.add_point(Vector2(0, 0))          # Inicio plano
		curve.set_point_out(0, Vector2(120, 0))
		
		curve.add_point(Vector2(350, 140))      # Cima colina 1
		curve.set_point_out(1, Vector2(0, -70))
		curve.set_point_in(1, Vector2(-120, 0))
		
		curve.add_point(Vector2(700, 0))        # Bajada a plano
		curve.set_point_out(2, Vector2(120, 0))
		curve.set_point_in(2, Vector2(-120, 0))
		
		# Colina 2: Otra colina para repetir en segmentos
		curve.add_point(Vector2(1050, 100))     # Subida colina 2
		curve.set_point_out(3, Vector2(0, -50))
		curve.set_point_in(3, Vector2(-120, 0))
		
		curve.add_point(Vector2(1400, 0))       # Bajada final (cubre ~1.5 segmentos)
		curve.set_point_out(4, Vector2(120, 0))
		curve.set_point_in(4, Vector2(-120, 0))
		
		print("¡Curva con colinas generada! Puntos: ", curve.get_point_count())

	# Intentar obtener nodo jugador (FIX: Usar current_scene.find_child para evitar error en root)
	player_node = get_parent().get_node_or_null("CharacterBody2D")
	if player_node == null:
		var current_scene = get_tree().current_scene
		if current_scene:
			player_node = current_scene.find_child("CharacterBody2D", true, false)
		if player_node == null:
			print("Advertencia: No se encontró 'CharacterBody2D'. El generador usará x=0 para reciclaje.")

	# Crear pool
	for i in range(pool_size):
		var seg = segment_scene.instantiate()
		seg.visible = true
		add_child(seg)
		pool.append(seg)

	# Crear segmentos iniciales
	var start_x = -segment_width
	for i in range(2):
		var x = start_x + i * segment_width
		var seg = _get_segment_from_pool()
		_configure_segment(seg, x)
		active_segments.append(seg)

func _physics_process(_delta):  # FIX: Renombrar a _delta para ignorar warning
	var cam_x = 0.0
	if player_node:
		cam_x = player_node.global_position.x

	_recycle_if_needed(cam_x)

func _get_segment_from_pool():
	if pool.is_empty():
		return segment_scene.instantiate()
	return pool.pop_back()

func _return_segment_to_pool(seg):
	pool.append(seg)

func _configure_segment(seg: Node, seg_x: float) -> void:
	# obtener baked points
	var baked := curve.get_baked_points()

	# si curva vacía → piso plano
	if baked.is_empty():
		var flat := PackedVector2Array()
		for i in range(points_per_segment + 1):
			var t = float(i) / points_per_segment
			flat.append(Vector2(lerp(0, segment_width, t), 0))
		baked = flat

	# muestrear puntos superiores
	var top_points := PackedVector2Array()
	for i in range(points_per_segment + 1):
		var t = float(i) / points_per_segment
		var x_local = lerp(0, segment_width, t)
		var sample = _sample_baked(baked, t)
		top_points.append(Vector2(x_local, sample.y))

	# construir polígono cerrado
	var poly := PackedVector2Array()
	for p in top_points:
		poly.append(p)

	poly.append(Vector2(segment_width, ground_depth))
	poly.append(Vector2(0, ground_depth))

	# asignar al segmento
	var poly_node: Polygon2D = seg.get_node("Polygon2D")
	var coll_node: CollisionPolygon2D = seg.get_node("CollisionPolygon2D")

	if poly_node: poly_node.polygon = poly
	if coll_node: coll_node.polygon = poly

	seg.position.x = seg_x

# interpolación de baked points
func _sample_baked(baked: PackedVector2Array, t: float) -> Vector2:
	if baked.size() == 0:
		return Vector2.ZERO

	var idx_f = t * (baked.size() - 1)
	var i0 = int(floor(idx_f))
	var i1 = min(i0 + 1, baked.size() - 1)
	var f = idx_f - i0

	return baked[i0].lerp(baked[i1], f)

func _recycle_if_needed(cam_x: float):
	if active_segments.is_empty():
		return

	var first = active_segments[0]
	var first_right = first.global_position.x + segment_width

	if cam_x - first_right > segment_width * 1.5:
		active_segments.remove_at(0)
		var last = active_segments[-1]
		var new_x = last.global_position.x + segment_width
		_configure_segment(first, new_x)
		active_segments.append(first)
