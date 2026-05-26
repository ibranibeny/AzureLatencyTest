# Contract: WebSocket Echo Endpoint

**Protocol**: WebSocket (RFC 6455)  
**Port**: 8080  
**Path**: `/` (root)

## Connection

```
Client → Server: GET ws://<target-ip>:8080/ HTTP/1.1
                 Upgrade: websocket
                 Connection: Upgrade
                 Sec-WebSocket-Version: 13

Server → Client: HTTP/1.1 101 Switching Protocols
                 Upgrade: websocket
                 Connection: Upgrade
```

## Message Format

### Client → Server (text frame)

```json
{ "t": 1716710400000 }
```

| Field | Type | Description |
|-------|------|-------------|
| t | number | Client timestamp (`Date.now()`) at send time |

### Server → Client (text frame)

The server echoes the exact same message back without modification:

```json
{ "t": 1716710400000 }
```

## Measurement Protocol

1. Client opens WebSocket connection
2. On `open` event, client sends 3 sequential messages (wait for echo before sending next)
3. For each message: `RTT = Date.now() - JSON.parse(response).t`
4. Average of 3 RTTs = reported latency
5. Client closes connection

## Error Handling

| Scenario | Client Behavior |
|----------|----------------|
| Connection timeout (>5s) | Report status `timeout`, latencyMs = null |
| Connection refused | Report status `error`, latencyMs = null |
| Message not echoed within 3s | Report status `timeout` for that probe |
| WebSocket error event | Report status `error`, latencyMs = null |

## Server Constraints

- Max concurrent connections: 100
- No authentication required
- No message size validation (client sends <50 bytes)
- Server MUST NOT modify the message content
- Server MUST echo within 1ms of receiving (no processing delay)

## Security

- No origin checking (WebSocket is not subject to CORS)
- No sensitive data transmitted
- 1:1 echo ratio prevents amplification
- NSG limits port 8080 access (but allows from any source IP)
