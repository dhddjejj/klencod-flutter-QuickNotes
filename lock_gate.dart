import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'store.dart';
import 'widgets.dart';

/// مساعد البصمة / قفل الجهاز
class Auth {
  static bool busy = false;
  static final _a = LocalAuthentication();

  static Future<bool> supported() async {
    try {
      return await _a.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> verify() async {
    busy = true;
    try {
      return await _a.authenticate(
        localizedReason: 'تأكيد هويتك لفتح QuickNotes',
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (_) {
      return false;
    } finally {
      // نتجاهل أحداث دورة الحياة الناتجة عن نافذة البصمة نفسها
      Future.delayed(const Duration(milliseconds: 800), () => busy = false);
    }
  }
}

/// يغطي التطبيق بشاشة قفل عند الخروج والعودة (إذا كان القفل مفعلاً)
class LockGate extends StatefulWidget {
  final Widget child;
  const LockGate({super.key, required this.child});
  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locked = store.lockEnabled;
    if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (Auth.busy) return;
    if (s == AppLifecycleState.paused && store.lockEnabled) {
      setState(() => _locked = true);
    } else if (s == AppLifecycleState.resumed && _locked) {
      _unlock();
    }
  }

  Future<void> _unlock() async {
    if (Auth.busy) return;
    if (!await Auth.supported()) {
      if (mounted) setState(() => _locked = false); // لا نحبس المستخدم خارج التطبيق
      return;
    }
    final ok = await Auth.verify();
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.child,
      Positioned.fill(
        child: IgnorePointer(
          ignoring: !_locked,
          child: AnimatedOpacity(
            opacity: _locked ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: Material(
              color: const Color(0xFF0B0B1A),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.fingerprint_rounded, size: 90, color: Color(0xFF7C5CFF)),
                  const SizedBox(height: 16),
                  const Text('QuickNotes مقفل',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 220,
                    child: FilledButton(style: kBtn, onPressed: _unlock, child: const Text('فتح')),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
