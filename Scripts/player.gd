extends CharacterBody2D

const MAX_SPEED = 300.0
const ACCELERATION = 1500.0
const FRICTION = 1000.0
const AIR_CONTROL = 0.6  
const GRAVITY = 1200.0
const JUMP_FORCE = -400.0
const FALL_MULTIPLIER = 2.2
const LOW_JUMP_MULTIPLIER = 3.0
const COYOTE_TIME = 0.15
const JUMP_BUFFER_TIME = 0.15
const ROLL_SPEED = 600.0
const ROLL_DURATION = 0.3
const ROLL_COOLDOWN = 1.0
const TELEPORT_DISTANCE = 200.0
const TELEPORT_COOLDOWN = 1.5
const TELEPORT_DELAY = 0.2  

var wizard = false
var teleport_cooldown_timer = 0.0
var knight = true
var health = 100
var coyote_time_left = 0.0
var jump_buffer_time_left = 0.0
var mouse_pos
var is_rolling = false
var roll_direction = Vector2.ZERO
var roll_timer = 0.0
var roll_cooldown_timer = 0.0
var is_teleporting = false
var teleport_target_position = Vector2.ZERO
var teleport_delay_timer = 0.0
var wiz_atack_charge_pos = 3

@onready var wizard_stay_timer = $wizard_stay_timer
@onready var knight_stay_timer = $knight_stay_timer
@onready var knight_hitbox = $knightHitbox
@onready var wizard_hitbox = $wizardHitbox
@onready var wizard_hitbox_2 = $wizardHitbox2
@onready var wizard_hitbox_3 = $wizardHitbox3
@onready var player = $"."

func _handle_roll(delta: float) -> void:
	if not knight:
		return  # Only knights can roll

	if is_rolling:
		roll_timer -= delta
		if roll_timer <= 0:
			is_rolling = false
			roll_cooldown_timer = ROLL_COOLDOWN
		else:
			velocity.x = roll_direction.x * ROLL_SPEED
		return  # Skip further input if rolling

	if roll_cooldown_timer > 0:
		roll_cooldown_timer -= delta

	if Input.is_action_just_pressed("roll") and roll_cooldown_timer <= 0 and is_on_floor():
		is_rolling = true
		roll_timer = ROLL_DURATION
		var input_dir = Input.get_axis("ui_left", "ui_right")
		if input_dir != 0:
			roll_direction = Vector2(input_dir, 0)
		else:
			roll_direction = Vector2(sign(velocity.x), 0)

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
	_handle_roll(delta) 
	_handle_movement(delta)
	move_and_slide()
	_handle_teleport(delta)


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
		if wiz_atack_charge_pos == 3:
			wizard_hitbox.global_position = mouse_pos
			wizard_hitbox.disabled = false
			wiz_atack_charge_pos = 2
		elif wiz_atack_charge_pos == 2:
			wizard_hitbox_2.global_position = mouse_pos
			wizard_hitbox_2.disabled = false
			wiz_atack_charge_pos = 1
		elif wiz_atack_charge_pos == 1:
			wizard_hitbox_3.global_position = mouse_pos
			wizard_hitbox_3.disabled = false
			wiz_atack_charge_pos  = 3

func _handle_teleport(delta: float) -> void:
	if not wizard:
		return  # Only wizards can teleport

	if teleport_cooldown_timer > 0:
		teleport_cooldown_timer -= delta

	if Input.is_action_just_pressed("roll") and teleport_cooldown_timer <= 0:
		var direction = (mouse_pos - global_position).normalized()
		global_position += direction * TELEPORT_DISTANCE
		teleport_cooldown_timer = TELEPORT_COOLDOWN
