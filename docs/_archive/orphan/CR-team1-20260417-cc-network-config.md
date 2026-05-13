---
title: "CR: Team4 CC boApiClientProvider localhost 하드코딩 제거"
author: team1
risk: MEDIUM
affected_teams: [team4]
created: 2026-04-17
---

# CR: Team4 CC REST API 네트워크 설정 수정

## 배경
Team4 CC의 `boApiClientProvider`가 `LaunchConfig.boBaseUrl`을 무시하고 `http://localhost:8000`으로 하드코딩되어 있어 LAN/WAN 배포 시 REST API 연결 불가.

## 현재 상태
파일: `team4-cc/src/lib/data/remote/bo_api_client.dart` (line ~243)
```dart
final boApiClientProvider = Provider<BoApiClient>((ref) {
  return BoApiClient(baseUrl: 'http://localhost:8000');  // HARDCODED
});
```

## 요청 변경
```dart
final boApiClientProvider = Provider<BoApiClient>((ref) {
  final config = ref.watch(launchConfigProvider);
  return BoApiClient(baseUrl: config?.boBaseUrl ?? 'http://localhost:8000');
});
```

## 영향
- WS는 이미 LaunchConfig에서 읽음 (정상)
- REST만 수정 필요
- 하위 호환: LaunchConfig 없으면 기존 localhost fallback

## 리스크
MEDIUM — 비파괴적 수정, 영향팀 1개 (team4)
