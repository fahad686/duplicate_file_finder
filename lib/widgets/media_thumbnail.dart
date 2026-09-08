import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../models/duplicate_file.dart';

class MediaThumbnail extends StatelessWidget {
  static final Map<String, Future<Uint8List?>> _videoCache = {};

  final DuplicateFile file;
  final double width;
  final double height;
  final double borderRadius;

  const MediaThumbnail({
    super.key,
    required this.file,
    this.width = 96,
    this.height = 80,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: file.isImage
            ? Image.file(
                file.file,
                fit: BoxFit.cover,
                cacheWidth: (width * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                errorBuilder: (_, _, _) => _fallback(),
              )
            : file.isVideo
            ? _videoThumbnail()
            : _fallback(),
      ),
    );
  }

  Widget _videoThumbnail() {
    final thumbnail = _videoCache.putIfAbsent(
      file.path,
      () => VideoThumbnail.thumbnailData(
        video: file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 360,
        quality: 75,
      ),
    );

    return FutureBuilder<Uint8List?>(
      future: thumbnail,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: const Color(0xFF171229),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
            );
          }
          return _fallback();
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
            Container(color: Colors.black.withValues(alpha: 0.16)),
            const Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _fallback() {
    final (color, icon) = switch (file.extension.toLowerCase()) {
      '.pdf' => (const Color(0xFFEF4444), Icons.picture_as_pdf_rounded),
      '.zip' ||
      '.rar' ||
      '.7z' => (const Color(0xFFF59E0B), Icons.folder_zip_rounded),
      _ when file.isVideo => (const Color(0xFF8B5CF6), Icons.videocam_rounded),
      _ when file.isAudio => (
        const Color(0xFFF59E0B),
        Icons.audiotrack_rounded,
      ),
      _ when file.isImage => (const Color(0xFF3B82F6), Icons.image_rounded),
      _ => (const Color(0xFF6B7A94), Icons.insert_drive_file_rounded),
    };

    return Container(
      color: color.withValues(alpha: 0.14),
      child: Icon(icon, color: color, size: 30),
    );
  }
}
