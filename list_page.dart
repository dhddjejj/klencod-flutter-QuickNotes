import 'package:flutter/material.dart';
import 'sheets.dart';
import 'store.dart';
import 'widgets.dart';

/// صفحة عناصر قائمة واحدة
class ListPage extends StatelessWidget {
  final String listId;
  const ListPage({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final l = store.byId(listId);
        if (l == null) return const SizedBox();
        final col = listColor(l.color);

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Row(children: [
              Icon(listIcon(l.icon), color: col),
              const SizedBox(width: 10),
              Flexible(
                child: Text(l.name,
                    overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: col,
            foregroundColor: Colors.white,
            onPressed: () =>
                showItemSheet(context, onSave: (t, v, ty) => store.addItem(l.id, t, v, ty)),
            icon: const Icon(Icons.add_rounded),
            label: const Text('عنصر جديد'),
          ),
          body: l.items.isEmpty
              ? const EmptyState(icon: Icons.inbox_rounded, text: 'القائمة فارغة\nأضف أول عنصر')
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  buildDefaultDragHandles: false,
                  proxyDecorator: liftDecorator,
                  itemCount: l.items.length,
                  onReorder: (o, n) {
                    if (n > o) n--;
                    store.reorderItems(l.id, o, n);
                  },
                  itemBuilder: (c, i) {
                    final it = l.items[i];
                    return Padding(
                      key: ValueKey(it.id),
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: ValueKey('d${it.id}'),
                        direction: DismissDirection.horizontal,
                        background: dismissBg(Alignment.centerRight, radius: 22),
                        secondaryBackground: dismissBg(Alignment.centerLeft, radius: 22),
                        onDismissed: (_) => store.deleteItem(l.id, it.id),
                        child: StaggerIn(
                          index: i,
                          child: ItemTile(
                            item: it,
                            accent: col,
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                color: const Color(0xFF1B1B3A),
                                icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
                                onSelected: (v) async {
                                  if (v == 'edit') {
                                    showItemSheet(context,
                                        item: it,
                                        onSave: (t, val, ty) => store.editItem(l.id, it.id, t, val, ty));
                                  } else if (await confirm(context, 'حذف "${it.title}"؟')) {
                                    store.deleteItem(l.id, it.id);
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
                    );
                  },
                ),
        );
      },
    );
  }
}