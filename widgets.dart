import 'package:flutter/material.dart';

import 'models.dart';
import 'store.dart';
import 'util.dart';

Color goodC(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? const Color(0xFF66D187)
    : const Color(0xFF1F7A3D);
Color badC(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? const Color(0xFFF4928A)
    : const Color(0xFFB3261E);
Color warnC(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? const Color(0xFFF0B34A)
    : const Color(0xFF8F5200);

void snack(BuildContext c, String m) {
  final s = ScaffoldMessenger.of(c);
  s.hideCurrentSnackBar();
  s.showSnackBar(SnackBar(content: Text(m)));
}

class Pill extends StatelessWidget {
  final String text;
  final Color? color;
  const Pill(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = color ?? cs.onSecondaryContainer;
    final bg = color == null ? cs.secondaryContainer : color!.withAlpha(36);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(text,
          style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class HeroCard extends StatelessWidget {
  final String label, value;
  final List<MapEntry<String, String>> trio;
  const HeroCard(
      {super.key, required this.label, required this.value, required this.trio});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final on = cs.onPrimary;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
          color: cs.primary, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: on.withAlpha(230), fontSize: 14)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(value,
                style: TextStyle(
                    color: on, fontSize: 40, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 8),
          Divider(color: on.withAlpha(70), height: 1),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in trio)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.key,
                          style: TextStyle(
                              color: on.withAlpha(220), fontSize: 12.5)),
                      Text(e.value,
                          style: TextStyle(
                              color: on,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label, value;
  final Color? color;
  const StatTile(this.label, this.value, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          ),
        ],
      ),
    );
  }
}

class StatGrid extends StatelessWidget {
  final List<Widget> tiles;
  const StatGrid(this.tiles, {super.key});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      rows.add(Row(
        children: [
          Expanded(child: tiles[i]),
          const SizedBox(width: 10),
          Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox()),
        ],
      ));
      rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  const SectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (trailing != null)
            Text(trailing!,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title, text;
  final String? action;
  final VoidCallback? onAction;
  const EmptyState(
      {super.key,
      required this.title,
      required this.text,
      this.action,
      this.onAction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cake_outlined, size: 56, color: cs.primary),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant)),
          if (action != null) ...[
            const SizedBox(height: 14),
            FilledButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    );
  }
}

Widget textField(
  String label,
  TextEditingController c, {
  TextInputType? type,
  int maxLines = 1,
  String? suffix,
  String? hint,
  ValueChanged<String>? onChanged,
}) =>
    TextField(
      controller: c,
      keyboardType: type,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
          labelText: label, suffixText: suffix, hintText: hint),
    );

Widget numField(String label, TextEditingController c,
        {String? suffix = 'ج.م', ValueChanged<String>? onChanged}) =>
    textField(label, c,
        type: const TextInputType.numberWithOptions(decimal: true),
        suffix: suffix,
        onChanged: onChanged);

class PickField extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final VoidCallback onTap;
  const PickField(
      {super.key,
      required this.label,
      required this.value,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration:
            InputDecoration(labelText: label, suffixIcon: Icon(icon, size: 20)),
        child: Text(value.isEmpty ? '—' : value),
      ),
    );
  }
}

class FormCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const FormCard(this.title, this.children, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ],
        ],
      ),
    );
  }
}

Future<T?> pickOne<T>(
  BuildContext context,
  String title,
  List<T> items,
  String Function(T) label, {
  String Function(T)? sub,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (c) => SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(c).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final i in items)
                    ListTile(
                      title: Text(label(i)),
                      subtitle: sub == null ? null : Text(sub(i)),
                      onTap: () => Navigator.pop(c, i),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<bool> confirmDialog(BuildContext context, String msg,
    {String yes = 'أيوه، امسح'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      content: Text(msg),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('لأ')),
        FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(yes)),
      ],
    ),
  );
  return r == true;
}

Future<double?> askNumber(BuildContext context, String title, double? initial) {
  final c = TextEditingController(text: initial == null ? '' : fmtDec(initial));
  return showDialog<double>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('إلغاء')),
        FilledButton(
            onPressed: () => Navigator.pop(d, parseNum(c.text)),
            child: const Text('تمام')),
      ],
    ),
  );
}

/// محرر مكونات التورتة: بيتستخدم في الطلب وفي الوصفة.
class LinesEditor extends StatelessWidget {
  final List<Line> lines;
  final VoidCallback onChanged;
  final Future<void> Function()? onAddRecipe;
  const LinesEditor(
      {super.key,
      required this.lines,
      required this.onChanged,
      this.onAddRecipe});

  Future<void> _add(BuildContext context) async {
    if (store.ingredients.isEmpty) {
      snack(context, 'ضيف الخامات الأول من تاب المكونات');
      return;
    }
    final ing = await pickOne<Ingredient>(
      context,
      'اختار الخامة',
      store.ingredients,
      (i) => i.name,
      sub: (i) => '${money(i.packPrice)} لكل ${fmtDec(i.packQty)} ${i.unit}',
    );
    if (ing == null || !context.mounted) return;
    final q = await askNumber(context, '${ing.name} (الكمية بال${ing.unit})', null);
    if (q == null || q <= 0) return;
    addLine(lines, ing, q);
    onChanged();
  }

  Future<void> _edit(BuildContext context, Line l) async {
    final q = await askNumber(context, '${l.name} (${l.unit})', l.qty);
    if (q == null || q <= 0) return;
    l.qty = q;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = lines.fold<double>(0, (s, l) => s + l.cost);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (lines.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              store.ingredients.isEmpty
                  ? 'لسه مضفتش خامات. ادخل تاب "المكونات" وسجّل الخامات بأسعار شرائها.'
                  : 'ضيف الخامات اللي دخلت في التورتة.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
        for (final l in lines)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(l.name),
            subtitle: Text('${fmtDec(l.qty)} ${l.unit} × ${fmtDec(l.unitCost)} ج.م'),
            onTap: () => _edit(context, l),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(money(l.cost),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                IconButton(
                  tooltip: 'شيل',
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    lines.remove(l);
                    onChanged();
                  },
                ),
              ],
            ),
          ),
        if (lines.isNotEmpty) ...[
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('تكلفة الخامات',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(money(total),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ],
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _add(context),
              icon: const Icon(Icons.add),
              label: const Text('إضافة خامة'),
            ),
            if (onAddRecipe != null)
              OutlinedButton.icon(
                onPressed: () => onAddRecipe!(),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('من وصفة جاهزة'),
              ),
          ],
        ),
      ],
    );
  }
}

/// بتضيف خامة بكمية للقائمة، ولو موجودة بتزوّد الكمية.
void addLine(List<Line> lines, Ingredient ing, double qty) {
  final i = lines.indexWhere((l) => l.ingredientId == ing.id);
  if (i >= 0) {
    lines[i].qty += qty;
    lines[i].unitCost = ing.unitCost;
  } else {
    lines.add(Line(
      ingredientId: ing.id,
      name: ing.name,
      unit: ing.unit,
      qty: qty,
      unitCost: ing.unitCost,
    ));
  }
}
