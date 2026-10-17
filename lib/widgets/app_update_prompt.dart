import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';

import '../services/app_update_service.dart';

class AppUpdatePrompt extends StatefulWidget {
  const AppUpdatePrompt({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdatePrompt> createState() => _AppUpdatePromptState();
}

class _AppUpdatePromptState extends State<AppUpdatePrompt> {
  final _updates = AppUpdateService();
  StreamSubscription<OtaEvent>? _subscription;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final update = await _updates.checkForUpdate();
    if (!mounted || _showing) return;
    if (update == null) {
      // Once an update is installed, the old temporary APK can be removed.
      await _updates.cleanupDownloadedApks();
      return;
    }

    _showing = true;
    var downloading = false;
    var progress = 0.0;
    var status = 'Ready to download';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Version ${update.versionTag} is ready to install.'),
              const SizedBox(height: 10),
              Text(update.notes, maxLines: 5, overflow: TextOverflow.ellipsis),
              if (downloading) ...[
                const SizedBox(height: 18),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                Text(status),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: downloading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: downloading
                  ? null
                  : () async {
                      final permitted = await _updates.canRequestPackageInstalls();
                      if (!permitted) {
                        await _updates.openInstallUnknownAppsSettings();
                        if (!mounted) return;
                        setDialogState(() {
                          status = 'Allow installs from this app, then tap Update now again.';
                        });
                        return;
                      }

                      await _updates.cleanupDownloadedApks();
                      setDialogState(() {
                        downloading = true;
                        status = 'Starting download...';
                      });
                      await _subscription?.cancel();
                      _subscription = _updates.downloadAndInstall(update).listen(
                        (event) {
                          if (!mounted) return;
                          final raw = (event.value ?? '').trim();
                          final number = double.tryParse(raw);
                          setDialogState(() {
                            if (number != null) {
                              progress = (number / 100).clamp(0, 1).toDouble();
                            }
                            status = event.status.name.toUpperCase() == 'INSTALLING'
                                ? 'Opening installer...'
                                : number != null
                                    ? 'Downloading ${(progress * 100).round()}%'
                                    : (raw.isEmpty ? 'Downloading...' : raw);
                          });
                        },
                        onError: (_) {
                          if (!mounted) return;
                          setDialogState(() {
                            downloading = false;
                            status = 'Download failed. Please try again.';
                          });
                        },
                      );
                    },
              child: const Text('Update now'),
            ),
          ],
        ),
      ),
    );
    _showing = false;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
