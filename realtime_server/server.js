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

    players[ws.id] = { id: ws.id, x: 576, y: 100, state: "IDLE", facing: "right" };

    // Send the specific player ID and the full list
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
        }
    });

    ws.on('close', () => {
        console.log(`User disconnected: ${ws.id}`);
        delete players[ws.id];
        broadcast({ type: 'player_disconnected', data: ws.id });
    });
});

console.log('OverPowered raw WebSocket server running on port 3000');