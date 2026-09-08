import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

import '../models/duplicate_file.dart';
import '../models/file_types.dart';
import '../screens/file_detail_screen.dart';
import '../screens/media_player_screen.dart';
import 'media_thumbnail.dart';

class DuplicateGroupCard extends StatefulWidget {
  final DuplicateGroup group;
  final int groupIndex;
  final Function(bool) onSelectAll;
  final VoidCallback onSelectionChanged;

  const DuplicateGroupCard({
    super.key,
    required this.group,
    required this.groupIndex,
    required this.onSelectAll,
    required this.onSelectionChanged,
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                widget.onSelectionChanged();
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
    return MediaThumbnail(
      file: firstFile,
      width: 76,
      height: 64,
      borderRadius: 10,
    );
  }

  Widget _buildGroupInfo() {
    final selectedCount = widget.group.files.where((f) => f.isSelected).length;
    final extension = widget.group.files.first.extension;

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
    final dateLabel = DateFormat('MMM d, y').format(file.lastModified);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      color: file.isSelected
          ? const Color(0xFFEF4444).withValues(alpha: 0.06)
          : Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: file.isSelected,
            onChanged: (value) {
              setState(() {
                file.isSelected = value ?? false;
              });
              widget.onSelectionChanged();
            },
            activeColor: const Color(0xFFEF4444),
            checkColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          _buildTileThumbnail(file),
          const SizedBox(width: 12),
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
                const SizedBox(height: 5),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildInfoTag(file.sizeFormatted),
                    _buildInfoTag(file.extension.toUpperCase()),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              if (file.isImage || file.isVideo || file.isAudio) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MediaPlayerScreen(file: file),
                  ),
                );
              } else {
                final result = await OpenFile.open(file.path);
                if (!mounted || result.type == ResultType.done) return;
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
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: MediaThumbnail(file: file, width: 88, height: 72, borderRadius: 8),
    );
  }

  Color _getFileTypeColor() {
    final ext = widget.group.files.first.extension.toLowerCase();
    if (FileTypes.images.contains(ext)) return const Color(0xFF3B82F6);
    if (FileTypes.videos.contains(ext)) return const Color(0xFF8B5CF6);
    if (FileTypes.audio.contains(ext)) return const Color(0xFFF59E0B);
    if (ext == '.pdf') return const Color(0xFFEF4444);
    if (FileTypes.archives.contains(ext)) return const Color(0xFFF59E0B);
    if (FileTypes.documents.contains(ext)) return const Color(0xFF10B981);
    return const Color(0xFF6B7A94);
  }
}
