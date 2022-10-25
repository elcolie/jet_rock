import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer

logger = logging.getLogger(__name__)

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_name = self.scope["url_route"]["kwargs"]["room_name"]
        self.room_group_name = "chat_%s" % self.room_name

        if self.room_name == 'zeroth':
            # Join room group
            await self.channel_layer.group_add(self.room_group_name, self.channel_name)

            await self.accept()
        else:
            logger.info(f"{self.room_name} closed connection")
            await self.close()

    async def disconnect(self, close_code):
        # Leave room group
        logger.info("disconnected")
        await self.channel_layer.group_discard(self.room_group_name, self.channel_name)

    # Receive message from WebSocket
    async def receive(self, text_data):
        logger.info(text_data)
        # text_data_json = json.loads(text_data)
        # message = text_data_json["message"]
        # logger.info(f"receive: {message}")

        # Send message to room group
        await self.channel_layer.group_send(
            self.room_group_name, {"type": "chat_message", "message": text_data}
        )

    # Receive message from room group
    async def chat_message(self, event):
        message = event["message"]
        logger.info(f"chat_message: {message}")
        # Send message to WebSocket
        await self.send(text_data=json.dumps({"message": message}))
