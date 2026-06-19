import 'dart:convert';

/// Converts the app's raw batch JSON into a versioned backup file and back.
///
/// The backup wrapper gives us room for future metadata and migrations without
/// breaking today's saved files.
class BackupService {
  static const backupExtension = 'bdiary';
  static const backupVersion = 1;

  String buildBackupJson(String rawBatchesJson) {
    final batches = jsonDecode(rawBatchesJson);
    final wrapper = {
      'backupVersion': backupVersion,
      'app': 'Brewer Diary',
      'createdAt': DateTime.now().toIso8601String(),
      'batches': batches,
    };
    return const JsonEncoder.withIndent('  ').convert(wrapper);
  }

  String extractBatchesJson(String backupText) {
    final decoded = jsonDecode(backupText);

    // Backward compatibility: old exports were a raw list of batches.
    if (decoded is List) {
      return jsonEncode(decoded);
    }

    if (decoded is Map<String, dynamic> && decoded['batches'] is List) {
      return jsonEncode(decoded['batches']);
    }

    throw const FormatException('Nem felismerhető Brewer Diary backup fájl.');
  }

  String makeBackupFileName({DateTime? now}) {
    final date = now ?? DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    final stamp = '${date.year}-${two(date.month)}-${two(date.day)}_${two(date.hour)}${two(date.minute)}';
    return 'brewer_diary_backup_$stamp.$backupExtension';
  }
}
