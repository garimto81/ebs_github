/// Web-only implementation — opens CC URL in a new browser tab.
library;

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void launchTarget(String target, {required bool isWeb}) {
  html.window.open(target, '_blank');
}
