// test_driver/integration_driver.dart
//
// flutter drive 가 web target 에서 integration_test 를 실행할 때 필요한 entrypoint.
// 표준 boilerplate — 코드 변경 없음.

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
