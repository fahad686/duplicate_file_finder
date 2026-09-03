import 'dart:io';

import 'file_types.dart';

class DuplicateFile {
  final String path;
  final String name;
  final String extension;
  final int size;
  final DateTime lastModified;
  final DateTime lastAccessed;
  final String hash;
  bool isSelected;

  DuplicateFile({
    required this.path,
    required this.name,
    required this.extension,
    required this.size,
    required this.lastModified,
    DateTime? lastAccessed,
    required this.hash,
    this.isSelected = false,
  }) : lastAccessed = lastAccessed ?? lastModified;

  File get file => File(path);

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  bool get isImage => FileTypes.images.contains(extension.toLowerCase());
  bool get isVideo => FileTypes.videos.contains(extension.toLowerCase());
  bool get isAudio => FileTypes.audio.contains(extension.toLowerCase());

  DateTime get lastUsed =>
      lastAccessed.isAfter(lastModified) ? lastAccessed : lastModified;

  int get daysUnused => DateTime.now().difference(lastUsed).inDays;
}

class DuplicateGroup {
  final String hash;
  final int fileSize;
  final List<DuplicateFile> files;

  DuplicateGroup({
    required this.hash,
    required this.fileSize,
    required this.files,
  });

  int get duplicateCount => files.length - 1;

  int get wastedSize => fileSize * duplicateCount;

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get wastedSizeFormatted {
    if (wastedSize < 1024) return '$wastedSize B';
    if (wastedSize < 1024 * 1024) {
      return '${(wastedSize / 1024).toStringAsFixed(1)} KB';
    }
    if (wastedSize < 1024 * 1024 * 1024) {
      return '${(wastedSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(wastedSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  List<DuplicateFile> get selectedFiles =>
      files.where((f) => f.isSelected).toList();

  int get selectedSize => selectedFiles.fold(0, (sum, f) => sum + f.size);
}
