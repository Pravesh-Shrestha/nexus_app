import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shake/shake.dart';
import 'package:nexus_app/core/utils/firestore_cache_extension.dart';
import 'package:nexus_app/core/theme/app_colors.dart';

class ShakeRefreshWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const ShakeRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  State<ShakeRefreshWrapper> createState() => _ShakeRefreshWrapperState();
}

class _ShakeRefreshWrapperState extends State<ShakeRefreshWrapper> {
  ShakeDetector? _detector;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    debugPrint('ShakeRefreshWrapper: Initializing ShakeDetector...');
    _detector = ShakeDetector.autoStart(
      onPhoneShake: _handleShake,
      shakeThresholdGravity: 1.8, // Lowered from 2.7 for easier moderate shake triggering
      shakeSlopTimeMS: 500,
    );
  }

  @override
  void dispose() {
    _detector?.stopListening();
    super.dispose();
  }

  Future<void> _handleShake() async {
    if (_isRefreshing) return;

    debugPrint('ShakeRefreshWrapper: Shake Event Detected!');
    // Trigger haptic feedback vibration
    HapticFeedback.mediumImpact();

    setState(() {
      _isRefreshing = true;
    });

    // Toggle cache bypass flag
    forceServerFetch = true;

    try {
      // Trigger user's refresh callback
      await widget.onRefresh();
    } catch (e) {
      debugPrint('Shake Refresh Error: $e');
    }

    // Reset forceServerFetch flag
    forceServerFetch = false;

    // Show a quick visual success feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.sync, color: AppColors.primaryCyan, size: 20),
              SizedBox(width: 12),
              Text(
                'Data Refreshed!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: AppColors.surface,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isRefreshing)
          Container(
            color: Colors.black45,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
              ),
            ),
          ),
      ],
    );
  }
}
