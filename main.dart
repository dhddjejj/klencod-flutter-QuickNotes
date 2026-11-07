import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_page.dart';
import 'lock_gate.dart';
import 'overlay_page.dart';
import 'store.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.load();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  runApp(const QuickNotesApp());
}

/// نقطة دخول الفقاعة العائمة (يستدعيها flutter_overlay_window)
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayApp());
}

class QuickNotesApp extends StatelessWidget {
  const QuickNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuickNotes',
      theme: buildTheme(),
      // واجهة عربية RTL + خلفية متحركة + بوابة القفل فوق كل الصفحات
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(children: [
          const Positioned.fill(child: AnimatedBackground()),
          Positioned.fill(child: LockGate(child: child!)),
        ]),
      ),
      home: const HomePage(),
    );
  }
}