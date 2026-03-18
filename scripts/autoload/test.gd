extends Node

func _ready():

	print("teste começou")

	for i in range(5):

		var q = QuizManager.get_random_question()

		print(q)
