// B-354: Legacy ID Redirect Validation
//
// Validates docs/_generated/legacy-id-redirect.json against:
//   1. JSON syntax + schema (required fields per mapping)
//   2. Duplicate keys in `mappings` block (raw-text scan)
//   3. Invalid path format (must match ^docs/.+\.md$)
//   4. Circular references in legacy_path → redirect_to graph
//
// Exit 0 on success, exit 1 on any failure with detailed stderr.
//
// Usage:
//   dart run tools/validate_redirects.dart                                   # default path
//   dart run tools/validate_redirects.dart docs/_generated/legacy-id-redirect.json
//   dart run tools/validate_redirects.dart path/to/mock_invalid.json

import 'dart:convert';
import 'dart:io';

const String _defaultPath = 'docs/_generated/legacy-id-redirect.json';

const Set<String> _requiredFields = {
  'title',
  'legacy_path',
  'redirect_to',
  'domain',
  'phase',
};

final RegExp _pathRegex = RegExp(r'^docs/.+\.md$');

void main(List<String> args) {
  final path = args.isNotEmpty ? args[0] : _defaultPath;

  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('FAIL: file not found: $path');
    exit(1);
  }

  final raw = file.readAsStringSync();
  final errors = <String>[];

  // Check 1 — JSON parse
  Map<String, dynamic> data;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      stderr.writeln('FAIL: top-level must be a JSON object');
      exit(1);
    }
    data = decoded;
  } catch (e) {
    stderr.writeln('FAIL: invalid JSON: $e');
    exit(1);
  }

  // Check 2 — top-level structure
  if (!data.containsKey('mappings')) {
    errors.add('top-level "mappings" key missing');
  }
  final mappingsRaw = data['mappings'];
  if (mappingsRaw is! Map<String, dynamic>) {
    errors.add('"mappings" must be a JSON object');
    _report(errors, 0);
  }
  final mappings = mappingsRaw as Map<String, dynamic>;

  // Check 3 — duplicate keys via raw-text scan
  errors.addAll(_findDuplicateMappingKeys(raw));

  // Check 4 — schema (required fields) + path format per mapping
  for (final entry in mappings.entries) {
    final id = entry.key;
    final value = entry.value;
    if (value is! Map<String, dynamic>) {
      errors.add('$id: mapping value must be a JSON object');
      continue;
    }
    final missing = _requiredFields.difference(value.keys.toSet());
    if (missing.isNotEmpty) {
      errors.add('$id: missing required fields: ${missing.toList()..sort()}');
    }
    final lp = value['legacy_path'];
    final rt = value['redirect_to'];
    if (lp is String && !_pathRegex.hasMatch(lp)) {
      errors.add('$id: invalid legacy_path format "$lp" (expected ^docs/.+\\.md\$)');
    }
    if (rt is String && !_pathRegex.hasMatch(rt)) {
      errors.add('$id: invalid redirect_to format "$rt" (expected ^docs/.+\\.md\$)');
    }
  }

  // Check 5 — circular references in legacy_path → redirect_to graph
  final graph = <String, String>{};
  final ownerById = <String, String>{}; // node path → owning legacy-id
  for (final entry in mappings.entries) {
    final value = entry.value;
    if (value is! Map<String, dynamic>) continue;
    final lp = value['legacy_path'];
    final rt = value['redirect_to'];
    if (lp is String && rt is String) {
      graph[lp] = rt;
      ownerById[lp] = entry.key;
    }
  }
  errors.addAll(_findCycles(graph, ownerById));

  _report(errors, mappings.length);
}

/// Detect duplicate keys at indent-4 inside the `"mappings": { ... }` block.
/// Standard JSON parsers silently keep the last value; this catches them upstream.
List<String> _findDuplicateMappingKeys(String raw) {
  final errors = <String>[];
  // Match: "mappings": {\n ... \n  }
  final blockRegex = RegExp(
    r'"mappings"\s*:\s*\{([\s\S]*?)\n  \}',
    multiLine: true,
  );
  final match = blockRegex.firstMatch(raw);
  if (match == null) return errors;
  final block = match.group(1) ?? '';
  // Top-level keys inside mappings appear at exactly 4 spaces indent.
  final keyRegex = RegExp(r'^    "([^"]+)"\s*:', multiLine: true);
  final counts = <String, int>{};
  for (final m in keyRegex.allMatches(block)) {
    final k = m.group(1)!;
    counts[k] = (counts[k] ?? 0) + 1;
  }
  for (final e in counts.entries) {
    if (e.value > 1) {
      errors.add('duplicate key "${e.key}" appears ${e.value} times in mappings block');
    }
  }
  return errors;
}

/// DFS cycle detection. Treats self-redirects (A.legacy_path == A.redirect_to) as 1-cycles.
List<String> _findCycles(Map<String, String> graph, Map<String, String> owner) {
  final errors = <String>[];
  final reported = <String>{};

  for (final start in graph.keys) {
    final path = <String>[];
    final seen = <String>{};
    String? current = start;
    while (current != null) {
      if (seen.contains(current)) {
        // Found a cycle — emit once per cycle by sorted starting node
        final cyclePath = [...path, current];
        final key = (cyclePath.toSet().toList()..sort()).join(',');
        if (!reported.contains(key)) {
          reported.add(key);
          final ids = cyclePath.map((p) => owner[p] ?? '?').toList();
          errors.add(
            'circular reference: ${ids.join(' -> ')} '
            '(path chain: ${cyclePath.join(' -> ')})',
          );
        }
        break;
      }
      seen.add(current);
      path.add(current);
      current = graph[current];
    }
  }
  return errors;
}

void _report(List<String> errors, int mappingCount) {
  if (errors.isEmpty) {
    stdout.writeln('OK: $mappingCount mappings validated (schema + paths + cycles)');
    exit(0);
  }
  stderr.writeln('FAIL: ${errors.length} validation error(s)');
  for (final e in errors) {
    stderr.writeln('  - $e');
  }
  exit(1);
}
