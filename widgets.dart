import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'store.dart';

/// الثيم الداكن + خط Cairo
ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C5CFF), brightness: Brightness.dark),
    scaffoldBackgroundColor: Colors.transparent,
  );
  return base.copyWith(textTheme: GoogleFonts.cairoTextTheme(base.textTheme));
}

final kBtn = FilledButton.styleFrom(
  minimumSize: const Size.fromHeight(52),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
);

InputDecoration glassInput(String hint, [IconData? icon]) => InputDecoration(
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(.08),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

/// انتقال سلس بين الصفحات
Route<void> fadeRoute(Widget page) => PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .04), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: const Cubic(.2, .8, .2, 1))),
          child: child,
        ),
      ),
    );

/// خلفية متدرجة متحركة
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});
  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _blob(Color c, double size, Alignment a) => Align(
        alignment: a,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [c.withOpacity(.38), c.withOpacity(0)]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value * 2 * math.pi;
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B0B1A), Color(0xFF120E2E), Color(0xFF081A30)],
              ),
            ),
            child: Stack(fit: StackFit.expand, children: [
              _blob(const Color(0xFF7C5CFF), 420, Alignment(.9 * math.sin(t), -.6 + .3 * math.cos(t))),
              _blob(const Color(0xFF00C2FF), 380, Alignment(-.9 * math.cos(t), .5 * math.sin(t))),
              _blob(const Color(0xFFFF5C8A), 340, Alignment(.6 * math.cos(t + 2), .9 * math.sin(t + 1))),
            ]),
          );
        },
      ),
    );
  }
}

/// بطاقة زجاجية
class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final bool blur;
  final Color? tint;
  const GlassCard({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(16),
    this.blur = false,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final t = tint ?? Colors.white;
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.withOpacity(.16), t.withOpacity(.06)],
        ),
        border: Border.all(color: Colors.white.withOpacity(.16)),
      ),
      child: child,
    );
    if (!blur) return box;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: box),
    );
  }
}

/// ظهور متتابع (stagger)
class StaggerIn extends StatefulWidget {
  final int index;
  final Widget child;
  const StaggerIn({super.key, required this.index, required this.child});
  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 55 * math.min(widget.index, 8)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _c, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween(begin: const Offset(0, .15), end: Offset.zero)
            .animate(CurvedAnimation(parent: _c, curve: const Cubic(.2, .8, .2, 1))),
        child: widget.child,
      ),
    );
  }
}

/// حالة فارغة
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState({super.key, required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: .85, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        builder: (_, v, child) => Transform.scale(scale: v, child: Opacity(opacity: v.clamp(0, 1), child: child)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 72, color: Colors.white24),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 15)),
        ]),
      ),
    );
  }
}

/// خلفية السحب للحذف
Widget dismissBg(Alignment a, {double radius = 26}) => Container(
      alignment: a,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(.35), borderRadius: BorderRadius.circular(radius)),
      child: const Icon(Icons.delete_rounded, color: Colors.white),
    );

/// تأثير رفع العنصر أثناء السحب
Widget liftDecorator(Widget child, int index, Animation<double> anim) => AnimatedBuilder(
      animation: anim,
      builder: (_, c) {
        final t = Curves.easeOut.transform(anim.value);
        return Transform.scale(
          scale: 1 + .04 * t,
          child: Material(color: Colors.transparent, elevation: 12 * t, borderRadius: BorderRadius.circular(26), child: c),
        );
      },
      child: child,
    );

Future<bool> confirm(BuildContext context, String msg) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1B1B3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('تأكيد الحذف'),
      content: Text(msg),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('حذف'),
        ),
      ],
    ),
  );
  return r ?? false;
}

Future<T?> glassSheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GlassCard(
            blur: true,
            radius: 28,
            tint: const Color(0xFF2A2A5A),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );

/// إشعار Toast أنيق ينزلق من الأسفل
void showToast(BuildContext context, String msg, {IconData icon = Icons.check_circle_rounded}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry e;
  e = OverlayEntry(builder: (_) => _Toast(msg: msg, icon: icon, onDone: () => e.remove()));
  overlay.insert(e);
}

class _Toast extends StatefulWidget {
  final String msg;
  final IconData icon;
  final VoidCallback onDone;
  const _Toast({required this.msg, required this.icon, required this.onDone});
  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 350));

  @override
  void initState() {
    super.initState();
    _c.forward();
    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      await _c.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: const Cubic(.2, .8, .2, 1));
    return Positioned(
      bottom: 70,
      left: 24,
      right: 24,
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 1.2), end: Offset.zero).animate(curve),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xEE1B1B3A),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 8))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(widget.icon, color: const Color(0xFF00E0B8), size: 22),
                    const SizedBox(width: 10),
                    Flexible(child: Text(widget.msg, style: const TextStyle(fontWeight: FontWeight.w700))),
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

/// بطاقة عنصر: النقر ينسخ القيمة مع وميض وعلامة ✓
class ItemTile extends StatefulWidget {
  final NoteItem item;
  final Color accent;
  final String? subtitle;
  final Widget? trailing;
  final bool lockedPassword;
  final VoidCallback? onCopied;
  const ItemTile({
    super.key,
    required this.item,
    required this.accent,
    this.subtitle,
    this.trailing,
    this.lockedPassword = false,
    this.onCopied,
  });
  @override
  State<ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<ItemTile> {
  bool _copied = false;
  bool _show = false;

  bool get _locked => widget.lockedPassword && widget.item.type == ItemType.password;

  Future<void> _copy() async {
    if (_locked) {
      showToast(context, 'افتح التطبيق لنسخ كلمات السر', icon: Icons.lock_rounded);
      return;
    }
    await Clipboard.setData(ClipboardData(text: widget.item.value));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    showToast(context, 'تم نسخ ${widget.item.title}');
    widget.onCopied?.call();
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final a = widget.accent;
    final isPass = it.type == ItemType.password;
    final shown = _locked ? 'مقفلة' : (isPass && !_show ? '••••••••' : it.value);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: _copied ? a.withOpacity(.35) : Colors.white.withOpacity(.07),
        border: Border.all(color: _copied ? a : Colors.white.withOpacity(.14)),
        boxShadow: _copied ? [BoxShadow(color: a.withOpacity(.5), blurRadius: 24)] : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: _copy,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: a.withOpacity(.22), borderRadius: BorderRadius.circular(14)),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (c, an) => ScaleTransition(scale: an, child: c),
                  child: Icon(
                    _copied ? Icons.check_rounded : typeIcons[it.type],
                    key: ValueKey(_copied),
                    color: _copied ? const Color(0xFF00E0B8) : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(shown,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontFamily: 'monospace', color: Colors.white70, fontSize: 13)),
                  if (widget.subtitle != null)
                    Text(widget.subtitle!, style: TextStyle(color: a, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
              if (isPass && !_locked)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(_show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 20, color: Colors.white60),
                  onPressed: () => setState(() => _show = !_show),
                ),
              if (widget.trailing != null) widget.trailing!,
            ]),
          ),
        ),
      ),
    );
  }
}
