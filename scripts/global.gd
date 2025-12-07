extends Node


var score := 0.0
var high_score := 0.0

const SAVE_PATH = "user://savegame.save"

func _ready():
	load_score()

func check_high_score():
	if score > high_score:
		high_score = score
		save_score()

func save_score():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(high_score)
		print("Score saved: ", high_score)

func load_score():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			high_score = file.get_var()
			print("Score loaded: ", high_score)
	else:
		print("No save file found.")
