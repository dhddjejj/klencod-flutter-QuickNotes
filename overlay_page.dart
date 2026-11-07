import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'store.dart';
import 'widgets.dart';

/// تطبيق الفقاعة (يعمل في نافذة منفصلة فوق التطبيقات الأخرى)
class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      theme: buildTheme(),
      builder: (c, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const OverlayRoot(),
    );
  }
}

class OverlayRoot extends StatefulWidget {
  const OverlayRoot({super.key});
  @override
  State<OverlayRoot> createState() => _OverlayRootState();
}

class _OverlayRootState extends State<OverlayRoot> {
  final _store = Store(); // نسخة خاصة بالفقاعة
  final _qc = TextEditingController();
  bool _open = false;
  String _q = '';
  String? _sel;

  @override
  void initState() {
    super.initState();
    _store.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _qc.dispose();
    super.dispose();
  }

  /// فتح اللوحة: نكبّر النافذة ثم نعرض المحتوى بأنميشن
  Future<void> _expand() async {
    await _store.load();
    await FlutterOverlayWindow.resizeOverlay(WindowSize.matchParent, WindowSize.matchParent, false);
    if (mounted) setState(() => _open = true);
  }

  /// إغلاق اللوحة: أنميشن الإخفاء ثم نصغّر النافذة لفقاعة
  Future<void> _collapse() async {
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _open = false;
      _q = '';
      _qc.clear();
    });
    await Future.delayed(const Duration(milliseconds: 260));
    await FlutterOverlayWindow.resizeOverlay(120, 120, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: ScaleTransition(scale: Tween(begin: .9, end: 1.0).animate(a), child: child),
        ),
        child: _open ? _panel(context) : _bubbleView(),
      ),
    );
  }

  Widget _bubbleView() {
    return LayoutBuilder(
      key: const ValueKey('bubble'),
      builder: (c, box) {
        final s = math.min(box.maxWidth, box.maxHeight) * .78;
        return Center(
          child: GestureDetector(
            onTap: _expand,
            child: Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFF7C5CFF), Color(0xFF00C2FF)]),
                boxShadow: [BoxShadow(color: const Color(0xFF7C5CFF).withOpacity(.6), blurRadius: 18)],
              ),
              child: Icon(Icons.bolt_rounded, color: Colors.white, size: s * .5),
            ),
          ),
        );
      },
    );
  }

  Widget _panel(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final lists = _store.lists;
    final sel = (_sel != null && _store.byId(_sel!) != null)
        ? _sel
        : (lists.isNotEmpty ? lists.first.id : null);

    final entries = <MapEntry<NoteList, NoteItem>>[];
    if (q.isNotEmpty) {
      for (final l in lists) {
        for (final it in l.items) {
          if (l.name.toLowerCase().contains(q) ||
              it.title.toLowerCase().contains(q) ||
              (it.type != ItemType.password && it.value.toLowerCase().contains(q))) {
            entries.add(MapEntry(l, it));
          }
        }
      }
    } else if (sel != null) {
      final l = _store.byId(sel)!;
      for (final it in l.items) {
        entries.add(MapEntry(l, it));
      }
    }

    return Stack(key: const ValueKey('panel'), children: [
      // خلفية معتمة: النقر عليها يغلق اللوحة
      Positioned.fill(
        child: GestureDetector(onTap: _collapse, child: Container(color: Colors.black54)),
      ),
      SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 520, maxHeight: MediaQuery.of(context).size.height * .72),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF14142E),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white24),
                  boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 40)],
                ),
                child: Column(children: [
                  Row(children: [
                    const Icon(Icons.bolt_rounded, color: Color(0xFFFFB020)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('QuickNotes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                    IconButton(onPressed: _collapse, icon: const Icon(Icons.close_rounded)),
                  ]),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _qc,
                    onChanged: (v) => setState(() => _q = v),
                    decoration: glassInput('ابحث...', Icons.search_rounded),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 42,
                    child: ListView(scrollDirection: Axis.horizontal, children: [
                      for (final l in lists)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                            avatar: Icon(listIcon(l.icon), size: 18, color: Colors.white),
                            label: Text(l.name),
                            selected: q.isEmpty && l.id == sel,
                            selectedColor: listColor(l.color).withOpacity(.45),
                            onSelected: (_) => setState(() {
                              _sel = l.id;
                              _q = '';
                              _qc.clear();
                            }),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: entries.isEmpty
                        ? const EmptyState(icon: Icons.inbox_rounded, text: 'لا توجد عناصر')
                        : ListView.builder(
                            itemCount: entries.length,
                            itemBuilder: (c, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: StaggerIn(
                                index: i,
                                child: ItemTile(
                                  item: entries[i].value,
                                  accent: listColor(entries[i].key.color),
                                  subtitle: q.isNotEmpty ? entries[i].key.name : null,
                                  lockedPassword: _store.lockEnabled,
                                  // بعد النسخ تُغلق اللوحة تلقائياً وترجع لمهمتك
                                  onCopied: () => Future.delayed(const Duration(milliseconds: 700), _collapse),
                                ),
                              ),
                            ),
                          ),
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
