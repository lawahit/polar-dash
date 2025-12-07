extends Panel

var dialogos = [
	"¡Ah caray! Ese ruido no suena a viento… ¿qué está detrás de mí?",
	"¡Oye, pingüinito! ¡Vengo por ti! Tengo muuucha hambre.",
	"¡¿Qué?! ¡No no no! ¡Yo no quiero ser desayuno de nadie!",
	"Tranquilo, solo quiero hablar… ¡y comerte después!",
	"¡Eso no me tranquiliza! ¡Mis patitas cortas no podrán correr tanto!",
	"Pues apúrate, que ya casi te alcanzo…",
	"¡Ni lo sueñes! ¡Soy pequeño, pero soy rápido! ¡A ver si me alcanzas!",
	"¡Ya veremos, pingüinito sabrosito!"
]

var indice = 0
var tiempo_entre_dialogos := 2.5  # ← Ajusta el tiempo aquí (segundos)

func _ready():
	mostrar_dialogo()
	avanzar_automatico()

func mostrar_dialogo():
	$Label.text = dialogos[indice]

func avanzar_automatico():
	await get_tree().create_timer(tiempo_entre_dialogos).timeout
	avanzar_dialogo()

func avanzar_dialogo():
	indice += 1

	if indice >= dialogos.size():
		hide() # Se oculta al terminar
	else:
		mostrar_dialogo()
		avanzar_automatico() # ← Vuelve a llamar el autoavance
