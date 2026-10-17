import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ReleaseUpdateInfo {
  const ReleaseUpdateInfo({
    required this.versionTag,
    required this.notes,
    required this.apkUrl,
  });

  final String versionTag;
  final String notes;
  final String apkUrl;
}

/// Android GitHub Release updater. `GITHUB_REPO` may override the default.
class AppUpdateService {
  static const _repo = String.fromEnvironment(
    'GITHUB_REPO',
    defaultValue: 'PiyushGupta-45/DesiFit',
  );
  static const _channel = MethodChannel('com.desifit.desi_fit/app_update');

  Future<bool> canRequestPackageInstalls() async =>
      await _channel.invokeMethod<bool>('canRequestPackageInstalls') ?? false;

  Future<void> openInstallUnknownAppsSettings() =>
      _channel.invokeMethod<void>('openInstallUnknownAppsSettings');

  Future<void> cleanupDownloadedApks() =>
      _channel.invokeMethod<void>('cleanupDownloadedApks');

  Future<ReleaseUpdateInfo?> checkForUpdate() async {
    if (kIsWeb || !Platform.isAndroid || !_repo.contains('/')) return null;

    final response = await http.get(
      Uri.parse('https://api.github.com/repos/$_repo/releases/latest'),
      headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'DesiFit-Updater',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );
    if (response.statusCode != 200) return null;

    final release = jsonDecode(response.body) as Map<String, dynamic>;
    final tag = (release['tag_name'] ?? '').toString().trim();
    final package = await PackageInfo.fromPlatform();
    if (tag.isEmpty || !_isNewer(tag, package.version, package.buildNumber)) {
      return null;
    }

    final assets = (release['assets'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();
    final apk = assets
        .map((asset) => (asset['browser_download_url'] ?? '').toString())
        .where((url) => url.toLowerCase().endsWith('.apk'))
        .firstWhere((url) => url.isNotEmpty, orElse: () => '');
    if (apk.isEmpty) return null;

    return ReleaseUpdateInfo(
      versionTag: tag,
      notes: (release['body'] ?? 'A new version of DesiFit is available.')
          .toString()
          .trim(),
      apkUrl: apk,
    );
  }

  Stream<OtaEvent> downloadAndInstall(ReleaseUpdateInfo update) {
    final fileName = 'desi_fit_${update.versionTag.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}.apk';
    return OtaUpdate().execute(update.apkUrl, destinationFilename: fileName);
  }

  bool _isNewer(String remote, String current, String build) {
    final a = _parts(remote);
    final b = _parts('$current+$build');
    for (var i = 0; i < (a.length > b.length ? a.length : b.length); i++) {
      final left = i < a.length ? a[i] : 0;
      final right = i < b.length ? b[i] : 0;
      if (left != right) return left > right;
    }
    return false;
  }

  List<int> _parts(String value) => value
      .toLowerCase()
      .replaceFirst('v', '')
      .replaceAll(RegExp(r'[-+]'), '.')
      .split('.')
      .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
}
