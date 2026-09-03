import 'package:flutter/material.dart';

import '../services/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  AppSettings _settings = const AppSettings();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _settingsService.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loaded = true;
    });
  }

  Future<void> _update(AppSettings settings) async {
    setState(() => _settings = settings);
    await _settingsService.save(settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1724),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: !_loaded
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4A9EFF),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('File Types to Scan'),
                          const SizedBox(height: 12),
                          _buildFileTypeToggles(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Scan Options'),
                          const SizedBox(height: 12),
                          _buildScanOptions(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Large Files'),
                          const SizedBox(height: 12),
                          _buildLargeFileOptions(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Unused Files'),
                          const SizedBox(height: 12),
                          _buildUnusedOptions(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Auto-Selection'),
                          const SizedBox(height: 12),
                          _buildAutoSelection(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('About'),
                          const SizedBox(height: 12),
                          _buildAbout(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildFileTypeToggles() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2538),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildToggleTile(
            'Images',
            'JPG, PNG, GIF, WEBP',
            Icons.image_rounded,
            Colors.blue,
            _settings.scanImages,
            (value) => _update(_settings.copyWith(scanImages: value)),
          ),
          _buildDivider(),
          _buildToggleTile(
            'Videos',
            'MP4, AVI, MKV, MOV',
            Icons.videocam_rounded,
            Colors.purple,
            _settings.scanVideos,
            (value) => _update(_settings.copyWith(scanVideos: value)),
          ),
          _buildDivider(),
          _buildToggleTile(
            'Audio',
            'MP3, WAV, FLAC, AAC',
            Icons.audio_file_rounded,
            Colors.orange,
            _settings.scanAudio,
            (value) => _update(_settings.copyWith(scanAudio: value)),
          ),
          _buildDivider(),
          _buildToggleTile(
            'Documents',
            'PDF, DOC, TXT',
            Icons.description_rounded,
            Colors.green,
            _settings.scanDocuments,
            (value) => _update(_settings.copyWith(scanDocuments: value)),
          ),
          _buildDivider(),
          _buildToggleTile(
            'Archives',
            'ZIP, RAR, 7Z',
            Icons.folder_zip_rounded,
            Colors.amber,
            _settings.scanArchives,
            (value) => _update(_settings.copyWith(scanArchives: value)),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF4A9EFF),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 56,
      color: Colors.white.withValues(alpha: 0.05),
    );
  }

  Widget _buildScanOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2538),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Minimum File Size',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                _formatSize(_settings.minFileSize),
                style: const TextStyle(
                  color: Color(0xFF4A9EFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _settings.minFileSize.toDouble(),
            min: 0,
            max: 1024 * 1024,
            divisions: 20,
            activeColor: const Color(0xFF4A9EFF),
            inactiveColor: const Color(0xFF0F1724),
            onChanged: (value) =>
                _update(_settings.copyWith(minFileSize: value.toInt())),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeFileOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2538),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Minimum large file size',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                _formatSize(_settings.largeFileMinSize),
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _settings.largeFileMinSize.toDouble().clamp(
              10.0 * 1024 * 1024,
              200.0 * 1024 * 1024,
            ),
            min: 10 * 1024 * 1024,
            max: 200 * 1024 * 1024,
            divisions: 19,
            activeColor: const Color(0xFFF59E0B),
            inactiveColor: const Color(0xFF0F1724),
            onChanged: (value) =>
                _update(_settings.copyWith(largeFileMinSize: value.toInt())),
          ),
          Text(
            'Only files this size or larger appear in Large Files',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnusedOptions() {
    const options = [30, 90, 180, 365];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2538),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Not used for at least',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((days) {
              final selected = _settings.unusedDays == days;
              return GestureDetector(
                onTap: () => _update(_settings.copyWith(unusedDays: days)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF14B8A6).withValues(alpha: 0.2)
                        : const Color(0xFF0F1724),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF14B8A6)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    days == 365 ? '1 year' : '$days days',
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF14B8A6)
                          : Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSelection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2538),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: const Text(
          'Auto-select oldest files',
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          'Keep the newest copy and select older duplicates for deletion',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
        value: _settings.autoSelectOldest,
        onChanged: (value) =>
            _update(_settings.copyWith(autoSelectOldest: value)),
        activeThumbColor: const Color(0xFF4A9EFF),
      ),
    );
  }

  Widget _buildAbout() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2538),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAboutRow('Version', '1.0.0'),
          const SizedBox(height: 12),
          _buildAboutRow('Application ID', 'com.duplicatefilefinder.app'),
        ],
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _formatSize(int bytes) {
    if (bytes == 0) return 'No minimum';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
