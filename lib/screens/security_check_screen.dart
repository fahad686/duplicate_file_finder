import 'package:flutter/material.dart';

import '../models/security_check.dart';
import '../services/security_scan_service.dart';

class SecurityCheckScreen extends StatefulWidget {
  const SecurityCheckScreen({super.key});

  @override
  State<SecurityCheckScreen> createState() => _SecurityCheckScreenState();
}

class _SecurityCheckScreenState extends State<SecurityCheckScreen>
    with SingleTickerProviderStateMixin {
  static const _scanSteps = [
    'Known spyware apps',
    'Root and hidden tools',
    'Screen-reading access',
    'USB and wireless debugging',
    'Overlay and notification access',
    'VPN and certificates',
  ];

  final SecurityScanService _service = SecurityScanService();
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  bool _scanning = true;
  String? _error;
  SecurityScanResult? _result;
  int _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.86, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _runScan();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runScan() async {
    setState(() {
      _scanning = true;
      _error = null;
      _result = null;
      _stepIndex = 0;
    });
    _controller.repeat(reverse: true);

    final scan = _service.scan();
    for (var i = 0; i < _scanSteps.length; i++) {
      if (!mounted) return;
      setState(() => _stepIndex = i);
      await Future.delayed(const Duration(milliseconds: 420));
    }

    try {
      final result = await scan;
      if (!mounted) return;
      _controller.stop();
      setState(() {
        _result = result;
        _scanning = false;
      });
    } catch (error) {
      if (!mounted) return;
      _controller.stop();
      setState(() {
        _scanning = false;
        _error = 'Could not finish the security check.\n$error';
      });
    }
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
              child: _scanning
                  ? _buildScanning()
                  : _error != null
                      ? _buildError()
                      : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
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
          const Expanded(
            child: Text(
              'Phone Security',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (!_scanning && _result != null)
            IconButton(
              onPressed: _runScan,
              tooltip: 'Scan again',
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildScanning() {
    final step = _scanSteps[_stepIndex.clamp(0, _scanSteps.length - 1)];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 36),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              );
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF22C55E).withValues(alpha: 0.3),
                    const Color(0xFF22C55E).withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF163226),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  size: 44,
                  color: Color(0xFF22C55E),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Checking this phone...',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Looking for signs this device may be bugged',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2538),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              step,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            backgroundColor: const Color(0xFF1A2538),
            color: const Color(0xFF22C55E),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _runScan,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final result = _result!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _buildScoreCard(result),
        const SizedBox(height: 12),
        Text(
          'No app can prove a phone is not bugged. This checkup looks for common warning signs.',
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Checks',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...result.checks.map(_buildCheckCard),
        const SizedBox(height: 22),
        const Text(
          'Help & tips',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        _buildTip(
          Icons.mic_none_rounded,
          'Watch the status dots',
          'Android and iOS show an orange or green dot when the microphone or camera is in use. If that appears when you are not using those features, check which app is running.',
        ),
        _buildTip(
          Icons.phonelink_erase_rounded,
          'If you think the phone is bugged',
          'Do not type passwords here. Use another device you trust, change important account passwords, then factory-reset this phone.',
        ),
        _buildTip(
          Icons.apps_rounded,
          'Review apps you did not install',
          'Open system settings and look for unknown apps, extra VPN profiles, or accessibility tools you never turned on.',
        ),
      ],
    );
  }

  Widget _buildScoreCard(SecurityScanResult result) {
    final (title, subtitle, color, icon) = switch (result.riskLevel) {
      SecurityRiskLevel.safe => (
          'No warning signs found',
          'This phone does not show the usual spyware setup.',
          const Color(0xFF22C55E),
          Icons.verified_user_rounded,
        ),
      SecurityRiskLevel.attention => (
          'Needs a closer look',
          '${result.warningCount} setting${result.warningCount == 1 ? '' : 's'} could be used to watch this phone.',
          const Color(0xFFF59E0B),
          Icons.privacy_tip_rounded,
        ),
      SecurityRiskLevel.high => (
          'Serious warning signs',
          '${result.failCount} high-risk issue${result.failCount == 1 ? '' : 's'} found. Review the red items first.',
          const Color(0xFFEF4444),
          Icons.gpp_maybe_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _miniStat('Clear', result.passCount, const Color(0xFF22C55E)),
              const SizedBox(width: 8),
              _miniStat('Review', result.warningCount, const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              _miniStat('Risk', result.failCount, const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1724).withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckCard(SecurityCheck check) {
    final color = switch (check.status) {
      SecurityStatus.pass => const Color(0xFF22C55E),
      SecurityStatus.warning => const Color(0xFFF59E0B),
      SecurityStatus.fail => const Color(0xFFEF4444),
      SecurityStatus.info => const Color(0xFF4A9EFF),
    };
    final icon = switch (check.status) {
      SecurityStatus.pass => Icons.check_circle_rounded,
      SecurityStatus.warning => Icons.warning_rounded,
      SecurityStatus.fail => Icons.error_rounded,
      SecurityStatus.info => Icons.info_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2538),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(icon, color: color, size: 22),
          title: Text(
            check.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            check.summary,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          children: [
            Text(
              check.detail,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            if (check.items.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...check.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle, size: 6, color: color),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (check.settingsAction != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _service.openSettings(check.settingsAction!),
                  child: const Text('Open settings'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTip(IconData icon, String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF4A9EFF), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF6B7A94),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
