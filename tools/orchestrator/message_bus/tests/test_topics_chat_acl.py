"""Topic ACL — chat:* prefix + source='user' anti-spoofing."""
from tools.orchestrator.message_bus.topics import check_publish_acl


class TestChatPrefix:
    def test_chat_room_design_any_source_allowed(self):
        ok, _ = check_publish_acl("chat:room:design", "S2")
        assert ok is True

    def test_chat_room_blocker_any_source_allowed(self):
        ok, _ = check_publish_acl("chat:room:blocker", "S3")
        assert ok is True

    def test_chat_thread_allowed(self):
        ok, _ = check_publish_acl("chat:thread:rake-01", "S2")
        assert ok is True

    def test_chat_dm_allowed(self):
        ok, _ = check_publish_acl("chat:dm:S2-S3", "S2")
        assert ok is True


class TestUserSourceProtection:
    def test_session_cannot_spoof_user_source(self):
        ok, reason = check_publish_acl("chat:room:design", "user")
        assert ok is False
        assert "reserved" in reason.lower()

    def test_chat_server_can_publish_as_user(self):
        ok, _ = check_publish_acl(
            "chat:room:design", "user", publisher_id="chat-server"
        )
        assert ok is True

    def test_random_publisher_id_rejected(self):
        ok, reason = check_publish_acl(
            "chat:room:design", "user", publisher_id="hacker"
        )
        assert ok is False
        assert "not authorized" in reason.lower()


class TestExistingBehaviorPreserved:
    def test_cascade_still_open(self):
        ok, _ = check_publish_acl("cascade:Foundation.md", "S2")
        assert ok is True

    def test_bus_still_reserved(self):
        ok, _ = check_publish_acl("bus:internal", "S2")
        assert ok is False

    def test_unknown_prefix_still_denied(self):
        ok, _ = check_publish_acl("unknown:topic", "S2")
        assert ok is False

    def test_stream_source_match_required(self):
        ok, _ = check_publish_acl("stream:S2", "S2")
        assert ok is True
        ok, _ = check_publish_acl("stream:S2", "S3")
        assert ok is False
