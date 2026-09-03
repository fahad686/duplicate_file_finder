import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/scan_mode.dart';
import 'scanning_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ScanMode? _busyMode;
  ScanMode _pendingMode = ScanMode.duplicates;

  static const _channel = MethodChannel(
    'com.duplicatefilefinder.app/permissions',
  );

  Future<int> _androidSdkInt() async {
    try {
      return await _channel.invokeMethod<int>('getSdkInt') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _openAllFilesAccessSettings() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('openAllFilesAccessSettings');
      } catch (_) {
        await openAppSettings();
      }
    }
  }

  Future<void> _startScan(ScanMode mode) async {
    _pendingMode = mode;
    setState(() => _busyMode = mode);

    final hasPermission = await _requestPermissions();

    if (!hasPermission) {
      if (mounted) {
        setState(() => _busyMode = null);
        await _showPermissionDialog();
      }
      return;
    }

    if (mounted) {
      setState(() => _busyMode = null);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ScanningScreen(mode: mode)),
      );
    }
  }

  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }

    final sdk = await _androidSdkInt();

    if (sdk >= 30) {
      if (await Permission.manageExternalStorage.isGranted) return true;
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> _showPermissionDialog() async {
    final sdk = Platform.isAndroid ? await _androidSdkInt() : 0;
    final needsAllFiles = sdk >= 30;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A2538),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Permission Required',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          needsAllFiles
              ? 'This app needs "All files access" to find duplicate documents, photos, videos, and archives.\n\n'
                  'Tap "Open Settings" and enable "All files access" for this app.'
              : 'This app needs storage permission to scan for duplicate files.\n\n'
                  'Tap "Open Settings" and allow storage access.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (Platform.isAndroid) {
                final sdk = await _androidSdkInt();
                if (sdk >= 30) {
                  await _openAllFilesAccessSettings();
                } else {
                  await openAppSettings();
                }
              } else {
                await openAppSettings();
              }
              await Future.delayed(const Duration(seconds: 2));
              if (!mounted) return;
              final granted = await _requestPermissions();
              if (!mounted || !granted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScanningScreen(mode: _pendingMode),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9EFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 40),
                    _buildMainScanArea(size),
                    const SizedBox(height: 20),
                    _buildToolCards(),
                    const SizedBox(height: 36),
                    _buildInfoCards(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF4A9EFF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.content_copy_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Duplicate Finder',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2233),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: Color(0xFF6B7A94),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainScanArea(Size size) {
    return GestureDetector(
      onTap: _busyMode != null ? null : () => _startScan(ScanMode.duplicates),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E6FEB), Color(0xFF3B82F6), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: _busyMode == ScanMode.duplicates
                  ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.search_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Scan Now',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find duplicate files and free up space',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Tap to Start',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'More tools',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                mode: ScanMode.largeFiles,
                title: 'Large Files',
                desc: 'Biggest files using the most storage',
                icon: Icons.sd_storage_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildToolCard(
                mode: ScanMode.unusedFiles,
                title: 'Unused Files',
                desc: 'Old files you have not opened in months',
                icon: Icons.history_rounded,
                color: const Color(0xFF14B8A6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolCard({
    required ScanMode mode,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    final busy = _busyMode == mode;
    return GestureDetector(
      onTap: _busyMode != null ? null : () => _startScan(mode),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF131B2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: busy
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7A94),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How it works',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildStepCard(
                step: '1',
                title: 'Scan',
                desc: 'Detects all duplicate files using MD5 hash',
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStepCard(
                step: '2',
                title: 'Review',
                desc: 'Preview and select which files to remove',
                color: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStepCard(
                step: '3',
                title: 'Delete',
                desc: 'Remove duplicates and reclaim storage',
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7A94),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
