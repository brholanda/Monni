import 'package:flutter/material.dart';

import '../data/app_lock_settings.dart';
import '../screens/app_lock_screen.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _locked = AppLockSettings.instance.isLockEnabled;
  bool _backgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _backgrounded = true;
      return;
    }
    if (state == AppLifecycleState.resumed &&
        _backgrounded &&
        AppLockSettings.instance.isLockEnabled) {
      _backgrounded = false;
      setState(() => _locked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLockSettings.instance,
      builder: (context, _) {
        if (!AppLockSettings.instance.isLockEnabled || !_locked) {
          return widget.child;
        }
        return AppLockScreen(onUnlocked: () => setState(() => _locked = false));
      },
    );
  }
}
