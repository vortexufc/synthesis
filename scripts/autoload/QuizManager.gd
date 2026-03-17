extends Node

var questions = [
	{
		"question": "Quanto é 2 + 2?",
		"options": ["1", "2", "3", "4"],
		"answer": 3
	},
	{
		"question": "Capital do Brasil?",
		"options": ["Rio", "Brasília", "São Paulo", "Salvador"],
		"answer": 1
	},
	{
		"question": "Quanto é 5 * 3?",
		"options": ["10", "15", "20", "8"],
		"answer": 1
	}
]

var shuffled_questions = []
var current_index = 0

func _ready():
	randomize()
	reset_questions()

func reset_questions():
	shuffled_questions = questions.duplicate()
	shuffled_questions.shuffle()
	current_index = 0

func get_random_question():

	if current_index >= shuffled_questions.size():
		print("acabaram as perguntas")
		return null
	
	var q = shuffled_questions[current_index]
	current_index += 1
	
	return q
