import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

enum FileSortOption { newest, oldest, largest, smallest, folder }

extension FileSortLabel on FileSortOption {
  String get label => switch (this) {
    FileSortOption.newest => 'Newest',
    FileSortOption.oldest => 'Oldest',
    FileSortOption.largest => 'Largest',
    FileSortOption.smallest => 'Smallest',
    FileSortOption.folder => 'Folder',
  };
}

class FileFilterBar extends StatelessWidget {
  final List<String> folders;
  final String? selectedFolder;
  final int? modifiedWithinDays;
  final FileSortOption sort;
  final ValueChanged<String?> onFolderChanged;
  final ValueChanged<int?> onDateChanged;
  final ValueChanged<FileSortOption> onSortChanged;
  final VoidCallback onClear;

  const FileFilterBar({
    super.key,
    required this.folders,
    required this.selectedFolder,
    required this.modifiedWithinDays,
    required this.sort,
    required this.onFolderChanged,
    required this.onDateChanged,
    required this.onSortChanged,
    required this.onClear,
  });

  bool get hasFilters => selectedFolder != null || modifiedWithinDays != null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        scrollDirection: Axis.horizontal,
        children: [
          _popupChip<FileSortOption>(
            context,
            icon: Icons.swap_vert_rounded,
            label: 'Sort: ${sort.label}',
            value: sort,
            values: FileSortOption.values,
            itemLabel: (value) => value.label,
            onSelected: onSortChanged,
          ),
          const SizedBox(width: 8),
          _popupChip<String>(
            context,
            icon: Icons.folder_rounded,
            label: selectedFolder == null
                ? 'All folders'
                : p.basename(selectedFolder!),
            value: selectedFolder ?? '',
            values: ['', ...folders],
            itemLabel: (value) =>
                value.isEmpty ? 'All folders' : p.basename(value),
            onSelected: (value) =>
                onFolderChanged(value.isEmpty ? null : value),
          ),
          const SizedBox(width: 8),
          _popupChip<int>(
            context,
            icon: Icons.calendar_month_rounded,
            label: _dateLabel(modifiedWithinDays),
            value: modifiedWithinDays ?? 0,
            values: const [0, 7, 30, 180, 365],
            itemLabel: (value) => _dateLabel(value == 0 ? null : value),
            onSelected: (value) => onDateChanged(value == 0 ? null : value),
          ),
          if (hasFilters) ...[
            const SizedBox(width: 8),
            ActionChip(
              onPressed: onClear,
              backgroundColor: const Color(0xFF241A24),
              side: const BorderSide(color: Color(0xFF5F2A35)),
              avatar: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Color(0xFFEF4444),
              ),
              label: const Text(
                'Clear',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _popupChip<T>(
    BuildContext context, {
    required IconData icon,
    required String label,
    required T value,
    required List<T> values,
    required String Function(T value) itemLabel,
    required ValueChanged<T> onSelected,
  }) {
    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onSelected,
      color: const Color(0xFF1A2538),
      position: PopupMenuPosition.under,
      itemBuilder: (context) => values
          .map(
            (item) => PopupMenuItem<T>(
              value: item,
              child: Row(
                children: [
                  if (item == value)
                    const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Color(0xFF4A9EFF),
                    )
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      itemLabel(item),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF131B2A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF4A9EFF)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF6B7A94)),
          ],
        ),
      ),
    );
  }

  String _dateLabel(int? days) => switch (days) {
    null => 'Any date',
    7 => 'Last 7 days',
    30 => 'Last 30 days',
    180 => 'Last 6 months',
    365 => 'Last year',
    _ => 'Last $days days',
  };
}
