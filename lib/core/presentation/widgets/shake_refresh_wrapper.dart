import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
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
  StreamSubscription? _subscription;
  bool _isRefreshing = false;
  
  DateTime? _lastShakeTime;

  @override
  void initState() {
    super.initState();
    debugPrint('ShakeRefreshWrapper: Subscribing to accelerometerEvents...');
    _subscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        final double gX = event.x / 9.80665;
        final double gY = event.y / 9.80665;
        final double gZ = event.z / 9.80665;

        final double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);
        
        // Print logs when movement starts to show it's working
        if (gForce > 1.3) {
          debugPrint('ShakeRefreshWrapper: Force = ${gForce.toStringAsFixed(2)}g');
        }

        // 1.9g is a reliable shake threshold across all devices
        if (gForce > 1.9) {
          final now = DateTime.now();
          if (_lastShakeTime == null || now.difference(_lastShakeTime!) > const Duration(seconds: 2)) {
            _lastShakeTime = now;
            _handleShake();
          }
        }
      },
      onError: (error) {
        debugPrint('ShakeRefreshWrapper: Error listening to accelerometer: $error');
      },
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
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
