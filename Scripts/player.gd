extends CharacterBody2D

const MAX_SPEED = 300.0
const ACCELERATION = 1500.0
const FRICTION = 1000.0
const AIR_CONTROL = 0.6  # Lower than 1.0 for less sharp air movement
const GRAVITY = 1200.0
const JUMP_FORCE = -400.0
const FALL_MULTIPLIER = 2.2
const LOW_JUMP_MULTIPLIER = 3.0
const COYOTE_TIME = 0.15
const JUMP_BUFFER_TIME = 0.15

var wizard = false
var knight = true
var health = 100
var coyote_time_left = 0.0
var jump_buffer_time_left = 0.0
var mouse_pos

@onready var wizard_stay_timer = $wizard_stay_timer
@onready var knight_stay_timer = $knight_stay_timer
@onready var knight_hitbox = $knightHitbox
@onready var wizard_hitbox = $wizardHitbox
@onready var player = $"."

func _physics_process(delta):
	#checking if ur a knight or a wizard
	if wizard:
		wiz_func()
	else:
		knight_func()
		
	mouse_pos = get_global_mouse_position()
	
	if Input.is_action_just_pressed("basic_attack"):
		attack()
		
	_handle_timers(delta)
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement(delta)
	move_and_slide()

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

func _handle_timers(delta: float) -> void:
	if is_on_floor():
		coyote_time_left = COYOTE_TIME
	else:
		coyote_time_left -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_time_left = JUMP_BUFFER_TIME
	else:
		jump_buffer_time_left -= delta

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		if velocity.y > 0:
			# Falling — heavier gravity
			velocity.y += GRAVITY * FALL_MULTIPLIER * delta
		elif velocity.y < 0 and not Input.is_action_pressed("jump"):
			# Letting go early — shorter jump
			velocity.y += GRAVITY * LOW_JUMP_MULTIPLIER * delta
		else:
			# Rising normally
			velocity.y += GRAVITY * delta
	else:
		# Reset vertical velocity on floor
		velocity.y = 0
		
func _handle_jump() -> void:
	if jump_buffer_time_left > 0 and coyote_time_left > 0:
		velocity.y = JUMP_FORCE
		jump_buffer_time_left = 0
		coyote_time_left = 0
		
func _handle_movement(delta: float) -> void:
	var input_direction := Input.get_axis("left", "right")

	var target_speed = input_direction * MAX_SPEED
	var acceleration_rate = ACCELERATION if is_on_floor() else ACCELERATION * AIR_CONTROL

	if input_direction != 0:
		velocity.x = move_toward(velocity.x, target_speed, acceleration_rate * delta)
	else:
		# Decelerate toward 0
		var friction_rate = FRICTION if is_on_floor() else FRICTION * AIR_CONTROL
		velocity.x = move_toward(velocity.x, 0, friction_rate * delta)

func attack():
	if knight:
		knight_hitbox.disabled = false
		if mouse_pos.x < player.global_position.x:
			knight_hitbox.global_position.x = player.global_position.x - 128
		elif mouse_pos.x > player.global_position.x:
			knight_hitbox.global_position.x = player.global_position.x + 128
		knight_hitbox.disabled = true
	elif wizard:
		wizard_hitbox.disabled = false
