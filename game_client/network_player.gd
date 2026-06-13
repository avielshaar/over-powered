extends Node2D

@onready var hitbox_rect = $HitboxRect

func update_data(data: Dictionary):
	# Update position based on server data
	position.x = data.get("x", position.x)
	position.y = data.get("y", position.y)
	
	# Update hitbox direction
	var facing = data.get("facing", "right")
	if facing == "right":
		hitbox_rect.position.x = 40
	else:
		hitbox_rect.position.x = -40

func play_attack():
	# Flash the attack hitbox momentarily
	hitbox_rect.show()
	await get_tree().create_timer(0.2).timeout
	hitbox_rect.hide()