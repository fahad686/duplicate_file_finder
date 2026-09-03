import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

import '../models/duplicate_file.dart';
import '../models/file_types.dart';
import '../models/scan_mode.dart';
import '../services/file_scanner_service.dart';
import 'file_detail_screen.dart';
import 'media_player_screen.dart';

class FileListScreen extends StatefulWidget {
  final ScanMode mode;
  final List<DuplicateFile> files;

  const FileListScreen({
    super.key,
    required this.mode,
    required this.files,
  });

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  final FileScannerService _scanner = FileScannerService();
  final Set<String> _activeFilters = {};
  late List<DuplicateFile> _files;

  static const _filterTypes = [
    {
      'key': 'image',
      'label': 'Images',
      'icon': Icons.image_rounded,
      'color': Color(0xFF3B82F6),
      'exts': FileTypes.images,
    },
    {
      'key': 'video',
      'label': 'Videos',
      'icon': Icons.videocam_rounded,
      'color': Color(0xFF8B5CF6),
      'exts': FileTypes.videos,
    },
    {
      'key': 'audio',
      'label': 'Audio',
      'icon': Icons.audiotrack_rounded,
      'color': Color(0xFFF59E0B),
      'exts': FileTypes.audio,
    },
    {
      'key': 'document',
      'label': 'Docs',
      'icon': Icons.description_rounded,
      'color': Color(0xFF10B981),
      'exts': FileTypes.documents,
    },
  ];

  @override
  void initState() {
    super.initState();
    _files = List<DuplicateFile>.from(widget.files);
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  List<DuplicateFile> get _filteredFiles {
    if (_activeFilters.isEmpty) return _files;
    return _files.where((file) {
      for (final filter in _activeFilters) {
        final filterData = _filterTypes.firstWhere((f) => f['key'] == filter);
        final exts = filterData['exts'] as List<String>;
        if (exts.contains(file.extension.toLowerCase())) return true;
      }
      return false;
    }).toList();
  }

  int get _selectedCount => _files.where((f) => f.isSelected).length;

  int get _selectedSize =>
      _files.where((f) => f.isSelected).fold(0, (sum, f) => sum + f.size);

  int get _totalSize => _filteredFiles.fold(0, (sum, f) => sum + f.size);

  void _toggleFilter(String key) {
    setState(() {
      if (_activeFilters.contains(key)) {
        _activeFilters.remove(key);
      } else {
        _activeFilters.add(key);
      }
    });
  }

  void _selectAll(bool select) {
    setState(() {
      for (final file in _filteredFiles) {
        file.isSelected = select;
      }
    });
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  int _countForFilter(String key) {
    final exts = _filterTypes
        .firstWhere((f) => f['key'] == key)['exts'] as List<String>;
    return _files.where((f) => exts.contains(f.extension.toLowerCase())).length;
  }

  Future<void> _deleteSelected() async {
    if (_selectedCount == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2538),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Files', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete $_selectedCount files (${_formatSize(_selectedSize)})?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final selectedFiles = _files.where((f) => f.isSelected).toList();
    final freedBytes = await _scanner.deleteFiles(selectedFiles);

    if (!mounted) return;
    setState(() {
      _files.removeWhere((f) => f.isSelected);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deleted ${selectedFiles.length} files, freed ${_formatSize(freedBytes)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatsBar(),
            _buildFilterGrid(),
            Expanded(
              child: _filteredFiles.isEmpty
                  ? _buildEmptyState()
                  : _buildResultsList(),
            ),
            if (_selectedCount > 0) _buildDeleteBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          ),
          Expanded(
            child: Text(
              widget.mode.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (_filteredFiles.isNotEmpty)
            TextButton(
              onPressed: () => _selectAll(true),
              child: const Text('Select All'),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            widget.mode == ScanMode.largeFiles ? 'Large files' : 'Unused',
            _filteredFiles.length.toString(),
            Icons.insert_drive_file_rounded,
          ),
          _buildStatItem(
            'Can free',
            _formatSize(_totalSize),
            Icons.delete_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF3B82F6), size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7A94)),
        ),
      ],
    );
  }

  Widget _buildFilterGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.4,
        children: _filterTypes.map((filter) {
          final key = filter['key'] as String;
          final label = filter['label'] as String;
          final icon = filter['icon'] as IconData;
          final color = filter['color'] as Color;
          final isActive = _activeFilters.contains(key);
          final count = _countForFilter(key);

          return GestureDetector(
            onTap: () => _toggleFilter(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? color.withValues(alpha: 0.15)
                    : const Color(0xFF131B2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? color.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.05),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isActive ? color : color.withValues(alpha: 0.5),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive ? color : Colors.white,
                          ),
                        ),
                        Text(
                          '$count found',
                          style: TextStyle(
                            fontSize: 11,
                            color: isActive
                                ? color.withValues(alpha: 0.7)
                                : const Color(0xFF6B7A94),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 64,
            color: Colors.green.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            widget.mode == ScanMode.largeFiles
                ? 'No Large Files'
                : 'No Unused Files',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: _filteredFiles.length,
      itemBuilder: (context, index) => _buildFileTile(_filteredFiles[index]),
    );
  }

  Widget _buildFileTile(DuplicateFile file) {
    final folderName = p.basename(p.dirname(file.path));
    final subtitle = widget.mode == ScanMode.unusedFiles
        ? '${file.daysUnused} days unused · ${file.sizeFormatted}'
        : '$folderName · ${file.sizeFormatted}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: file.isSelected
            ? const Color(0xFFEF4444).withValues(alpha: 0.08)
            : const Color(0xFF131B2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Checkbox(
            value: file.isSelected,
            onChanged: (value) {
              setState(() => file.isSelected = value ?? false);
            },
            activeColor: const Color(0xFFEF4444),
            checkColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
          _buildThumbnail(file),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _openFile(file),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _openFile(file),
            icon: Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(DuplicateFile file) {
    if (file.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(file.path),
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackIcon(file),
        ),
      );
    }
    return _fallbackIcon(file);
  }

  Widget _fallbackIcon(DuplicateFile file) {
    Color color = const Color(0xFF6B7A94);
    IconData icon = Icons.insert_drive_file_rounded;
    if (file.isVideo) {
      color = const Color(0xFF8B5CF6);
      icon = Icons.videocam_rounded;
    } else if (file.isAudio) {
      color = const Color(0xFFF59E0B);
      icon = Icons.audiotrack_rounded;
    } else if (file.isImage) {
      color = const Color(0xFF3B82F6);
      icon = Icons.image_rounded;
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Future<void> _openFile(DuplicateFile file) async {
    if (file.isImage || file.isVideo || file.isAudio) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MediaPlayerScreen(file: file)),
      );
      return;
    }

    final result = await OpenFile.open(file.path);
    if (!mounted) return;
    if (result.type != ResultType.done) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FileDetailScreen(file: file)),
      );
    }
  }

  Widget _buildDeleteBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF131B2A),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_selectedCount files selected',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_formatSize(_selectedSize)} will be freed',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A94)),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _deleteSelected,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
