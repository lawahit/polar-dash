extends CharacterBody2D

const SPEED = 295.0
const GRAVITY = 900.0

var player: Node2D = null  # Se llena cuando el jugador entra al Area2D

func _ready():
	add_to_group("enemy")
	# Conectar la señal de área de daño si existe
	if has_node("DamageArea"):
		$DamageArea.body_entered.connect(_on_damage_area_body_entered)

func _physics_process(delta: float) -> void:
	# gravedad
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if player:
		_follow_player()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED) # si no hay jugador, se detiene

	move_and_slide()


func _follow_player() -> void:
	var dir = sign(player.global_position.x - global_position.x)
	velocity.x = dir * SPEED

	# Si quieres que el enemigo mire al jugador
	scale.x = dir


# Señales del Area2D de detección
func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body

func _on_detection_area_body_exited(body):
	if body == player:
		player = null

# Señal para el área de daño (colisión directa)
func _on_damage_area_body_entered(body):
	if body.is_in_group("player"):
		# Enviar al jugador a Game Over - usar call_deferred para evitar problemas de física
		get_tree().call_deferred("change_scene_to_file", "res://GameOver.tscn")
