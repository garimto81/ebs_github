from datetime import datetime, timezone
import uuid


# Table events
TABLE_STATUS_CHANGED = "TableStatusChanged"
TABLE_PLAYERS_CHANGED = "TablePlayersChanged"
TABLE_SEATS_CHANGED = "TableSeatsChanged"
TABLE_SETTINGS_CHANGED = "TableSettingsChanged"
TABLE_RFID_STATUS = "TableRfidStatus"

# Hand events
HAND_STARTED = "HandStarted"
HAND_ACTION = "HandAction"
HAND_COMPLETED = "HandCompleted"

# Config events
CONFIG_CHANGED = "ConfigChanged"

# Operator events
OPERATOR_CONNECTED = "OperatorConnected"
OPERATOR_DISCONNECTED = "OperatorDisconnected"

# Subscribe/Unsubscribe
SUBSCRIBE = "Subscribe"
SUBSCRIBE_ACK = "SubscribeAck"
UNSUBSCRIBE = "Unsubscribe"


class WsMessage:
    """Standard WebSocket message envelope per API-05 §2."""

    def __init__(self, type: str, payload: dict, source_id: str = "bo"):
        self.type = type
        self.payload = payload
        self.timestamp = datetime.now(timezone.utc).strftime(
            "%Y-%m-%dT%H:%M:%S.%f"
        )[:-3] + "Z"
        self.source_id = source_id
        self.message_id = str(uuid.uuid4())

    def to_dict(self) -> dict:
        return {
            "type": self.type,
            "payload": self.payload,
            "timestamp": self.timestamp,
            "source_id": self.source_id,
            "message_id": self.message_id,
        }
