import 'package:shared_preferences/shared_preferences.dart';

import '../models/file_types.dart';

class AppSettings {
  final bool scanImages;
  final bool scanVideos;
  final bool scanAudio;
  final bool scanDocuments;
  final bool scanArchives;
  final int minFileSize;
  final int largeFileMinSize;
  final int unusedDays;
  final bool autoSelectOldest;

  const AppSettings({
    this.scanImages = true,
    this.scanVideos = true,
    this.scanAudio = true,
    this.scanDocuments = true,
    this.scanArchives = true,
    this.minFileSize = 0,
    this.largeFileMinSize = 50 * 1024 * 1024,
    this.unusedDays = 180,
    this.autoSelectOldest = true,
  });

  AppSettings copyWith({
    bool? scanImages,
    bool? scanVideos,
    bool? scanAudio,
    bool? scanDocuments,
    bool? scanArchives,
    int? minFileSize,
    int? largeFileMinSize,
    int? unusedDays,
    bool? autoSelectOldest,
  }) {
    return AppSettings(
      scanImages: scanImages ?? this.scanImages,
      scanVideos: scanVideos ?? this.scanVideos,
      scanAudio: scanAudio ?? this.scanAudio,
      scanDocuments: scanDocuments ?? this.scanDocuments,
      scanArchives: scanArchives ?? this.scanArchives,
      minFileSize: minFileSize ?? this.minFileSize,
      largeFileMinSize: largeFileMinSize ?? this.largeFileMinSize,
      unusedDays: unusedDays ?? this.unusedDays,
      autoSelectOldest: autoSelectOldest ?? this.autoSelectOldest,
    );
  }

  List<String> get fileExtensions {
    final extensions = <String>[];
    if (scanImages) extensions.addAll(FileTypes.images);
    if (scanVideos) extensions.addAll(FileTypes.videos);
    if (scanAudio) extensions.addAll(FileTypes.audio);
    if (scanDocuments) extensions.addAll(FileTypes.documents);
    if (scanArchives) extensions.addAll(FileTypes.archives);
    if (extensions.isEmpty) return FileTypes.all();
    return extensions;
  }
}

class SettingsService {
  static const _scanImages = 'scan_images';
  static const _scanVideos = 'scan_videos';
  static const _scanAudio = 'scan_audio';
  static const _scanDocuments = 'scan_documents';
  static const _scanArchives = 'scan_archives';
  static const _minFileSize = 'min_file_size';
  static const _largeFileMinSize = 'large_file_min_size';
  static const _unusedDays = 'unused_days';
  static const _autoSelectOldest = 'auto_select_oldest';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      scanImages: prefs.getBool(_scanImages) ?? true,
      scanVideos: prefs.getBool(_scanVideos) ?? true,
      scanAudio: prefs.getBool(_scanAudio) ?? true,
      scanDocuments: prefs.getBool(_scanDocuments) ?? true,
      scanArchives: prefs.getBool(_scanArchives) ?? true,
      minFileSize: prefs.getInt(_minFileSize) ?? 0,
      largeFileMinSize: prefs.getInt(_largeFileMinSize) ?? 50 * 1024 * 1024,
      unusedDays: prefs.getInt(_unusedDays) ?? 180,
      autoSelectOldest: prefs.getBool(_autoSelectOldest) ?? true,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_scanImages, settings.scanImages);
    await prefs.setBool(_scanVideos, settings.scanVideos);
    await prefs.setBool(_scanAudio, settings.scanAudio);
    await prefs.setBool(_scanDocuments, settings.scanDocuments);
    await prefs.setBool(_scanArchives, settings.scanArchives);
    await prefs.setInt(_minFileSize, settings.minFileSize);
    await prefs.setInt(_largeFileMinSize, settings.largeFileMinSize);
    await prefs.setInt(_unusedDays, settings.unusedDays);
    await prefs.setBool(_autoSelectOldest, settings.autoSelectOldest);
  }
}
