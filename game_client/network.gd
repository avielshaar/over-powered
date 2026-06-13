extends Node

var socket = WebSocketPeer.new()
var is_connected = false

var network_player_scene = preload("res://network_player.tscn")
var network_players = {}
var arena_node = null
var local_player_id = ""

func _ready():
	var err = socket.connect_to_url("ws://localhost:3000")
	if err != OK:
		print("Failed to initiate connection.")
		set_process(false)

func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		if not is_connected:
			print("Connected to WebSocket Server!")
			is_connected = true
		
		while socket.get_available_packet_count() > 0:
			var packet = socket.get_packet()
			var json_str = packet.get_string_from_utf8()
			var json = JSON.new()
			var err = json.parse(json_str)
			if err == OK:
				handle_server_message(json.data)
				
	elif state == WebSocketPeer.STATE_CLOSED:
		if is_connected:
			print("Disconnected from server.")
			is_connected = false

func send_data(type: String, data_dict: Dictionary):
	if is_connected:
		var message = {
			"type": type,
			"data": data_dict
		}
		socket.send_text(JSON.stringify(message))

func handle_server_message(message: Dictionary):
	var type = message.get("type", "")
	var data = message.get("data", null)
	
	if not arena_node:
		arena_node = get_tree().root.get_node_or_null("Arena")
		if not arena_node:
			return
			
	match type:
		"welcome":
			local_player_id = data.id
			var current_players = data.players
			for p_id in current_players:
				# Spawn everyone EXCEPT the local player
				if p_id != local_player_id:
					spawn_network_player(p_id, current_players[p_id])
		"player_connected":
			if data.id != local_player_id:
				spawn_network_player(data.id, data)
		"player_updated":
			if network_players.has(data.id):
				network_players[data.id].update_data(data)
		"player_attacked":
			if network_players.has(data):
				network_players[data].play_attack()
		"player_disconnected":
			if network_players.has(data):
				network_players[data].queue_free()
				network_players.erase(data)

func spawn_network_player(p_id: String, data: Dictionary):
	if network_players.has(p_id):
		return
		
	var new_player = network_player_scene.instantiate()
	arena_node.add_child(new_player)
	new_player.update_data(data)
	network_players[p_id] = new_player