import 'package:flutter/material.dart';

// import '../widgets/bottom_banner_ad.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _scanImages = true;
  bool _scanVideos = true;
  bool _scanAudio = true;
  bool _scanDocuments = true;
  bool _scanArchives = true;
  int _minFileSize = 0;
  bool _autoSelectOldest = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1724),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
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
            // const BottomBannerAd(),
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
            _scanImages,
            (value) => setState(() => _scanImages = value),
          ),
          _buildDivider(),
          _buildToggleTile(
            'Videos',
            'MP4, AVI, MKV, MOV',
            Icons.videocam_rounded,
            Colors.purple,
            _scanVideos,
            (value) => setState(() => _scanVideos = value),
          ),
          _buildDivider(),
          _buildToggleTile(
            'Audio',
            'MP3, WAV, FLAC, AAC',
            Icons.audio_file_rounded,
            Colors.orange,
            _scanAudio,
            (value) => setState(() => _scanAudio = value),
          ),
          _buildDivider(),
          _buildToggleTile(
            'Documents',
            'PDF, DOC, TXT',
            Icons.description_rounded,
            Colors.green,
            _scanDocuments,
            (value) => setState(() => _scanDocuments = value),
          ),
          _buildDivider(),
          _buildToggleTile(
            'Archives',
            'ZIP, RAR, 7Z',
            Icons.folder_zip_rounded,
            Colors.amber,
            _scanArchives,
            (value) => setState(() => _scanArchives = value),
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
        activeColor: const Color(0xFF4A9EFF),
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
                _formatSize(_minFileSize),
                style: const TextStyle(
                  color: Color(0xFF4A9EFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _minFileSize.toDouble(),
            min: 0,
            max: 1024 * 1024, // 1MB
            divisions: 20,
            activeColor: const Color(0xFF4A9EFF),
            inactiveColor: const Color(0xFF0F1724),
            onChanged: (value) => setState(() => _minFileSize = value.toInt()),
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
          'Automatically select older duplicates for deletion',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
        value: _autoSelectOldest,
        onChanged: (value) => setState(() => _autoSelectOldest = value),
        activeColor: const Color(0xFF4A9EFF),
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
          _buildAboutRow('Developer', 'Your Name'),
          const SizedBox(height: 12),
          _buildAboutRow('Contact', 'your@email.com'),
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
        Text(
          value,
          style: const TextStyle(color: Colors.white),
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
