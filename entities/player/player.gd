extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -500.0

var slow_timer := 0.0
var slow_force := 0.0

# --- SCORE ---
var last_x := 0.0

@onready var score_label = $ScoreLabel
@onready var anim = $AnimatedSprite2D # Referencia a la animación

func _ready():
	add_to_group("player")
	Global.score = 0
	last_x = global_position.x

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_salto") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var current_speed = SPEED

	if slow_timer > 0:
		current_speed -= slow_force
		slow_timer -= delta
		play_hurt()

	velocity.x = max(current_speed, 50)

	move_and_slide()

	var dx = global_position.x - last_x
	if dx > 0:
		Global.score += dx * 0.1
	last_x = global_position.x

	score_label.text = "SCORE: " + str(int(Global.score))

const PAUSE_SCENE = preload("res://ui/overlays/pausa.tscn")

func _on_button_pressed() -> void:
	var pause_instance = PAUSE_SCENE.instantiate()
	$CanvasLayer.add_child(pause_instance)
	pause_instance.process_mode = Node.PROCESS_MODE_ALWAYS # Importante para que funcione mientras el juego está pausado
	get_tree().paused = true

func apply_slow(amount: float, duration: float):
	slow_force = amount
	slow_timer = duration

# --- Nueva animación de daño ---
func play_hurt():
	anim.play("hurt")
	await get_tree().create_timer(0.3).timeout
	anim.play("default")
