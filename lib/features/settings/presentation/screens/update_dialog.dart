
import 'package:flutter/material.dart';
import 'package:github_release_apk_updater/github_release_apk_updater.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_info.dart';

/// Confirms with the user whether to update now.

class UpdateAvailableDialog extends StatelessWidget {
  final GithubAPKRelease release;

  const UpdateAvailableDialog({super.key, required this.release});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Update available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Version ${release.version} is available.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Later'),
        ),
        TextButton(
          onPressed: () async {
            // Construct the release page URL from AppInfo
            final htmlUrl =
                'https://github.com/${AppInfo.githubOwner}/${AppInfo.githubRepo}/releases/tag/v${release.version}';
            final uri = Uri.parse(htmlUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: const Text('View release'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Update now'),
        ),
      ],
    );
  }
}

/// Downloads the APK with a progress bar, then triggers the installer.
/// Uses the package's [ApkDownloaderService] and [GithubReleaseApkUpdater].
class UpdateDownloadDialog extends StatefulWidget {
  final GithubAPKRelease release;

  const UpdateDownloadDialog({super.key, required this.release});

  @override
  State<UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}

class _UpdateDownloadDialogState extends State<UpdateDownloadDialog> {
  double _progress = 0;
  String _status = 'Preparing…';
  bool _started = false;
  bool _failed = false;

  final _downloader = ApkDownloaderService();
  final _updater = GithubReleaseApkUpdater();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;

    try {
      setState(() => _status = 'Downloading...');

      // 1. Download the APK using the package's downloader.
      // It uses dio internally and correctly handles GitHub's redirects.
      final filePath = await _downloader.downloadAPK(
        widget.release.apkUrl,
        null, // optional token for private repos
        (received, total) {
          if (!mounted) return;
          if (total > 0) {
            final p = (received / total).clamp(0.0, 1.0);
            setState(() {
              _progress = p;
              _status = 'Downloading ${(p * 100).toStringAsFixed(0)}%';
            });
          } else {
            setState(() {
              _status =
                  'Downloading ${(received / 1024 / 1024).toStringAsFixed(1)} MB';
            });
          }
        },
      );

      if (filePath == null) {
        throw Exception('Download failed: no file path returned');
      }

      // 2. Hand the local file to the installer.
      setState(() {
        _status = 'Installing...';
        _progress = 1.0;
      });

      await _updater.installApk(filePath);

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _status = 'Failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Downloading update'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _progress == 0 ? null : _progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Text(_status, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          Text(
            'After the download finishes, Android will ask you to allow '
            'installation. Tap "Allow" to install the update.',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.55),
              height: 1.4,
            ),
          ),
        ],
      ),
      actions: [
        if (_failed)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
      ],
    );
  }
}