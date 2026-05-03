/// Desktop / non-web stub. Replace with `package:url_launcher` integration
/// once team4 deep-link cascade is staffed. Currently logs target URL only.
library;

import 'package:flutter/foundation.dart' show debugPrint;

void launchTarget(String target, {required bool isWeb}) {
  debugPrint('[cc_launcher][stub] target=$target isWeb=$isWeb');
}
