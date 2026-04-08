export 'variant.dart';
export 'nlh.dart';

import 'variant.dart';
import 'nlh.dart';

/// Registry of available game variants by identifier.
final Map<String, Variant Function()> variantRegistry = {
  'nlh': () => Nlh(),
};
