/// CC iframe view (SG-008-b11 v1.4 — issue 1).
///
/// Lobby 가 "Enter CC" 클릭 시 fullscreen Dialog 안에서 CC 를 iframe 으로 임베드.
/// 사용자 의도: "해당 로비에 해당 cc 를 선택해서 진행중이라는 상호작용" — lobby UI
/// 가 dialog 뒤에 보존되어 active 상태 시각 표현.
///
/// Web: HtmlElementView + IFrameElement. Desktop: stub (placeholder text).
library;

import 'package:flutter/material.dart';

import 'cc_iframe_view_stub.dart'
    if (dart.library.html) 'cc_iframe_view_web.dart' as impl;

class CcIframeView extends StatelessWidget {
  const CcIframeView({super.key, required this.url, this.tableId});
  final String url;
  final int? tableId;

  @override
  Widget build(BuildContext context) => impl.buildCcIframe(url, tableId: tableId);
}
