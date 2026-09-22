/// Информация об обновлении, прочитанная из version.json.
class AppUpdateInfo {
  AppUpdateInfo({
    required this.latestVersion,
    this.minSupportedVersion,
    this.notes,
    this.forceUpdate = false,
    this.androidUrl,
    this.iosUrl,
  });

  final String latestVersion;
  final String? minSupportedVersion;
  final String? notes;
  final bool forceUpdate;
  final String? androidUrl;
  final String? iosUrl;

  bool isNewerThan(String current) =>
      compareVersions(latestVersion, current) > 0;

  bool requiresUpdate(String current) {
    final String min = minSupportedVersion ?? '';
    return min.isNotEmpty && compareVersions(current, min) < 0;
  }

  /// >0 — a новее b; <0 — a старше b; 0 — равны. Формат: 1.2.10
  static int compareVersions(String a, String b) {
    final List<String> pa = a.split('.');
    final List<String> pb = b.split('.');
    final int n = pa.length > pb.length ? pa.length : pb.length;
    for (int i = 0; i < n; i++) {
      final int x = i < pa.length ? (int.tryParse(pa[i]) ?? 0) : 0;
      final int y = i < pb.length ? (int.tryParse(pb[i]) ?? 0) : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) => AppUpdateInfo(
        latestVersion: (json['latest_version'] ?? '') as String,
        minSupportedVersion: json['min_supported_version'] as String?,
        notes: json['notes'] as String?,
        forceUpdate: json['force_update'] as bool? ?? false,
        androidUrl: json['android_url'] as String?,
        iosUrl: json['ios_url'] as String?,
      );
}
