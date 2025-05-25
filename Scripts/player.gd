extends CharacterBody2D

var wizard = false
var knight = true
var health = 100

@onready var wizard_stay_timer = $wizard_stay_timer
@onready var knight_stay_timer = $knight_stay_timer

func _physics_process(delta):
	#checking if ur a knight or a wizard
	if wizard:
		wiz_func()
	else:
		knight_func()
		
	print("Wizard: ", wizard, "Knight: ", knight)
	print("Wizard Time:", wizard_stay_timer.time_left, "Knight Time: ", knight_stay_timer.time_left)

func knight_func():
	if not knight_stay_timer.time_left:
		wizard_stay_timer.stop()
		knight_stay_timer.start()
	
	#change to wizard
	if Input.is_action_just_pressed("change"):
		knight = false
		wizard = true
		knight_stay_timer.stop()

func wiz_func():
	if not wizard_stay_timer.time_left:
		knight_stay_timer.stop()
		wizard_stay_timer.start()
	
	#change to knight
	if Input.is_action_just_pressed("change"):
		knight = true
		wizard = false
		wizard_stay_timer.stop()

func _on_wizard_stay_timer_timeout():
	knight = true
	wizard = false

func _on_knight_stay_timer_timeout():
	knight = false
	wizard = true
