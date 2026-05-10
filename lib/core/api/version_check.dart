import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets.dart';
import 'api_client.dart';

class VersionCheckService {
  const VersionCheckService(this.apiClient);

  final ApiClient apiClient;

  Future<void> checkVersion(BuildContext context) async {
    try {
      final response = await apiClient.dio.get('/version');
      final data = response.data;
      if (data is Map && data['minimum_version'] is String) {
        final minVersionStr = data['minimum_version'] as String;
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersionStr = packageInfo.version;

        if (_isOutdated(currentVersionStr, minVersionStr)) {
          if (context.mounted) {
            _showUpdateDialog(context);
          }
        }
      }
    } catch (e) {
      debugPrint('Version check failed: $e');
    }
  }

  bool _isOutdated(String current, String minimum) {
    final curParts = current.split('.');
    final minParts = minimum.split('.');
    
    for (int i = 0; i < 3; i++) {
      final cur = i < curParts.length ? int.tryParse(curParts[i]) ?? 0 : 0;
      final min = i < minParts.length ? int.tryParse(minParts[i]) ?? 0 : 0;
      if (cur < min) return true;
      if (cur > min) return false;
    }
    return false; // Equal
  }

  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false, // Prevent dismissing
          child: AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: const Text('Update Required'),
            content: const Text(
              'A new version of Nutrimate is available. Please update the app to continue using it.',
            ),
            actions: [
              NVPrimaryButton(
                label: 'Update Now',
                onPressed: () {
                  // In a real app, you'd direct to the specific store URL.
                  final url = Platform.isIOS 
                      ? 'https://apps.apple.com/app/idYOUR_APP_ID'
                      : 'https://play.google.com/store/apps/details?id=com.momodeveluk.nutrimate';
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
