import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/file_scanner_service.dart';

Future<void> showDeletionProgressDialog(
  BuildContext context,
  ValueListenable<DeleteProgress> progress,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: const Color(0xFF1A2538),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Deleting Files',
          style: TextStyle(color: Colors.white),
        ),
        content: ValueListenableBuilder<DeleteProgress>(
          valueListenable: progress,
          builder: (context, value, child) {
            final percent = (value.fraction * 100).round();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deleting ${value.completed} of ${value.total}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  value.currentFile,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8B9AB5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: value.fraction,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: const Color(0xFF0D1117),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF4A9EFF),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$percent%',
                    style: const TextStyle(
                      color: Color(0xFF4A9EFF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
