import 'dart:convert';

/// Converts the app's raw batch JSON into a versioned backup and back.
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

    throw const FormatException('Nem felismerhető Brewer Diary backup.');
  }

  String describeBackup(String backupText) {
    try {
      final decoded = jsonDecode(backupText);
      if (decoded is Map<String, dynamic>) {
        final createdAtRaw = decoded['createdAt'] as String?;
        final batches = decoded['batches'];
        final batchCount = batches is List ? batches.length : null;
        final createdAt = createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw);
        final dateLabel = createdAt == null ? 'Ismeretlen dátum' : _formatDate(createdAt);
        final countLabel = batchCount == null ? '' : ' • $batchCount tétel';
        return '$dateLabel$countLabel';
      }
      if (decoded is List) return 'Régi JSON backup • ${decoded.length} tétel';
    } catch (_) {
      // Fall through to generic label.
    }
    return 'Ismeretlen backup';
  }

  String makeBackupFileName({DateTime? now}) {
    final date = now ?? DateTime.now();
    return 'brewer_diary_backup_${_fileStamp(date)}.$backupExtension';
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}.${two(date.month)}.${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
  }

  String _fileStamp(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}_${two(date.hour)}${two(date.minute)}';
  }
}
