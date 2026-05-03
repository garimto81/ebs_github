/// Desktop / non-web stub. Replace with shared_preferences for desktop persistence.
library;

import 'cc_settings_storage.dart' show CcLastSession;

CcLastSession? loadLastSession(String key) => null;
Future<void> saveLastSession(String key, CcLastSession s) async {}
Future<void> clearLastSession(String key) async {}
