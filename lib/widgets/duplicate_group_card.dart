import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

import '../models/duplicate_file.dart';
import '../screens/file_detail_screen.dart';

class DuplicateGroupCard extends StatefulWidget {
  final DuplicateGroup group;
  final int groupIndex;
  final Function(bool) onSelectAll;

  const DuplicateGroupCard({
    super.key,
    required this.group,
    required this.groupIndex,
    required this.onSelectAll,
  });

  @override
  State<DuplicateGroupCard> createState() => _DuplicateGroupCardState();
}

class _DuplicateGroupCardState extends State<DuplicateGroupCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroupHeader(),
          _buildGroupInfo(),
          if (_isExpanded) ...[
            const Divider(height: 1, color: Color(0xFF0D1117)),
            ...widget.group.files.map((file) => _buildFileTile(file)),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupHeader() {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _buildGroupThumbnail(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.fileSizeFormatted,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.group.duplicateCount + 1} files · ${widget.group.wastedSizeFormatted} wasted',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7A94),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                widget.onSelectAll(true);
                setState(() {});
              },
              child: const Text('Select Dupes', style: TextStyle(fontSize: 12)),
            ),
            Icon(
              _isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: const Color(0xFF6B7A94),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupThumbnail() {
    final firstFile = widget.group.files.first;
    if (firstFile.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(firstFile.path),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(firstFile),
        ),
      );
    }
    return _buildFallbackIcon(firstFile);
  }

  Widget _buildFallbackIcon(DuplicateFile file) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getFileTypeColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_getFileTypeIcon(), color: _getFileTypeColor(), size: 24),
    );
  }

  Widget _buildGroupInfo() {
    final selectedCount =
        widget.group.files.where((f) => f.isSelected).length;
    final extension = widget.group.files.first.extension;
    final folder = p.dirname(widget.group.files.first.path);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getFileTypeColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              extension.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getFileTypeColor(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.group.files.first.name,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8B9AB5)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (selectedCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$selectedCount selected',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileTile(DuplicateFile file) {
    final folderName = p.basename(p.dirname(file.path));
    final parentFolder = p.basename(p.dirname(p.dirname(file.path)));
    final folderDisplay = '$parentFolder/$folderName';

    return Container(
      color: file.isSelected
          ? const Color(0xFFEF4444).withValues(alpha: 0.06)
          : Colors.transparent,
      child: Row(
        children: [
          Checkbox(
            value: file.isSelected,
            onChanged: (value) {
              setState(() {
                file.isSelected = value ?? false;
              });
            },
            activeColor: const Color(0xFFEF4444),
            checkColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          _buildTileThumbnail(file),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.folder_rounded,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        folderDisplay,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _buildInfoTag(file.sizeFormatted),
                    const SizedBox(width: 6),
                    _buildInfoTag(file.extension.toUpperCase()),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final result = await OpenFile.open(file.path);
              if (context.mounted && result.type != ResultType.done) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FileDetailScreen(file: file),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildTileThumbnail(DuplicateFile file) {
    if (file.isImage) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            File(file.path),
            width: 42,
            height: 42,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildSmallFallback(file),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: _buildSmallFallback(file),
    );
  }

  Widget _buildSmallFallback(DuplicateFile file) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _getFileTypeColor().withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(_getFileTypeIcon(), color: _getFileTypeColor(), size: 20),
    );
  }

  Color _getFileTypeColor() {
    final ext = widget.group.files.first.extension.toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
      return const Color(0xFF3B82F6);
    }
    if (['.mp4', '.avi', '.mkv', '.mov'].contains(ext)) {
      return const Color(0xFF8B5CF6);
    }
    if (['.mp3', '.wav', '.flac', '.aac'].contains(ext)) {
      return const Color(0xFFF59E0B);
    }
    if (ext == '.pdf') return const Color(0xFFEF4444);
    if (['.zip', '.rar', '.7z'].contains(ext)) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFF6B7A94);
  }

  IconData _getFileTypeIcon() {
    final ext = widget.group.files.first.extension.toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
      return Icons.image_rounded;
    }
    if (['.mp4', '.avi', '.mkv', '.mov'].contains(ext)) {
      return Icons.videocam_rounded;
    }
    if (['.mp3', '.wav', '.flac', '.aac'].contains(ext)) {
      return Icons.audiotrack_rounded;
    }
    if (ext == '.pdf') return Icons.picture_as_pdf_rounded;
    if (['.zip', '.rar', '.7z'].contains(ext)) return Icons.folder_zip_rounded;
    return Icons.insert_drive_file_rounded;
  }
}
