import 'package:flutter/material.dart';
import 'store.dart';
import 'widgets.dart';

/// نافذة إنشاء/تعديل قائمة
Future<void> showListSheet(BuildContext context,
    {NoteList? list, required void Function(String name, int color, int icon) onSave}) {
  return glassSheet(context, _ListForm(list: list, onSave: onSave));
}

class _ListForm extends StatefulWidget {
  final NoteList? list;
  final void Function(String, int, int) onSave;
  const _ListForm({this.list, required this.onSave});
  @override
  State<_ListForm> createState() => _ListFormState();
}

class _ListFormState extends State<_ListForm> {
  late final _name = TextEditingController(text: widget.list?.name ?? '');
  late int _color = widget.list?.color ?? 0;
  late int _icon = widget.list?.icon ?? 0;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final n = _name.text.trim();
    if (n.isEmpty) return;
    widget.onSave(n, _color, _icon);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.list == null ? 'قائمة جديدة' : 'تعديل القائمة',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 16),
      TextField(
        controller: _name,
        autofocus: true,
        decoration: glassInput('اسم القائمة (مثال: حسابات)', Icons.edit_rounded),
        onSubmitted: (_) => _save(),
      ),
      const SizedBox(height: 16),
      Wrap(spacing: 12, runSpacing: 12, children: [
        for (int i = 0; i < kColors.length; i++)
          GestureDetector(
            onTap: () => setState(() => _color = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: listColor(i),
                border: Border.all(color: _color == i ? Colors.white : Colors.transparent, width: 3),
              ),
              child: _color == i ? const Icon(Icons.check_rounded, size: 20, color: Colors.white) : null,
            ),
          ),
      ]),
      const SizedBox(height: 16),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (int i = 0; i < kIcons.length; i++)
          GestureDetector(
            onTap: () => setState(() => _icon = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _icon == i ? listColor(_color).withOpacity(.4) : Colors.white.withOpacity(.08),
                border: Border.all(color: _icon == i ? listColor(_color) : Colors.transparent, width: 2),
              ),
              child: Icon(kIcons[i], color: Colors.white),
            ),
          ),
      ]),
      const SizedBox(height: 20),
      FilledButton(style: kBtn, onPressed: _save, child: const Text('حفظ')),
    ]);
  }
}

/// نافذة إضافة/تعديل عنصر
Future<void> showItemSheet(BuildContext context,
    {NoteItem? item, required void Function(String title, String value, ItemType type) onSave}) {
  return glassSheet(context, _ItemForm(item: item, onSave: onSave));
}

class _ItemForm extends StatefulWidget {
  final NoteItem? item;
  final void Function(String, String, ItemType) onSave;
  const _ItemForm({this.item, required this.onSave});
  @override
  State<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<_ItemForm> {
  late final _t = TextEditingController(text: widget.item?.title ?? '');
  late final _v = TextEditingController(text: widget.item?.value ?? '');
  late ItemType _type = widget.item?.type ?? ItemType.text;

  @override
  void dispose() {
    _t.dispose();
    _v.dispose();
    super.dispose();
  }

  void _save() {
    final v = _v.text.trim();
    if (v.isEmpty) return;
    final t = _t.text.trim().isEmpty ? typeLabels[_type]! : _t.text.trim();
    widget.onSave(t, v, _type);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.item == null ? 'عنصر جديد' : 'تعديل العنصر',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 16),
      TextField(
        controller: _t,
        autofocus: widget.item == null,
        decoration: glassInput('العنوان (مثال: جيميل الشخصي)', Icons.title_rounded),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _v,
        textDirection: TextDirection.ltr,
        keyboardType: _type == ItemType.email
            ? TextInputType.emailAddress
            : _type == ItemType.link
                ? TextInputType.url
                : TextInputType.text,
        decoration: glassInput('القيمة', Icons.edit_note_rounded),
        onSubmitted: (_) => _save(),
      ),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in ItemType.values)
          ChoiceChip(
            avatar: Icon(typeIcons[t], size: 18),
            label: Text(typeLabels[t]!),
            selected: _type == t,
            onSelected: (_) => setState(() => _type = t),
          ),
      ]),
      const SizedBox(height: 20),
      FilledButton(style: kBtn, onPressed: _save, child: const Text('حفظ')),
    ]);
  }
}
