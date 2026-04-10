# PokerGFX Decompiled Archive

> **이 디렉토리는 git에 포함하지 않습니다** (저작권 보호)

## 디컴파일 정보

| 항목 | 값 |
|------|-----|
| **도구** | ILSpy CLI (ilspycmd v8.2.0.7535) |
| **SDK** | .NET SDK 6.0.428 |
| **소스** | `C:\Program Files\PokerGFX\Server\` |
| **일자** | 2026-02-12 |

## 바이너리 목록

| 디렉토리 | 원본 | 크기 | 난독화 |
|----------|------|:----:|:------:|
| `Server/` | PokerGFX-Server.exe | 355MB | O (ConfuserEx) |
| `Common/` | PokerGFX.Common.dll | 553KB | X |
| `ActionTracker/` | ActionTracker.exe | 8.8MB | 부분 |
| `GFXUpdater/` | GFXUpdater.exe | 56KB | X |

## 핵심 파일 위치

| 파일 | 경로 | LOC | 역할 |
|------|------|:---:|------|
| Tags.cs | Server/ (난독화) | 7,000+ | RFID 핵심 |
| gfx.cs | Server/ (난독화) | 8,121 | 그래픽 엔진 |
| render.cs | Server/ (난독화) | 2,474 | 렌더링 |
| core.cs | ActionTracker/ | 25,643 | 게임 로직 |
| ClientNetworkService.cs | ActionTracker/ | ~6,400 | 네트워크 메시지 |

## 재생성 방법

```powershell
dotnet tool install ilspycmd -g --version 8.2.0.7535

ilspycmd "C:\Program Files\PokerGFX\Server\PokerGFX-Server.exe" -p -o Server
ilspycmd "C:\Program Files\PokerGFX\Server\PokerGFX.Common.dll" -p -o Common
ilspycmd "C:\Program Files\PokerGFX\Server\ActionTracker.exe" -p -o ActionTracker
ilspycmd "C:\Program Files\PokerGFX\Server\GFXUpdater.exe" -p -o GFXUpdater
```
