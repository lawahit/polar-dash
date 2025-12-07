extends Area2D

@export var slow_amount := 150.0
@export var slow_time := 0.5

@onready var sprite = $AnimatedSprite2D
@onready var timer = $Timer
var broken := false

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	sprite.connect("animation_finished", Callable(self, "_on_animation_finished"))

func _on_body_entered(body):
	if broken:
		return

	if body.is_in_group("player"):
		broken = true

		# Desacelerar jugador
		if body.has_method("apply_slow"):
			body.apply_slow(slow_amount, slow_time)

		# Reproducir animación de romperse
		sprite.play("break")

		# Desactivar colisión de forma segura
		$CollisionShape2D.set_deferred("disabled", true)

func _on_animation_finished():
	if sprite.animation == "break":
		queue_free()
