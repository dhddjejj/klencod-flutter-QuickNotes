import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'list_page.dart';
import 'lock_gate.dart';
import 'sheets.dart';
import 'store.dart';
import 'widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _q = TextEditingController();
  bool _bubble = false;

  @override
  void initState() {
    super.initState();
    _syncBubble();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _syncBubble() async {
    try {
      final a = await FlutterOverlayWindow.isActive();
      if (mounted) setState(() => _bubble = a);
    } catch (_) {}
  }

  /// تشغيل/إيقاف الفقاعة العائمة
  Future<void> _toggleBubble() async {
    try {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
        if (mounted) setState(() => _bubble = false);
        return;
      }
      var ok = await FlutterOverlayWindow.isPermissionGranted();
      if (!ok) ok = await FlutterOverlayWindow.requestPermission() ?? false;
      if (!ok) {
        if (mounted) showToast(context, 'فعّل "العرض فوق التطبيقات" ثم اضغط مرة أخرى', icon: Icons.error_rounded);
        return;
      }
      await FlutterOverlayWindow.showOverlay(
        height: 120,
        width: 120,
        alignment: OverlayAlignment.centerRight,
        enableDrag: true,
        flag: OverlayFlag.focusPointer, // يسمح بالكتابة في البحث
        positionGravity: PositionGravity.auto,
        overlayTitle: 'QuickNotes',
        overlayContent: 'الفقاعة تعمل',
        notificationVisibility: NotificationVisibility.visibilitySecret,
      );
      if (mounted) {
        setState(() => _bubble = true);
        showToast(context, 'الفقاعة تعمل — افتح أي تطبيق', icon: Icons.bolt_rounded);
      }
    } catch (_) {
      if (mounted) showToast(context, 'تعذّر تشغيل الفقاعة', icon: Icons.error_rounded);
    }
  }

  /// تفعيل/إيقاف القفل بالبصمة
  Future<void> _toggleLock() async {
    if (!await Auth.supported()) {
      if (mounted) showToast(context, 'فعّل قفل الشاشة أو البصمة في جهازك أولاً', icon: Icons.error_rounded);
      return;
    }
    if (!await Auth.verify()) return;
    store.lockEnabled = !store.lockEnabled;
    await store.save();
    if (mounted) {
      showToast(context, store.lockEnabled ? 'تم تفعيل القفل' : 'تم إيقاف القفل', icon: Icons.lock_rounded);
    }
  }

  void _newList() =>
      showListSheet(context, onSave: (n, c, i) => store.addList(n, c, i));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _newList,
          icon: const Icon(Icons.add_rounded),
          label: const Text('قائمة جديدة'),
        ),
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Row(children: [
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('QuickNotes', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                    Text('كل ما تحتاجه بنقرة واحدة', style: TextStyle(color: Colors.white60)),
                  ]),
                ),
                IconButton(
                  tooltip: 'الفقاعة العائمة',
                  onPressed: _toggleBubble,
                  icon: Icon(_bubble ? Icons.bolt_rounded : Icons.bolt_outlined,
                      color: _bubble ? const Color(0xFFFFB020) : Colors.white70, size: 28),
                ),
                IconButton(
                  tooltip: 'القفل',
                  onPressed: _toggleLock,
                  icon: Icon(store.lockEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                      color: store.lockEnabled ? const Color(0xFF00E0B8) : Colors.white70),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _q,
                onChanged: (_) => setState(() {}),
                decoration: glassInput('ابحث في كل القوائم...', Icons.search_rounded).copyWith(
                  suffixIcon: _q.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(_q.clear),
                        ),
                ),
              ),
            ),
            Expanded(child: _body()),
          ]),
        ),
      ),
    );
  }

  Widget _body() {
    final q = _q.text.trim().toLowerCase();

    // ---- نتائج البحث ----
    if (q.isNotEmpty) {
      final res = <MapEntry<NoteList, NoteItem>>[];
      for (final l in store.lists) {
        for (final it in l.items) {
          if (l.name.toLowerCase().contains(q) ||
              it.title.toLowerCase().contains(q) ||
              (it.type != ItemType.password && it.value.toLowerCase().contains(q))) {
            res.add(MapEntry(l, it));
          }
        }
      }
      if (res.isEmpty) return const EmptyState(icon: Icons.search_off_rounded, text: 'لا توجد نتائج');
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: res.length,
        itemBuilder: (c, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: StaggerIn(
            index: i,
            child: ItemTile(
              item: res[i].value,
              accent: listColor(res[i].key.color),
              subtitle: res[i].key.name,
            ),
          ),
        ),
      );
    }

    if (store.lists.isEmpty) {
      return const EmptyState(icon: Icons.folder_open_rounded, text: 'لا توجد قوائم بعد\nاضغط "قائمة جديدة"');
    }

    // ---- القوائم ----
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      buildDefaultDragHandles: false,
      proxyDecorator: liftDecorator,
      itemCount: store.lists.length,
      onReorder: (o, n) {
        if (n > o) n--;
        store.reorderLists(o, n);
      },
      itemBuilder: (c, i) => _listTile(store.lists[i], i),
    );
  }

  Widget _listTile(NoteList l, int i) {
    final col = listColor(l.color);
    return Padding(
      key: ValueKey(l.id),
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey('d${l.id}'),
        direction: DismissDirection.horizontal,
        confirmDismiss: (_) => confirm(context, 'حذف القائمة "${l.name}" وكل عناصرها؟'),
        onDismissed: (_) => store.deleteList(l.id),
        background: dismissBg(Alignment.centerRight),
        secondaryBackground: dismissBg(Alignment.centerLeft),
        child: StaggerIn(
          index: i,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [col.withOpacity(.35), col.withOpacity(.08)],
              ),
              border: Border.all(color: col.withOpacity(.45)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: () => Navigator.push(context, fadeRoute(ListPage(listId: l.id))),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: col.withOpacity(.3), borderRadius: BorderRadius.circular(16)),
                      child: Icon(listIcon(l.icon), color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        Text('${l.items.length} عنصر',
                            style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      ]),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      color: const Color(0xFF1B1B3A),
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
                      onSelected: (v) async {
                        if (v == 'edit') {
                          showListSheet(context,
                              list: l, onSave: (n, c, ic) => store.editList(l.id, n, c, ic));
                        } else if (await confirm(context, 'حذف القائمة "${l.name}" وكل عناصرها؟')) {
                          store.deleteList(l.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('تعديل')),
                        PopupMenuItem(value: 'del', child: Text('حذف')),
                      ],
                    ),
                    ReorderableDragStartListener(
                      index: i,
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.drag_indicator_rounded, color: Colors.white38),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}