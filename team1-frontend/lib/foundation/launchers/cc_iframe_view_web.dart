/// Web iframe 구현 — HtmlElementView + dart:ui_web platformViewRegistry.
library;

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: depend_on_referenced_packages
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

final Set<String> _registeredFactories = <String>{};

Widget buildCcIframe(String url, {int? tableId}) {
  // 각 url 마다 unique factory key (재진입 시 새 iframe 생성 보장).
  final key = 'cc-iframe-${url.hashCode}';
  if (!_registeredFactories.contains(key)) {
    ui_web.platformViewRegistry.registerViewFactory(key, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true;
      return iframe;
    });
    _registeredFactories.add(key);
  }
  return HtmlElementView(viewType: key);
}
