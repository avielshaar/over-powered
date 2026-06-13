extends CharacterBody2D

const PUNCH_FRICTION = 2500.0

var health = 100
var default_color = Color(0, 0, 1, 1) # Blue
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 2.0

@onready var color_rect = $ColorRect

func _physics_process(delta):
	# Apply gravity if not on the floor
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Apply friction to bring velocity back to zero (useful for knockbacks later)
	velocity.x = move_toward(velocity.x, 0, PUNCH_FRICTION * delta)

	move_and_slide()

func take_damage(amount):
	health -= amount
	print("Hit! Dummy health: ", health)
	
	# White flash for hit feedback
	color_rect.color = Color(1, 1, 1, 1) 
	await get_tree().create_timer(0.1).timeout
	color_rect.color = default_color
	
	if health <= 0:
		print("Dummy Defeated!")
		queue_free() # Remove the object from the scene