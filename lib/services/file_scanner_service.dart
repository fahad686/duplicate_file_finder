import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../models/duplicate_file.dart';

class ScanProgress {
  final int filesScanned;
  final int duplicatesFound;
  final String currentPath;
  final int totalSize;

  ScanProgress({
    required this.filesScanned,
    required this.duplicatesFound,
    required this.currentPath,
    required this.totalSize,
  });
}

class FileScannerService {
  static const androidScanRoot = '/storage/emulated/0';

  static const androidExcludedDirs = [
    '/storage/emulated/0/Android/data',
    '/storage/emulated/0/Android/obb',
  ];

  final StreamController<ScanProgress> _progressController =
      StreamController<ScanProgress>.broadcast();

  Stream<ScanProgress> get progressStream => _progressController.stream;

  List<String> _excludedDirs = List.from(androidExcludedDirs);
  List<String> _fileExtensions = [];
  int _minFileSize = 0;
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void configure({
    List<String>? excludedDirs,
    List<String>? fileExtensions,
    int? minFileSize,
  }) {
    _excludedDirs = [
      ...androidExcludedDirs,
      ...?excludedDirs,
    ];
    _fileExtensions = fileExtensions ?? [];
    _minFileSize = minFileSize ?? 0;
  }

  void cancel() {
    _cancelled = true;
  }

  Future<List<DuplicateGroup>> scanDirectories(List<String> directories) async {
    _cancelled = false;
    final Map<String, List<DuplicateFile>> sizeGroups = {};
    var filesScanned = 0;
    var totalSize = 0;

    filesScanned = await _collectFiles(directories, (file, scanned) {
      totalSize += file.size;
      sizeGroups.putIfAbsent(file.size.toString(), () => []).add(file);
      _emitProgress(scanned, 0, file.path, totalSize);
    });

    if (_cancelled) return [];

    final Map<String, List<DuplicateFile>> hashGroups = {};

    for (final group in sizeGroups.values) {
      if (_cancelled) return [];
      if (group.length < 2) continue;

      for (final file in group) {
        if (_cancelled) return [];
        try {
          final hash = await _computeHash(file.path);
          final fileWithHash = DuplicateFile(
            path: file.path,
            name: file.name,
            extension: file.extension,
            size: file.size,
            lastModified: file.lastModified,
            lastAccessed: file.lastAccessed,
            hash: hash,
          );

          hashGroups.putIfAbsent(hash, () => []).add(fileWithHash);

          _emitProgress(
            filesScanned,
            hashGroups.values
                .where((g) => g.length > 1)
                .fold(0, (sum, g) => sum + g.length),
            file.path,
            totalSize,
          );
        } catch (_) {
          continue;
        }
      }
    }

    if (_cancelled) return [];

    final duplicates = hashGroups.entries
        .where((entry) => entry.value.length > 1)
        .map((entry) {
          final files = List<DuplicateFile>.from(entry.value)
            ..sort((a, b) => b.lastModified.compareTo(a.lastModified));
          return DuplicateGroup(
            hash: entry.key,
            fileSize: files.first.size,
            files: files,
          );
        })
        .toList();

    duplicates.sort((a, b) => b.wastedSize.compareTo(a.wastedSize));
    return duplicates;
  }

  Future<List<DuplicateFile>> scanLargeFiles(List<String> directories) async {
    _cancelled = false;
    final files = <DuplicateFile>[];
    var totalSize = 0;

    await _collectFiles(directories, (file, scanned) {
      files.add(file);
      totalSize += file.size;
      _emitProgress(scanned, files.length, file.path, totalSize);
    });

    if (_cancelled) return [];
    files.sort((a, b) => b.size.compareTo(a.size));
    return files;
  }

  Future<List<DuplicateFile>> scanUnusedFiles(
    List<String> directories, {
    required int unusedDays,
  }) async {
    _cancelled = false;
    final cutoff = DateTime.now().subtract(Duration(days: unusedDays));
    final files = <DuplicateFile>[];
    var totalSize = 0;

    await _collectFiles(directories, (file, scanned) {
      if (file.lastUsed.isBefore(cutoff)) {
        files.add(file);
        totalSize += file.size;
      }
      _emitProgress(scanned, files.length, file.path, totalSize);
    });

    if (_cancelled) return [];
    files.sort((a, b) => a.lastUsed.compareTo(b.lastUsed));
    return files;
  }

  Future<int> _collectFiles(
    List<String> directories,
    void Function(DuplicateFile file, int scanned) onFile,
  ) async {
    var filesScanned = 0;
    for (final dir in directories) {
      if (_cancelled) return filesScanned;
      final directory = Directory(dir);
      if (!await directory.exists()) continue;
      filesScanned = await _walkDirectory(directory, filesScanned, onFile);
    }
    return filesScanned;
  }

  Future<int> _walkDirectory(
    Directory directory,
    int filesScanned,
    void Function(DuplicateFile file, int scanned) onFile,
  ) async {
    if (_cancelled) return filesScanned;
    if (_isExcluded(directory.path)) return filesScanned;

    try {
      await for (final entity in directory.list(followLinks: false)) {
        if (_cancelled) return filesScanned;

        if (entity is Directory) {
          filesScanned = await _walkDirectory(entity, filesScanned, onFile);
          continue;
        }

        if (entity is! File) continue;

        try {
          final stat = await entity.stat();
          if (stat.type != FileSystemEntityType.file) continue;
          if (stat.size < _minFileSize) continue;

          final ext = p.extension(entity.path).toLowerCase();
          if (_fileExtensions.isNotEmpty && !_fileExtensions.contains(ext)) {
            continue;
          }

          if (_isExcluded(entity.path)) continue;

          filesScanned++;
          onFile(
            DuplicateFile(
              path: entity.path,
              name: p.basename(entity.path),
              extension: ext,
              size: stat.size,
              lastModified: stat.modified,
              lastAccessed: _validAccessed(stat),
              hash: '',
            ),
            filesScanned,
          );

          if (filesScanned % 25 == 0) {
            await Future<void>.delayed(Duration.zero);
          }
        } catch (_) {
          continue;
        }
      }
    } catch (_) {
      return filesScanned;
    }

    return filesScanned;
  }

  DateTime _validAccessed(FileStat stat) {
    final accessed = stat.accessed;
    if (accessed.year < 1980) return stat.modified;
    return accessed;
  }

  void _emitProgress(
    int filesScanned,
    int duplicatesFound,
    String currentPath,
    int totalSize,
  ) {
    if (_progressController.isClosed) return;
    _progressController.add(
      ScanProgress(
        filesScanned: filesScanned,
        duplicatesFound: duplicatesFound,
        currentPath: currentPath,
        totalSize: totalSize,
      ),
    );
  }

  Future<String> _computeHash(String filePath) async {
    final file = File(filePath);
    final digest = await md5.bind(file.openRead()).first;
    return digest.toString();
  }

  bool _isExcluded(String filePath) {
    for (final dir in _excludedDirs) {
      if (filePath == dir || filePath.startsWith('$dir/')) return true;
    }
    return false;
  }

  Future<int> deleteFiles(List<DuplicateFile> files) async {
    int freedBytes = 0;

    for (final file in files) {
      try {
        final f = File(file.path);
        if (await f.exists()) {
          final stat = await f.stat();
          await f.delete();
          freedBytes += stat.size;
        }
      } catch (_) {
        continue;
      }
    }

    return freedBytes;
  }

  void dispose() {
    _cancelled = true;
    if (!_progressController.isClosed) {
      _progressController.close();
    }
  }
}
