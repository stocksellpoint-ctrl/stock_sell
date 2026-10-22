import 'package:app_installer_plus/app_installer_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_info.dart';


import '../../../../core/services/update_service.dart';

/// Confirms with the user whether to update now.
class UpdateAvailableDialog extends StatelessWidget {
  final UpdateInfo update;

  const UpdateAvailableDialog({super.key, required this.update});

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
            'Version ${update.version} is available.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (update.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: SingleChildScrollView(
                child: Text(
                  update.releaseNotes,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurface.withOpacity(0.65),
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Later'),
        ),
        TextButton(
          onPressed: () async {
            if (update.htmlUrl.isNotEmpty) {
              final uri = Uri.parse(update.htmlUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
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
class UpdateDownloadDialog extends StatefulWidget {
  final UpdateInfo update;

  const UpdateDownloadDialog({super.key, required this.update});

  @override
  State<UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}

class _UpdateDownloadDialogState extends State<UpdateDownloadDialog> {
  double _progress = 0;
  String _status = 'Preparing…';
  bool _started = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;

    try {
      await AppInstallerPlus().downloadAndInstallApk(
        downloadFileUrl: widget.update.apkUrl,
        onProgress: (progress) {
          if (!mounted) return;
          final p = progress.clamp(0.0, 1.0);
          setState(() {
            _progress = p;
            _status = 'Downloading ${(p * 100).toStringAsFixed(0)}%';
          });
        },
      );
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
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.55),
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