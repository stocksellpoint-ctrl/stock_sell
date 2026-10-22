import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_info.dart';

class UpdateInfo {
  final String version;      // e.g. "1.0.1"
  final String apkUrl;       // direct download URL for the APK asset
  final String htmlUrl;      // human-readable release page
  final String releaseNotes;

  UpdateInfo({
    required this.version,
    required this.apkUrl,
    required this.htmlUrl,
    required this.releaseNotes,
  });
}

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  /// Fetches the latest release from GitHub and returns update info if
  /// a newer version than [currentVersion] exists; otherwise null.
  Future<UpdateInfo?> checkForUpdate({
    required String currentVersion,
  }) async {
    final uri = Uri.parse(
      'https://api.github.com/repos/${AppInfo.githubOwner}/${AppInfo.githubRepo}/releases/latest',
    );

    final res = await http.get(uri, headers: {
      'Accept': 'application/vnd.github+json',
    });

    if (res.statusCode != 200) {
      throw Exception('GitHub returned ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final tagName = (data['tag_name'] as String?) ?? '';
    final latest = tagName.startsWith('v') ? tagName.substring(1) : tagName;

    if (!_isNewer(latest, currentVersion)) return null;

    final assets = (data['assets'] as List?) ?? [];
    String? apkUrl;
    for (final a in assets) {
      final name = (a['name'] as String?) ?? '';
      if (name == AppInfo.apkAssetName) {
        apkUrl = a['browser_download_url'] as String?;
        break;
      }
    }
    if (apkUrl == null) {
      throw Exception(
        'Release ${tagName} does not contain ${AppInfo.apkAssetName}',
      );
    }

    return UpdateInfo(
      version: latest,
      apkUrl: apkUrl,
      htmlUrl: (data['html_url'] as String?) ?? '',
      releaseNotes: (data['body'] as String?) ?? '',
    );
  }

  /// Semver comparison: is [candidate] greater than [current]?
  bool _isNewer(String candidate, String current) {
    final a = candidate.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final b = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final len = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < len; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = i < b.length ? b[i] : 0;
      if (av > bv) return true;
      if (av < bv) return false;
    }
    return false;
  }
}