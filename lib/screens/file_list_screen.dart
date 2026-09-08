import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

import '../models/duplicate_file.dart';
import '../models/file_types.dart';
import '../models/scan_mode.dart';
import '../services/file_scanner_service.dart';
import '../widgets/deletion_progress_dialog.dart';
import '../widgets/file_filter_bar.dart';
import '../widgets/media_thumbnail.dart';
import 'file_detail_screen.dart';
import 'media_player_screen.dart';

class FileListScreen extends StatefulWidget {
  final ScanMode mode;
  final List<DuplicateFile> files;

  const FileListScreen({super.key, required this.mode, required this.files});

  @override
  State<FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  final FileScannerService _scanner = FileScannerService();
  final Set<String> _activeFilters = {};
  late List<DuplicateFile> _files;
  String? _selectedFolder;
  int? _modifiedWithinDays;
  FileSortOption _sort = FileSortOption.newest;

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
    final cutoff = _modifiedWithinDays == null
        ? null
        : DateTime.now().subtract(Duration(days: _modifiedWithinDays!));

    final files = _files.where((file) {
      if (_activeFilters.isNotEmpty) {
        var matchesType = false;
        for (final filter in _activeFilters) {
          final filterData = _filterTypes.firstWhere((f) => f['key'] == filter);
          final exts = filterData['exts'] as List<String>;
          if (exts.contains(file.extension.toLowerCase())) {
            matchesType = true;
            break;
          }
        }
        if (!matchesType) return false;
      }

      if (_selectedFolder != null && p.dirname(file.path) != _selectedFolder) {
        return false;
      }

      final date = widget.mode == ScanMode.unusedFiles
          ? file.lastUsed
          : file.lastModified;
      if (cutoff != null && date.isBefore(cutoff)) return false;
      return true;
    }).toList();

    files.sort((a, b) {
      final aDate = widget.mode == ScanMode.unusedFiles
          ? a.lastUsed
          : a.lastModified;
      final bDate = widget.mode == ScanMode.unusedFiles
          ? b.lastUsed
          : b.lastModified;
      return switch (_sort) {
        FileSortOption.newest => bDate.compareTo(aDate),
        FileSortOption.oldest => aDate.compareTo(bDate),
        FileSortOption.largest => b.size.compareTo(a.size),
        FileSortOption.smallest => a.size.compareTo(b.size),
        FileSortOption.folder => p.dirname(a.path).compareTo(p.dirname(b.path)),
      };
    });
    return files;
  }

  List<String> get _folders =>
      _files.map((file) => p.dirname(file.path)).toSet().toList()..sort();

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
    final exts =
        _filterTypes.firstWhere((f) => f['key'] == key)['exts'] as List<String>;
    return _files.where((f) => exts.contains(f.extension.toLowerCase())).length;
  }

  Future<void> _deleteSelected() async {
    if (_selectedCount == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2538),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Files',
          style: TextStyle(color: Colors.white),
        ),
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

    if (confirmed != true || !mounted) return;

    final selectedFiles = _files.where((f) => f.isSelected).toList();
    final progress = ValueNotifier(
      DeleteProgress(
        completed: 0,
        total: selectedFiles.length,
        currentFile: 'Preparing...',
      ),
    );
    final dialogFuture = showDeletionProgressDialog(context, progress);

    final result = await _scanner.deleteFiles(
      selectedFiles,
      onProgress: (value) => progress.value = value,
    );

    if (!mounted) {
      progress.dispose();
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();
    await dialogFuture;
    progress.dispose();

    final deletedPaths = result.deletedFiles.map((file) => file.path).toSet();
    setState(() {
      _files.removeWhere((file) => deletedPaths.contains(file.path));
    });

    final failureMessage = result.failedCount == 0
        ? ''
        : ' · ${result.failedCount} could not be deleted';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Deleted ${result.deletedFiles.length} files, freed '
            '${_formatSize(result.freedBytes)}$failureMessage',
          ),
        ),
      );
    }
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
            FileFilterBar(
              folders: _folders,
              selectedFolder: _selectedFolder,
              modifiedWithinDays: _modifiedWithinDays,
              sort: _sort,
              onFolderChanged: (folder) =>
                  setState(() => _selectedFolder = folder),
              onDateChanged: (days) =>
                  setState(() => _modifiedWithinDays = days),
              onSortChanged: (sort) => setState(() => _sort = sort),
              onClear: () => setState(() {
                _activeFilters.clear();
                _selectedFolder = null;
                _modifiedWithinDays = null;
              }),
            ),
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
    final date = widget.mode == ScanMode.unusedFiles
        ? file.lastUsed
        : file.lastModified;
    final dateLabel = DateFormat('MMM d, y · h:mm a').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: file.isSelected
            ? const Color(0xFFEF4444).withValues(alpha: 0.08)
            : const Color(0xFF131B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openFile(file),
            child: MediaThumbnail(
              file: file,
              width: 112,
              height: 88,
              borderRadius: 10,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        file.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Checkbox(
                      value: file.isSelected,
                      onChanged: (value) {
                        setState(() => file.isSelected = value ?? false);
                      },
                      activeColor: const Color(0xFFEF4444),
                      checkColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.folder_rounded,
                      size: 13,
                      color: Color(0xFF6B7A94),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        folderName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8B9AB5),
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
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  children: [
                    _infoTag(file.sizeFormatted),
                    _infoTag(file.extension.toUpperCase()),
                    if (widget.mode == ScanMode.unusedFiles)
                      _infoTag('${file.daysUnused} days unused'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Color(0xFF8B9AB5)),
      ),
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
      decoration: const BoxDecoration(color: Color(0xFF131B2A)),
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7A94),
                  ),
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
