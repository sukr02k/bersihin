import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams, XFile;
import 'package:sqflite/sqflite.dart';
import 'package:flutter_laundry_offline_app/core/constants/app_constants.dart';
import 'package:flutter_laundry_offline_app/core/utils/date_formatter.dart';
import 'package:flutter_laundry_offline_app/data/database/database_helper.dart';

class BackupInfo {
  final String fileName;
  final String filePath;
  final DateTime createdAt;
  final int sizeBytes;

  const BackupInfo({
    required this.fileName,
    required this.filePath,
    required this.createdAt,
    required this.sizeBytes,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  static const String _backupFolderName = 'backups';
  static const String _sqliteMagicHeader = 'SQLite format 3';

  Future<Directory> _getBackupDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docDir.path, _backupFolderName));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  Future<String> _getActiveDatabasePath() async {
    final dbDir = await getDatabasesPath();
    return p.join(dbDir, AppConstants.databaseName);
  }

  /// Create a local backup of the SQLite database and optionally open share sheet
  Future<BackupInfo> createBackup({bool shareAfterBackup = false}) async {
    // Ensure database is initialized before copying
    await DatabaseHelper.instance.database;

    final dbPath = await _getActiveDatabasePath();
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception('File database aktif tidak ditemukan');
    }

    final backupDir = await _getBackupDirectory();
    final now = DateTime.now();
    final timestamp =
        '${DateFormatter.formatDateCompact(now)}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final fileName = 'Bersihin_Backup_$timestamp.db';
    final backupPath = p.join(backupDir.path, fileName);

    final copiedFile = await dbFile.copy(backupPath);
    final stat = await copiedFile.stat();

    if (shareAfterBackup) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(copiedFile.path)],
          text:
              'Backup Database ${AppConstants.appName} (${DateFormatter.formatDateTime(now)})',
        ),
      );
    }

    return BackupInfo(
      fileName: fileName,
      filePath: copiedFile.path,
      createdAt: stat.modified,
      sizeBytes: stat.size,
    );
  }

  /// Share an existing backup file
  Future<void> shareBackup(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File backup tidak ditemukan');
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        text: 'Backup Database ${AppConstants.appName}',
      ),
    );
  }

  /// List all local backups sorted newest first
  Future<List<BackupInfo>> getAvailableBackups() async {
    final backupDir = await _getBackupDirectory();
    if (!await backupDir.exists()) return [];

    final entities = await backupDir.list().toList();
    final backups = <BackupInfo>[];

    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.db')) {
        final stat = await entity.stat();
        backups.add(
          BackupInfo(
            fileName: p.basename(entity.path),
            filePath: entity.path,
            createdAt: stat.modified,
            sizeBytes: stat.size,
          ),
        );
      }
    }

    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return backups;
  }

  /// Validate whether a file has a valid SQLite 3 header
  Future<bool> isValidSqliteFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return false;

    final length = await file.length();
    if (length < 16) return false;

    final bytes = await file.openRead(0, 16).first;
    final header = String.fromCharCodes(bytes.take(15));
    return header == _sqliteMagicHeader;
  }

  /// Restore database from a backup file path
  Future<void> restoreBackup(String backupFilePath) async {
    final isValid = await isValidSqliteFile(backupFilePath);
    if (!isValid) {
      throw Exception('File cadangan tidak valid atau rusak');
    }

    final dbPath = await _getActiveDatabasePath();
    final backupFile = File(backupFilePath);

    // Close active database connection
    await DatabaseHelper.instance.close();

    // Remove WAL/SHM files if they exist
    final walFile = File('$dbPath-wal');
    final shmFile = File('$dbPath-shm');
    if (await walFile.exists()) await walFile.delete();
    if (await shmFile.exists()) await shmFile.delete();

    // Copy backup over active database path
    await backupFile.copy(dbPath);

    // Re-open database to verify and run any pending migrations
    await DatabaseHelper.instance.database;
  }

  /// Delete a backup file
  Future<void> deleteBackup(String backupFilePath) async {
    final file = File(backupFilePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
