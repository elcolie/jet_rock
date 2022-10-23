import json


async def websocket_application(scope, receive, send):
    while True:
        event = await receive()

        if event["type"] == "websocket.connect":
            await send({"type": "websocket.accept"})

        if event["type"] == "websocket.disconnect":
            break

        if event["type"] == "websocket.receive":
            print(event)
            await send({"type": "websocket.send", "text": json.dumps(event)})
            # if event["text"] == "ping":
            #     await send({"type": "websocket.send", "text": "pong!"})
            # elif event["text"] == "sarit":
            #     await send({"type": "websocket.send", "text": "palm!"})
            # else:
            #     await send({"type": "websocket.send", "text": "oop!"})
