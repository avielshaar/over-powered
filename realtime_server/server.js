const { WebSocketServer } = require('ws');
const wss = new WebSocketServer({ port: 3000 });

let players = {};

function broadcast(data, excludeWs = null) {
    const message = JSON.stringify(data);
    wss.clients.forEach((client) => {
        if (client !== excludeWs && client.readyState === 1) { 
            client.send(message);
        }
    });
}

wss.on('connection', (ws) => {
    ws.id = Math.random().toString(36).substring(2, 10);
    console.log(`User connected: ${ws.id}`);

    // Added health parameter to the player object
    players[ws.id] = { id: ws.id, x: 576, y: 100, state: "IDLE", facing: "right", health: 100 };

    ws.send(JSON.stringify({ type: 'welcome', data: { id: ws.id, players: players } }));
    
    broadcast({ type: 'player_connected', data: players[ws.id] }, ws);

    ws.on('message', (message) => {
        const parsed = JSON.parse(message);
        
        if (parsed.type === 'player_movement') {
            if (players[ws.id]) {
                players[ws.id].x = parsed.data.x;
                players[ws.id].y = parsed.data.y;
                players[ws.id].state = parsed.data.state;
                players[ws.id].facing = parsed.data.facing;
                
                broadcast({ type: 'player_updated', data: players[ws.id] }, ws);
            }
        } else if (parsed.type === 'player_attack') {
            broadcast({ type: 'player_attacked', data: ws.id }, ws);
            
        } else if (parsed.type === 'player_hit') {
            const targetId = parsed.data.target_id;
            const damage = 20; // Server dictates the damage amount securely!

            if (players[targetId]) {
                players[targetId].health -= damage;
                console.log(`Player ${targetId} took ${damage} damage. Health: ${players[targetId].health}`);

                broadcast({ type: 'player_took_damage', data: { id: targetId, health: players[targetId].health } });

                if (players[targetId].health <= 0) {
                    console.log(`Player ${targetId} was defeated. Respawning...`);
                    players[targetId].health = 100; 
                    players[targetId].x = 576;      
                    players[targetId].y = 100;
                    
                    broadcast({ type: 'player_died', data: targetId });
                }
            }
        }
    });

    ws.on('close', () => {
        console.log(`User disconnected: ${ws.id}`);
        delete players[ws.id];
        broadcast({ type: 'player_disconnected', data: ws.id });
    });
});

console.log('OverPowered raw WebSocket server running on port 3000');