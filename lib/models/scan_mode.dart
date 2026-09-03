enum ScanMode {
  duplicates,
  largeFiles,
  unusedFiles,
}

extension ScanModeLabels on ScanMode {
  String get title => switch (this) {
        ScanMode.duplicates => 'Scanning',
        ScanMode.largeFiles => 'Large Files',
        ScanMode.unusedFiles => 'Unused Files',
      };

  String get progressTitle => switch (this) {
        ScanMode.duplicates => 'Scanning Files...',
        ScanMode.largeFiles => 'Finding Large Files...',
        ScanMode.unusedFiles => 'Finding Unused Files...',
      };

  String get progressSubtitle => switch (this) {
        ScanMode.duplicates => 'Looking for duplicate files',
        ScanMode.largeFiles => 'Looking for files that take the most space',
        ScanMode.unusedFiles => 'Looking for files you have not used in a while',
      };

  String get matchLabel => switch (this) {
        ScanMode.duplicates => 'Duplicates Found',
        ScanMode.largeFiles => 'Large Files Found',
        ScanMode.unusedFiles => 'Unused Files Found',
      };
}
