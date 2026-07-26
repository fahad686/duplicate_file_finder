import 'package:flutter/material.dart';

import '../models/duplicate_file.dart';
import '../services/file_scanner_service.dart';
import '../widgets/duplicate_group_card.dart';

class ResultsScreen extends StatefulWidget {
  final List<DuplicateGroup> duplicateGroups;

  const ResultsScreen({super.key, required this.duplicateGroups});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final FileScannerService _scanner = FileScannerService();

  Set<String> _activeFilters = {};

  static const _filterTypes = [
    {
      'key': 'image',
      'label': 'Images',
      'icon': Icons.image_rounded,
      'color': Color(0xFF3B82F6),
      'exts': ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'],
    },
    {
      'key': 'video',
      'label': 'Videos',
      'icon': Icons.videocam_rounded,
      'color': Color(0xFF8B5CF6),
      'exts': ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv'],
    },
    {
      'key': 'audio',
      'label': 'Audio',
      'icon': Icons.audiotrack_rounded,
      'color': Color(0xFFF59E0B),
      'exts': ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma'],
    },
    {
      'key': 'document',
      'label': 'Docs',
      'icon': Icons.description_rounded,
      'color': Color(0xFF10B981),
      'exts': [
        '.pdf', '.doc', '.docx', '.xls', '.xlsx',
        '.ppt', '.pptx', '.txt', '.csv',
      ],
    },
  ];

  List<DuplicateGroup> get _filteredGroups {
    if (_activeFilters.isEmpty) return widget.duplicateGroups;

    return widget.duplicateGroups.where((group) {
      return group.files.any((file) {
        for (final filter in _activeFilters) {
          final filterData = _filterTypes.firstWhere((f) => f['key'] == filter);
          final exts = filterData['exts'] as List<String>;
          if (exts.contains(file.extension.toLowerCase())) return true;
        }
        return false;
      });
    }).toList();
  }

  int get _totalDuplicates =>
      _filteredGroups.fold(0, (sum, g) => sum + g.duplicateCount);

  int get _totalWastedSize =>
      _filteredGroups.fold(0, (sum, g) => sum + g.wastedSize);

  int get _selectedSize => widget.duplicateGroups
      .expand((g) => g.files)
      .where((f) => f.isSelected)
      .fold(0, (sum, f) => sum + f.size);

  int get _selectedCount => widget.duplicateGroups
      .expand((g) => g.files)
      .where((f) => f.isSelected)
      .length;

  void _toggleFilter(String key) {
    setState(() {
      if (_activeFilters.contains(key)) {
        _activeFilters.remove(key);
      } else {
        _activeFilters.add(key);
      }
    });
  }

  void _selectAllInGroup(int groupIndex, bool select) {
    setState(() {
      final group = _filteredGroups[groupIndex];
      if (select) {
        for (int i = 1; i < group.files.length; i++) {
          group.files[i].isSelected = true;
        }
      } else {
        for (final file in group.files) {
          file.isSelected = false;
        }
      }
    });
  }

  void _selectAll(bool select) {
    setState(() {
      for (final group in _filteredGroups) {
        if (select) {
          for (int i = 1; i < group.files.length; i++) {
            group.files[i].isSelected = true;
          }
        } else {
          for (final file in group.files) {
            file.isSelected = false;
          }
        }
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
    return widget.duplicateGroups
        .where((g) =>
            g.files.any((f) => exts.contains(f.extension.toLowerCase())))
        .fold(0, (sum, g) => sum + g.duplicateCount);
  }

  Future<void> _deleteSelected() async {
    if (_selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No files selected for deletion')),
      );
      return;
    }

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
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final selectedFiles = widget.duplicateGroups
        .expand((g) => g.files)
        .where((f) => f.isSelected)
        .toList();

    final freedBytes = await _scanner.deleteFiles(selectedFiles);

    if (mounted) {
      setState(() {
        for (final group in widget.duplicateGroups) {
          group.files.removeWhere((f) => f.isSelected);
        }
        widget.duplicateGroups.removeWhere((g) => g.files.length < 2);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Deleted ${selectedFiles.length} files, freed ${_formatSize(freedBytes)}',
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
            Expanded(
              child: _filteredGroups.isEmpty
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
          const Expanded(
            child: Text(
              'Scan Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (_activeFilters.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _activeFilters.clear()),
              child: const Text('Clear Filters'),
            ),
          if (_filteredGroups.isNotEmpty)
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
            'Duplicates',
            _totalDuplicates.toString(),
            Icons.copy_rounded,
          ),
          _buildStatItem(
            'Groups',
            _filteredGroups.length.toString(),
            Icons.folder_open_rounded,
          ),
          _buildStatItem(
            'Wasted',
            _formatSize(_totalWastedSize),
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
                  if (isActive)
                    Icon(
                      Icons.check_circle_rounded,
                      color: color,
                      size: 18,
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
            _activeFilters.isEmpty
                ? Icons.check_circle_outline_rounded
                : Icons.filter_list_off_rounded,
            size: 64,
            color: _activeFilters.isEmpty
                ? Colors.green.withValues(alpha: 0.5)
                : const Color(0xFF6B7A94),
          ),
          const SizedBox(height: 16),
          Text(
            _activeFilters.isEmpty
                ? 'No Duplicates Found'
                : 'No Matches',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _activeFilters.isEmpty
                ? 'Your device is clean!'
                : 'Try removing some filters',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7A94),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: _filteredGroups.length,
      itemBuilder: (context, index) {
        return DuplicateGroupCard(
          group: _filteredGroups[index],
          groupIndex: index,
          onSelectAll: (select) => _selectAllInGroup(index, select),
        );
      },
    );
  }

  Widget _buildDeleteBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
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
