import 'dart:io';

import 'package:flutter/services.dart';

import '../models/security_check.dart';

class SecurityScanService {
  static const _channel = MethodChannel(
    'com.duplicatefilefinder.app/security',
  );

  Future<SecurityScanResult> scan() async {
    if (Platform.isAndroid) {
      final data = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'runSecurityScan',
      );
      if (data == null) {
        throw StateError('Security scan returned no data');
      }
      return SecurityScanResult.fromMap(data);
    }

    return _scanIos();
  }

  Future<void> openSettings(String action) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('openSettings', action);
  }

  Future<SecurityScanResult> _scanIos() async {
    final jailbroken = await _looksJailbroken();
    return SecurityScanResult(
      platform: 'ios',
      checks: [
        SecurityCheck(
          id: 'jailbreak',
          title: 'Jailbreak tools',
          status: jailbroken ? SecurityStatus.fail : SecurityStatus.pass,
          summary: jailbroken
              ? 'This iPhone looks jailbroken'
              : 'No common jailbreak files were found',
          detail: jailbroken
              ? 'Jailbroken phones are much easier to bug. If you did not jailbreak this iPhone, treat it as compromised and restore it from a computer you trust.'
              : 'iOS blocks other apps from inspecting each other. This check only looks for common jailbreak files.',
        ),
        const SecurityCheck(
          id: 'ios_limits',
          title: 'What iOS can check',
          status: SecurityStatus.info,
          summary: 'iOS cannot scan other apps for spyware',
          detail:
              'Apple does not let apps list hidden spyware, USB debugging, or accessibility services. Look for a recording indicator (orange or green dot), unknown configuration profiles in Settings, and apps you did not install. A factory reset is the most reliable cleanup.',
          settingsAction: null,
        ),
      ],
    );
  }

  Future<bool> _looksJailbroken() async {
    const paths = [
      '/Applications/Cydia.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/private/var/lib/apt/',
      '/usr/bin/ssh',
    ];

    for (final path in paths) {
      try {
        if (await File(path).exists()) return true;
      } catch (_) {}
    }

    try {
      final probe = File('/private/security_check_probe.txt');
      await probe.writeAsString('probe');
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
