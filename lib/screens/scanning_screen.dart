import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/file_scanner_service.dart';
import 'results_screen.dart';

class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen>
    with SingleTickerProviderStateMixin {
  final FileScannerService _scanner = FileScannerService();
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  int _filesScanned = 0;
  int _duplicatesFound = 0;
  String _currentPath = '';
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _startScan();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    _scanner.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _filesScanned = progress.filesScanned;
          _duplicatesFound = progress.duplicatesFound;
          _currentPath = progress.currentPath;
        });
      }
    });

    try {
      final duplicates = await _scanner.scanDirectories([
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Documents',
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/DCIM',
      ]);

      if (mounted) {
        setState(() => _isScanning = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultsScreen(duplicateGroups: duplicates),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1724),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Scanning',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(size.width * 0.06),
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.03),
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: size.width * 0.28,
                        height: size.width * 0.28,
                        constraints: const BoxConstraints(
                          minWidth: 100,
                          minHeight: 100,
                          maxWidth: 140,
                          maxHeight: 140,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF4A9EFF).withValues(alpha: 0.3),
                              const Color(0xFF4A9EFF).withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF1E3A5F),
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            size: size.width * 0.1,
                            color: const Color(0xFF4A9EFF),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),
                    Text(
                      'Scanning Files...',
                      style: TextStyle(
                        fontSize: size.width * 0.055,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Looking for duplicate files',
                      style: TextStyle(
                        fontSize: size.width * 0.035,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    SizedBox(height: size.height * 0.04),
                    _buildStatRow('Files Scanned', _filesScanned.toString()),
                    const SizedBox(height: 16),
                    _buildStatRow(
                      'Duplicates Found',
                      _duplicatesFound.toString(),
                    ),
                    const SizedBox(height: 16),
                    _buildCurrentPath(),
                    const SizedBox(height: 24),
                    LinearProgressIndicator(
                      value: null,
                      backgroundColor: const Color(0xFF1A2538),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF4A9EFF),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A9EFF),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPath() {
    if (_currentPath.isEmpty) return const SizedBox.shrink();

    final pathParts = _currentPath.split('/');
    final shortPath = pathParts.length > 3
        ? '.../${pathParts.sublist(pathParts.length - 2).join('/')}'
        : _currentPath;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2538),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        shortPath,
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.4),
          fontFamily: 'monospace',
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
