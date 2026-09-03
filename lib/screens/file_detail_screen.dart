import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

import '../models/duplicate_file.dart';
import 'media_player_screen.dart';

class FileDetailScreen extends StatelessWidget {
  final DuplicateFile file;

  const FileDetailScreen({super.key, required this.file});

  bool get _isMedia => file.isImage || file.isVideo || file.isAudio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        ),
        title: Text(
          file.name,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilePreview(context),
            const SizedBox(height: 16),
            _buildInfoSection(),
            const SizedBox(height: 16),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview(BuildContext context) {
    return GestureDetector(
      onTap: _isMedia
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MediaPlayerScreen(file: file),
                ),
              );
            }
          : null,
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFF131B2A),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildPreviewContent(),
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (file.isImage) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(file.path),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildFileIcon(),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.zoom_in_rounded,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Tap to view full screen',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (file.isVideo) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: const Color(0xFF1A1030),
            child: const Center(
              child: Icon(
                Icons.videocam_rounded,
                size: 64,
                color: Color(0xFF8B5CF6),
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.25)),
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 34,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    if (file.isAudio) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.music_note_rounded,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Tap to play',
                        style:
                            TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return _buildFileIcon();
  }

  Widget _buildFileIcon() {
    IconData icon;
    Color color;

    if (file.extension == '.pdf') {
      icon = Icons.picture_as_pdf_rounded;
      color = const Color(0xFFEF4444);
    } else if (['.doc', '.docx'].contains(file.extension)) {
      icon = Icons.description_rounded;
      color = const Color(0xFF3B82F6);
    } else if (['.xls', '.xlsx'].contains(file.extension)) {
      icon = Icons.table_chart_rounded;
      color = const Color(0xFF10B981);
    } else if (['.zip', '.rar', '.7z'].contains(file.extension)) {
      icon = Icons.folder_zip_rounded;
      color = const Color(0xFFF59E0B);
    } else if (['.txt', '.log'].contains(file.extension)) {
      icon = Icons.text_snippet_rounded;
      color = const Color(0xFF14B8A6);
    } else {
      icon = Icons.insert_drive_file_rounded;
      color = const Color(0xFF6B7A94);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 56, color: color),
        const SizedBox(height: 8),
        Text(
          file.extension.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'File Information',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoRow('Name', file.name),
          const SizedBox(height: 10),
          _buildInfoRow('Size', file.sizeFormatted),
          const SizedBox(height: 10),
          _buildInfoRow('Type', file.extension.toUpperCase()),
          const SizedBox(height: 10),
          _buildInfoRow(
            'Modified',
            DateFormat('MMM d, y HH:mm').format(file.lastModified),
          ),
          const SizedBox(height: 10),
          _buildInfoRow('Hash', file.hash.length >= 16
              ? file.hash.substring(0, 16)
              : file.hash),
          const SizedBox(height: 10),
          _buildInfoRow('Path', file.path),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        if (_isMedia)
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MediaPlayerScreen(file: file),
                  ),
                );
              },
              icon: Icon(
                file.isAudio
                    ? Icons.play_circle_rounded
                    : file.isVideo
                        ? Icons.play_circle_filled_rounded
                        : Icons.fullscreen_rounded,
                size: 20,
              ),
              label: Text(
                file.isAudio
                    ? 'Play Audio'
                    : file.isVideo
                        ? 'Play Video'
                        : 'View Image',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getAccentColor(),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        if (_isMedia) const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: () async {
              final result = await OpenFile.open(file.path);
              if (context.mounted && result.type != ResultType.done) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not open: ${result.message}')),
                );
              }
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('Open Externally'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6),
              side: const BorderSide(color: Color(0xFF3B82F6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: file.path));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Path copied to clipboard')),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy Path'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getAccentColor() {
    if (file.isImage) return const Color(0xFF3B82F6);
    if (file.isVideo) return const Color(0xFF8B5CF6);
    if (file.isAudio) return const Color(0xFFF59E0B);
    return const Color(0xFF3B82F6);
  }
}
