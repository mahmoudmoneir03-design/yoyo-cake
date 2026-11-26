import 'package:flutter/material.dart';

import 'screens/lock.dart';
import 'security.dart';

/// بيغلّف التطبيق كله: تفعيل ← رقم سري ← قفل تلقائي.
class SecurityGate extends StatefulWidget {
  final Widget child;
  const SecurityGate({super.key, required this.child});

  @override
  State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate>
    with WidgetsBindingObserver {
  DateTime? _away;
  static const _after = Duration(seconds: 60);

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
    if (state == AppLifecycleState.paused) {
      _away = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final a = _away;
      _away = null;
      if (a != null && DateTime.now().difference(a) > _after) {
        security.lock();
      }
    }
  }

  // الشاشات دي برّه الـ Navigator فبنديها Overlay خاص بيها.
  Widget _screen(String k, Widget w) => Overlay(
        key: ValueKey(k),
        initialEntries: [OverlayEntry(builder: (_) => w)],
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: security,
      builder: (context, _) {
        if (!security.hasPin) {
          return _screen(
            'pin',
            PinSetupPage(
              title: 'اعمل رقم سري للتطبيق',
              onDone: (p) {
                security.setPin(p);
                security.locked = false;
              },
            ),
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (security.locked)
              Positioned.fill(child: _screen('lock', const LockPage())),
          ],
        );
      },
    );
  }
}
