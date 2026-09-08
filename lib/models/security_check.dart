enum SecurityStatus { pass, warning, fail, info }

enum SecurityRiskLevel { safe, attention, high }

class SecurityCheck {
  final String id;
  final String title;
  final SecurityStatus status;
  final String summary;
  final String detail;
  final String? settingsAction;
  final List<String> items;

  const SecurityCheck({
    required this.id,
    required this.title,
    required this.status,
    required this.summary,
    required this.detail,
    this.settingsAction,
    this.items = const [],
  });

  factory SecurityCheck.fromMap(Map<dynamic, dynamic> map) {
    return SecurityCheck(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      status: SecurityStatusX.fromName(map['status'] as String? ?? 'info'),
      summary: map['summary'] as String? ?? '',
      detail: map['detail'] as String? ?? '',
      settingsAction: map['settingsAction'] as String?,
      items: ((map['items'] as List?) ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class SecurityScanResult {
  final String platform;
  final List<SecurityCheck> checks;

  const SecurityScanResult({
    required this.platform,
    required this.checks,
  });

  factory SecurityScanResult.fromMap(Map<dynamic, dynamic> map) {
    final rawChecks = (map['checks'] as List?) ?? const [];
    return SecurityScanResult(
      platform: map['platform'] as String? ?? 'unknown',
      checks: rawChecks
          .whereType<Map>()
          .map(SecurityCheck.fromMap)
          .toList(),
    );
  }

  int get failCount =>
      checks.where((check) => check.status == SecurityStatus.fail).length;

  int get warningCount =>
      checks.where((check) => check.status == SecurityStatus.warning).length;

  int get passCount =>
      checks.where((check) => check.status == SecurityStatus.pass).length;

  SecurityRiskLevel get riskLevel {
    if (failCount > 0) return SecurityRiskLevel.high;
    if (warningCount > 0) return SecurityRiskLevel.attention;
    return SecurityRiskLevel.safe;
  }
}

extension SecurityStatusX on SecurityStatus {
  static SecurityStatus fromName(String name) {
    return switch (name) {
      'pass' => SecurityStatus.pass,
      'warning' => SecurityStatus.warning,
      'fail' => SecurityStatus.fail,
      _ => SecurityStatus.info,
    };
  }
}
