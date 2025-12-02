import asyncio
import json
import websockets
import sys

async def test_server():
    uri = "ws://localhost:8080"
    
    print("Connecting Client A...")
    async with websockets.connect(uri) as client_a:
        # Client A Join
        await client_a.send(json.dumps({"tag": "Join", "name": "Client A"}))
        welcome_a = json.loads(await client_a.recv())
        print(f"Client A received: {welcome_a['tag']}")

        print("Connecting Client B...")
        async with websockets.connect(uri) as client_b:
            # Client B Join
            await client_b.send(json.dumps({"tag": "Join", "name": "Client B"}))
            welcome_b = json.loads(await client_b.recv())
            print(f"Client B received: {welcome_b['tag']}")
            
            # Consume ClientJoined on A
            msg_a = json.loads(await client_a.recv())
            print(f"Client A received: {msg_a['tag']} (Client B joined)")

            # Client A Broadcasts
            print("Client A broadcasting action...")
            # Use a valid action from BroadcastActionSchema to avoid polluting server state
            action = {"type": "REVEAL"}
            await client_a.send(json.dumps({"tag": "Broadcast", "payload": action}))

            # Client B should receive it
            msg_b = json.loads(await client_b.recv())
            print(f"Client B received: {msg_b['tag']}")
            if msg_b.get('payload') == action:
                print("SUCCESS: Client B received broadcast.")
            else:
                print(f"FAILURE: Payload mismatch. Got {msg_b.get('payload')}")
                sys.exit(1)

        print("Connecting Client C (Late Joiner)...")
        async with websockets.connect(uri) as client_c:
            # Client C Join
            await client_c.send(json.dumps({"tag": "Join", "name": "Client C"}))
            welcome_c = json.loads(await client_c.recv())
            print(f"Client C received: {welcome_c['tag']}")
            
            # Check History
            history = welcome_c.get('history', [])
            print(f"Client C History Length: {len(history)}")
            
            if len(history) >= 1 and history[-1] == action:
                 print("SUCCESS: Client C received history.")
            else:
                 print(f"FAILURE: History mismatch. Got {history}")
                 sys.exit(1)

if __name__ == "__main__":
    try:
        asyncio.run(test_server())
        print("ALL TESTS PASSED")
    except Exception as e:
        print(f"Test Failed: {e}")
        sys.exit(1)
