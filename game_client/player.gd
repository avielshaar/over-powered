extends CharacterBody2D

const MAX_SPEED = 400.0
const ACCELERATION = 2000.0
const FRICTION = 2500.0
const JUMP_VELOCITY = -700.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 2.0 

enum State { IDLE, RUN, JUMP, ATTACK }
var current_state = State.IDLE
var is_attacking = false

@onready var hitbox = $Hitbox

func _ready():
	hitbox.hide()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	match current_state:
		State.IDLE, State.RUN, State.JUMP:
			handle_movement(delta)
		State.ATTACK:
			handle_attack(delta)

	move_and_slide()
	update_state()
	
	# משדר את הנתונים לשרת בכל פריים
	broadcast_data()

func handle_movement(delta):
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		current_state = State.JUMP

	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, ACCELERATION * delta)
		
		# כיוון ה-Hitbox
		if direction > 0:
			hitbox.position.x = 40 
		elif direction < 0:
			hitbox.position.x = -40 
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	if Input.is_action_just_pressed("ui_accept") and not is_attacking:
		current_state = State.ATTACK

func handle_attack(_delta):
	if is_attacking:
		return
		
	is_attacking = true
	velocity.x = 0 
	
	hitbox.show()
	hitbox.monitoring = true
	
	# משדר לשרת שהשחקן התחיל תקיפה
	Network.send_data("player_attack", {})
	
	await get_tree().physics_frame
	
	var overlapping_bodies = hitbox.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.has_method("take_damage") and body != self:
			body.take_damage(20)
	
	await get_tree().create_timer(0.2).timeout
	
	hitbox.hide()
	hitbox.monitoring = false
	is_attacking = false
	current_state = State.IDLE

func update_state():
	if current_state == State.ATTACK:
		return
	if not is_on_floor():
		current_state = State.JUMP
	elif velocity.x != 0:
		current_state = State.RUN
	else:
		current_state = State.IDLE

# הפונקציה החדשה שאוספת את הנתונים ושולחת אותם
func broadcast_data():
	var facing = "right" if hitbox.position.x > 0 else "left"
	var state_name = State.keys()[current_state]
	
	Network.send_data("player_movement", {
		"x": position.x,
		"y": position.y,
		"state": state_name,
		"facing": facing
	})