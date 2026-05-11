// ignore_for_file: avoid_print, avoid_dynamic_calls
/// Manual dev-tool: validates protocols.json against domain VO invariants,
/// uniqueness, shape parity, and (for the 3 fn-82 new entries) DOI/URL +
/// BMD scope-lock for D3+K2.
///
/// This is NOT a test target. It is a dev-tool invoked manually via:
///   dart run tool/verify_protocols_json.dart
///
/// Exit 0 on green, non-zero with per-entry diagnostics on any failure.
library;

import 'dart:convert';
import 'dart:io';
import 'package:neurostack/features/protocol/domain/value_objects/protocol_name.dart';
import 'package:neurostack/features/protocol/domain/value_objects/protocol_description.dart';
import 'package:neurostack/features/protocol/domain/value_objects/frequency.dart';
import 'package:neurostack/features/protocol/domain/value_objects/target.dart';
import 'package:neurostack/features/protocol/domain/value_objects/research_citation.dart';
import 'package:neurostack/features/protocol/domain/enums/category.dart';
import 'package:neurostack/features/protocol/domain/enums/evidence_level.dart';

/// Strict DOI+URL+shape-parity gate applies to the LAST 3 entries (per R1
/// append-only contract). Hard-coded names are asserted as a sanity check.
const _expectedNewNames = <String>{
  'Daily Sub-Maximal Calisthenics for Functional Preservation',
  'Delayed Morning Caffeine for Sustained Daytime Alertness',
  'Vitamin D3 with K2 (MK-7) for Bone Density Maintenance',
};

/// The D3+K2 protocol's name; its description must contain "BMD" or
/// "bone mineral density" to lock the exact-outcome alignment with Knapen 2013.
const _d3K2Name = 'Vitamin D3 with K2 (MK-7) for Bone Density Maintenance';

/// Pre-existing duplicate that is INTENTIONALLY preserved (R1 append-only).
/// Listed by lower(name); the script allows exactly one collision pair.
const _knownPreExistingDuplicates = <String>{
  'structured gratitude journaling for well-being',
};

final _doiRe = RegExp(r'^10\.[0-9]{4,9}/.+');
final _bmdRe = RegExp(r'\b(BMD|bone mineral density)\b', caseSensitive: false);

bool _isAbsoluteHttpUrl(String? url) {
  if (url == null || url.trim().isEmpty) return false;
  final u = Uri.tryParse(url);
  if (u == null) return false;
  if (!u.hasScheme) return false;
  if (u.scheme != 'http' && u.scheme != 'https') return false;
  if (u.host.isEmpty) return false;
  return true;
}

void main() {
  // CWD guard: this dev-tool must run from the repo root (where pubspec.yaml lives)
  // so relative paths resolve. Friendlier than a raw FileSystemException.
  if (!File('pubspec.yaml').existsSync() || !File('protocols.json').existsSync()) {
    stderr.writeln(
      'FAIL: dev-tool must be run from repo root.\n'
      '  Expected pubspec.yaml + protocols.json in the current directory.\n'
      '  Try: cd <repo-root> && dart run tool/verify_protocols_json.dart',
    );
    exit(1);
  }
  final rawDecoded = jsonDecode(File('protocols.json').readAsStringSync());
  if (rawDecoded is! List<dynamic>) {
    stderr.writeln('FAIL: protocols.json root is not a JSON array');
    exit(1);
  }
  final List<dynamic> data = rawDecoded;
  var errors = 0;
  void err(String msg) {
    errors++;
    stderr.writeln('FAIL $msg');
  }

  // Uniqueness preflight (tolerates _knownPreExistingDuplicates only).
  final nameCounts = <String, int>{};
  for (final entry in data) {
    if (entry is Map && entry['name'] is String) {
      final lower = (entry['name'] as String).toLowerCase();
      nameCounts[lower] = (nameCounts[lower] ?? 0) + 1;
    }
  }
  for (final e in nameCounts.entries) {
    if (e.value > 1) {
      if (_knownPreExistingDuplicates.contains(e.key) && e.value == 2) {
        // Tolerated.
      } else {
        err('uniqueness: lower(name) "${e.key}" appears ${e.value} times '
            '(only known pre-existing duplicates allowed)');
      }
    }
  }

  // Tail-3 sanity (symmetric, verbose with indices on mismatch).
  if (data.length < 3) {
    err('expected ≥3 entries; got ${data.length}');
  } else {
    final tailEntries = <MapEntry<int, String>>[];
    for (var i = data.length - 3; i < data.length; i++) {
      final entry = data[i];
      final name = (entry is Map && entry['name'] is String)
          ? entry['name'] as String
          : '<entry $i: name missing>';
      tailEntries.add(MapEntry(i, name));
    }
    final tailNames = tailEntries.map((e) => e.value).toSet();
    if (tailNames.length != 3 || !tailNames.containsAll(_expectedNewNames)) {
      final unexpected = tailNames.difference(_expectedNewNames);
      final missing = _expectedNewNames.difference(tailNames);
      err('last-3 mismatch: tail entries=${tailEntries.map((e) => "[${e.key}]=${e.value}").join(", ")}; '
          'unexpected=$unexpected missing=$missing. '
          'Update _expectedNewNames if rename was intentional.');
    }
  }

  // Per-entry validation.
  for (var i = 0; i < data.length; i++) {
    final entry = data[i];
    if (entry is! Map) {
      err('entry[$i]: not a JSON object (got ${entry.runtimeType})');
      continue;
    }
    final name = (entry['name'] is String) ? entry['name'] as String : '<entry $i: name missing>';
    final isNew = i >= data.length - 3;

    if (entry['name'] is String) {
      ProtocolName.create(entry['name'] as String).fold(
        (failure) => err('ProtocolName ($name): ${failure.code} — ${failure.message}'),
        (_) {},
      );
    } else {
      err('ProtocolName ($name): missing or wrong type');
    }

    if (entry['description'] is String) {
      final desc = entry['description'] as String;
      ProtocolDescription.create(desc).fold(
        (failure) => err('ProtocolDescription ($name): ${failure.code} — ${failure.message}'),
        (_) {},
      );
      // BMD scope-lock check for the D3+K2 entry.
      if (name == _d3K2Name && !_bmdRe.hasMatch(desc)) {
        err('BMD scope-lock ($name): description must contain "BMD" or "bone mineral density" '
            'to keep exact-outcome aligned with Knapen 2013 RCT anchor.');
      }
    } else {
      err('ProtocolDescription ($name): missing or wrong type');
    }

    if (entry['category'] is String) {
      try {
        Category.values.byName(entry['category'] as String);
      } catch (_) {
        err('Category ($name): ${entry['category']}');
      }
    } else {
      err('Category ($name): missing or wrong type');
    }
    if (entry['evidence_level'] is String) {
      try {
        EvidenceLevel.values.byName(entry['evidence_level'] as String);
      } catch (_) {
        err('EvidenceLevel ($name): ${entry['evidence_level']}');
      }
    } else {
      err('EvidenceLevel ($name): missing or wrong type');
    }

    // Frequency + Target (VOs 3 + 4).
    final target = entry['target'];
    if (target is! Map) {
      err('target ($name): missing or wrong type');
    } else {
      final freqRaw = target['frequency'];
      Frequency? freqVo;
      if (freqRaw is! Map) {
        err('target.frequency ($name): missing or wrong type');
      } else {
        final minPerWeek = freqRaw['min_per_week'];
        final maxPerWeek = freqRaw['max_per_week'];
        if (minPerWeek is! int) {
          err('target.frequency.min_per_week ($name): $minPerWeek (must be int)');
        } else if (maxPerWeek is! int) {
          err('target.frequency.max_per_week ($name): $maxPerWeek (must be int)');
        } else {
          Frequency.create(minPerWeek: minPerWeek, maxPerWeek: maxPerWeek).fold(
            (failure) => err('Frequency.create ($name): ${failure.code} — ${failure.message}'),
            (vo) => freqVo = vo,
          );
        }
      }

      if (freqVo != null) {
        final durationSeconds = target['durationSeconds'];
        Duration? duration;
        if (durationSeconds is int) {
          if (durationSeconds < 0) {
            err('target.durationSeconds ($name): $durationSeconds (negative)');
          } else {
            duration = Duration(seconds: durationSeconds);
          }
        } else if (durationSeconds != null) {
          err('target.durationSeconds ($name): wrong type ($durationSeconds)');
        }

        final intensityRaw = target['intensity'];
        String? intensity;
        if (intensityRaw is String) {
          intensity = intensityRaw;
        } else if (intensityRaw != null) {
          err('target.intensity ($name): wrong type');
        }

        Target.create(frequency: freqVo!, duration: duration, intensity: intensity).fold(
          (failure) => err('Target.create ($name): ${failure.code} — ${failure.message}'),
          (_) {},
        );

        if (isNew) {
          if (durationSeconds is! int || durationSeconds < 1) {
            err('target.durationSeconds (new $name): $durationSeconds (require int ≥1)');
          }
          if (intensity == null || intensity.trim().isEmpty) {
            err('target.intensity (new $name): empty/missing (require non-empty string)');
          }
        }
      }
    }

    // ResearchCitation (VO 5) + INV-P1 + DOI/URL gates.
    final citationsRaw = entry['research_citations'];
    final citations = (citationsRaw is List) ? citationsRaw : const [];
    if (citationsRaw is! List) {
      err('research_citations ($name): missing or wrong type');
    }
    if (citations.isEmpty) {
      err('INV-P1 ($name): zero citations');
    }

    for (final c in citations) {
      if (c is! Map) {
        err('citation ($name): not a JSON object');
        continue;
      }
      final authors = (c['authors'] is String) ? c['authors'] as String : null;
      final year = (c['year'] is int) ? c['year'] as int : null;
      final title = (c['title'] is String) ? c['title'] as String : null;
      final journal = (c['journal'] is String) ? c['journal'] as String : null;
      final doi = (c['doi'] is String) ? c['doi'] as String : null;
      final url = (c['url'] is String) ? c['url'] as String : null;

      if (authors == null || year == null || title == null || journal == null) {
        err('citation field type ($name): authors=${c['authors']}, year=${c['year']}, '
            'title=${c['title']}, journal=${c['journal']}');
        continue;
      }

      ResearchCitation.create(
        authors: authors, year: year, title: title, journal: journal, doi: doi, url: url,
      ).fold(
        (failure) => err('ResearchCitation.create ($name): ${failure.code} — ${failure.message}'),
        (_) {},
      );

      if (isNew) {
        if (doi == null || !_doiRe.hasMatch(doi)) {
          err('R7-strict ($name): bad/missing DOI on new entry: $doi');
        }
        if (!_isAbsoluteHttpUrl(url)) {
          err('R2-url ($name): bad/missing URL on new entry: $url');
        }
        // Shape-parity for new entries: verification_status + verification_note.
        final vs = c['verification_status'];
        final vn = c['verification_note'];
        if (vs is! String || vs.trim().isEmpty) {
          err('shape-parity ($name): citation.verification_status missing/empty');
        }
        if (vn is! String || vn.trim().isEmpty) {
          err('shape-parity ($name): citation.verification_note missing/empty');
        }
      } else {
        if (doi != null && !_doiRe.hasMatch(doi)) {
          err('R7-format (legacy $name): malformed DOI: $doi');
        }
        if (url != null && url.trim().isNotEmpty && !_isAbsoluteHttpUrl(url)) {
          err('R2-url (legacy $name): malformed URL: $url');
        }
      }
    }

    // Shape-parity: source_models on new entries.
    if (isNew) {
      final sm = entry['source_models'];
      if (sm is! List || sm.isEmpty || sm.any((e) => e is! String || (e).trim().isEmpty)) {
        err('shape-parity ($name): source_models must be non-empty list of non-empty strings');
      }
    }
  }

  if (errors > 0) {
    stderr.writeln('$errors invariant violation(s)');
    exit(1);
  }
  print('OK ${data.length} entries valid');
}
