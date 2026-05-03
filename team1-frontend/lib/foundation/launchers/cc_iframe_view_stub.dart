/// Desktop stub — iframe 미지원 환경. 향후 webview_flutter 패키지로 교체.
library;

import 'package:flutter/material.dart';

Widget buildCcIframe(String url, {int? tableId}) {
  debugPrint('[cc_iframe][stub] desktop iframe placeholder url=$url table=$tableId');
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.open_in_new, size: 48),
        const SizedBox(height: 16),
        const Text('Desktop CC embedding is not yet wired.'),
        const SizedBox(height: 8),
        SelectableText(url, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
}
