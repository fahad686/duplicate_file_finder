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
  static const int _chunkSize = 8192;
  final StreamController<ScanProgress> _progressController =
      StreamController<ScanProgress>.broadcast();

  Stream<ScanProgress> get progressStream => _progressController.stream;

  List<String> _excludedDirs = [];
  List<String> _fileExtensions = [];
  int _minFileSize = 0;

  void configure({
    List<String>? excludedDirs,
    List<String>? fileExtensions,
    int? minFileSize,
  }) {
    _excludedDirs = excludedDirs ?? [];
    _fileExtensions = fileExtensions ?? [];
    _minFileSize = minFileSize ?? 0;
  }

  Future<List<DuplicateGroup>> scanDirectories(List<String> directories) async {
    final Map<String, List<DuplicateFile>> sizeGroups = {};
    int filesScanned = 0;

    for (final dir in directories) {
      await for (final entity in Directory(dir).list(recursive: true)) {
        if (entity is File) {
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

            final file = DuplicateFile(
              path: entity.path,
              name: p.basename(entity.path),
              extension: ext,
              size: stat.size,
              lastModified: stat.modified,
              hash: '',
            );

            final sizeKey = stat.size.toString();
            if (!sizeGroups.containsKey(sizeKey)) {
              sizeGroups[sizeKey] = [];
            }
            sizeGroups[sizeKey]!.add(file);

            if (filesScanned % 50 == 0) {
              _progressController.add(ScanProgress(
                filesScanned: filesScanned,
                duplicatesFound: 0,
                currentPath: entity.path,
                totalSize: stat.size,
              ));
            }
          } catch (e) {
            continue;
          }
        }
      }
    }

    final Map<String, List<DuplicateFile>> hashGroups = {};

    for (final group in sizeGroups.values) {
      if (group.length < 2) continue;

      for (final file in group) {
        try {
          final hash = await _computeHash(file.path);
          final fileWithHash = DuplicateFile(
            path: file.path,
            name: file.name,
            extension: file.extension,
            size: file.size,
            lastModified: file.lastModified,
            hash: hash,
          );

          if (!hashGroups.containsKey(hash)) {
            hashGroups[hash] = [];
          }
          hashGroups[hash]!.add(fileWithHash);

          _progressController.add(ScanProgress(
            filesScanned: filesScanned,
            duplicatesFound: hashGroups.values
                .where((g) => g.length > 1)
                .fold(0, (sum, g) => sum + g.length),
            currentPath: file.path,
            totalSize: file.size,
          ));
        } catch (e) {
          continue;
        }
      }
    }

    final duplicates = hashGroups.entries
        .where((entry) => entry.value.length > 1)
        .map((entry) => DuplicateGroup(
              hash: entry.key,
              fileSize: entry.value.first.size,
              files: entry.value,
            ))
        .toList();

    duplicates.sort((a, b) => b.wastedSize.compareTo(a.wastedSize));

    return duplicates;
  }

  Future<String> _computeHash(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return md5.convert(bytes).toString();
  }

  bool _isExcluded(String filePath) {
    for (final dir in _excludedDirs) {
      if (filePath.startsWith(dir)) return true;
    }
    return false;
  }

  Future<int> deleteFiles(List<DuplicateFile> files) async {
    int deletedCount = 0;
    int freedBytes = 0;

    for (final file in files) {
      try {
        final f = File(file.path);
        if (await f.exists()) {
          final stat = await f.stat();
          await f.delete();
          deletedCount++;
          freedBytes += stat.size;
        }
      } catch (e) {
        continue;
      }
    }

    return freedBytes;
  }

  void dispose() {
    _progressController.close();
  }
}
