extends CharacterBody2D

@onready var hitbox_rect = $HitboxRect
@onready var color_rect = $ColorRect
@onready var health_bar = $HealthBar

var network_id = ""
var target_position = Vector2.ZERO

func _ready():
	target_position = position

func _physics_process(delta):
	position = position.lerp(target_position, 15.0 * delta)

func update_data(data: Dictionary):
	target_position.x = data.get("x", target_position.x)
	target_position.y = data.get("y", target_position.y)
	
	var facing = data.get("facing", "right")
	if facing == "right":
		hitbox_rect.position.x = 40
	else:
		hitbox_rect.position.x = -40
		
	# Sync initial health when spawned
	if data.has("health"):
		update_health(data.health)

func play_attack():
	hitbox_rect.show()
	await get_tree().create_timer(0.2).timeout
	hitbox_rect.hide()

func take_damage(_amount):
	Network.send_data("player_hit", {
		"target_id": network_id
	})

# --- UI & Network Feedback ---

func update_health(new_health):
	health_bar.value = new_health

func play_damage_effect():
	color_rect.color = Color(1, 1, 1, 1)
	await get_tree().create_timer(0.1).timeout
	color_rect.color = Color(0, 1, 0, 1)

func respawn():
	target_position = Vector2(576, 100)
	position = target_position
	health_bar.value = 100