import 'package:uuid/uuid.dart';

class UuidIdempotency {
  UuidIdempotency._();
  static const _uuid = Uuid();
  static String generate() => _uuid.v4();
  static const headerName = 'Idempotency-Key';
}
