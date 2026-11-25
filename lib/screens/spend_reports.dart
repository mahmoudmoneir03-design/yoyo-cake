import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models.dart';
import '../store.dart';
import '../util.dart';
import '../widgets.dart';

class _Grp {
  final String label;
  double total = 0, qty = 0;
  int count = 0;
  String unit = '';
  _Grp(this.label);
}

/// تقارير المشتريات والمصروفات: إجمالي وتفصيلي.
class SpendReportsPage extends StatefulWidget {
  const SpendReportsPage({super.key});

  @override
  State<SpendReportsPage> createState() => _SpendReportsPageState();
}

class _SpendReportsPageState extends State<SpendReportsPage> {
  String period = 'month';
  bool detailed = false;

  static const periods = {
    'month': 'الشهر ده',
    'last': 'الشهر اللي فات',
    'q3': 'آخر ٣ شهور',
    'year': 'السنة دي',
    'all': 'الكل',
  };

  bool _in(String d, List<String> r) =>
      d.compareTo(r[0]) >= 0 && d.compareTo(r[1]) <= 0;

  String _pct(double v, double total) =>
      total > 0 ? '${(v / total * 100).round()}٪' : '';

  Future<void> _export(String name, List<List<Object?>> rows) async {
    String q(Object? v) {
      final s = '$v'.replaceAll('"', '""');
      return '"$s"';
    }

    final csv = '﻿${rows.map((x) => x.map(q).join(',')).join('\r\n')}';
    try {
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/$name-${today()}.csv');
      await f.writeAsString(csv);
      await Share.shareXFiles([XFile(f.path)], text: name);
    } catch (_) {
      if (mounted) snack(context, 'مقدرتش أجهّز الملف');
    }
  }

  Widget _filters() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final e in periods.entries)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: period == e.key,
                      onSelected: (_) => setState(() => period = e.key),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('إجمالي'),
                selected: !detailed,
                onSelected: (_) => setState(() => detailed = false),
              ),
              ChoiceChip(
                label: const Text('تفصيلي'),
                selected: detailed,
                onSelected: (_) => setState(() => detailed = true),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      );

  Widget _bar(BuildContext context, double v, double max) {
    final cs = Theme.of(context).colorScheme;
    final f = (max > 0 && v > 0) ? (v / max).clamp(0.02, 1.0) : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 8,
        color: cs.surfaceContainerHighest,
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: f,
          child: Container(color: cs.primary),
        ),
      ),
    );
  }

  /// قايمة المجموعات (حسب الخامة أو حسب البند) بشريط نسبة.
  Widget _groups(BuildContext context, List<_Grp> groups, double total,
      {required bool withQty}) {
    final cs = Theme.of(context).colorScheme;
    final max = groups.isEmpty ? 1.0 : groups.first.total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          for (final g in groups) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(g.label)),
                Text(money(g.total),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 4),
            _bar(context, g.total, max),
            const SizedBox(height: 2),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                [
                  '${g.count} عملية',
                  if (withQty && g.qty > 0)
                    g.unit.isEmpty ? fmtDec(g.qty) : fmtQty(g.qty, g.unit),
                  _pct(g.total, total),
                ].where((s) => s.isNotEmpty).join(' · '),
                style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _monthTable(Map<String, double> byMonth) {
    final keys = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('الشهر')),
          DataColumn(label: Text('الإجمالي')),
        ],
        rows: [
          for (final k in keys)
            DataRow(cells: [
              DataCell(Text(fmtMonth(k))),
              DataCell(Text(fmtInt(byMonth[k]!))),
            ]),
        ],
      ),
    );
  }

  // ---------------- المشتريات ----------------
  Widget _purchases(BuildContext context, List<String> rng) {
    final cs = Theme.of(context).colorScheme;
    final list = store.purchases.where((p) => _in(p.date, rng)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final total = list.fold<double>(0, (s, p) => s + p.price);
    final by = <String, _Grp>{};
    final byMonth = <String, double>{};
    for (final p in list) {
      final g = store.ingredientById(p.ingredientId);
      final grp = by.putIfAbsent(
          p.ingredientId, () => _Grp(g?.name ?? 'خامة محذوفة'));
      grp.total += p.price;
      grp.qty += p.qty;
      grp.count += 1;
      grp.unit = g?.unit ?? '';
      final m = p.date.length >= 7 ? p.date.substring(0, 7) : p.date;
      byMonth[m] = (byMonth[m] ?? 0) + p.price;
    }
    final groups = by.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    String nameOf(Purchase p) =>
        store.ingredientById(p.ingredientId)?.name ?? 'خامة محذوفة';
    String qtyOf(Purchase p) {
      final g = store.ingredientById(p.ingredientId);
      return g == null ? fmtDec(p.qty) : fmtQty(p.qty, g.unit);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _filters(),
        if (list.isEmpty)
          const EmptyState(
            title: 'مفيش مشتريات في الفترة دي',
            text: 'سجّل المشتريات من المكونات والمخزن ثم المخزن ثم زرار +.',
          )
        else ...[
          StatGrid([
            StatTile('إجمالي المشتريات', money(total)),
            StatTile('عدد العمليات', '${list.length}'),
            StatTile('عدد الخامات', '${groups.length}'),
            StatTile('متوسط العملية',
                money(list.isEmpty ? 0 : total / list.length)),
          ]),
          Text(
            'الكميات الافتتاحية اللي سجّلتها من غير سعر بتظهر في التفصيل وسعرها صفر.',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          if (!detailed) ...[
            const SectionTitle('حسب الخامة'),
            _groups(context, groups, total, withQty: true),
            const SectionTitle('حسب الشهر'),
            _monthTable(byMonth),
          ] else ...[
            SectionTitle('تفاصيل المشتريات', trailing: '${list.length}'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('التاريخ')),
                  DataColumn(label: Text('الخامة')),
                  DataColumn(label: Text('الكمية')),
                  DataColumn(label: Text('المبلغ')),
                  DataColumn(label: Text('سعر الوحدة')),
                  DataColumn(label: Text('ملاحظة')),
                ],
                rows: [
                  for (final p in list)
                    DataRow(cells: [
                      DataCell(Text(fmtDay(p.date))),
                      DataCell(Text(nameOf(p))),
                      DataCell(Text(qtyOf(p))),
                      DataCell(Text(p.price > 0 ? fmtInt(p.price) : 'افتتاحي')),
                      DataCell(Text((p.qty > 0 && p.price > 0)
                          ? fmtDec(p.price / p.qty)
                          : '—')),
                      DataCell(Text(p.note)),
                    ]),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              final rows = <List<Object?>>[
                ['التاريخ', 'الخامة', 'الكمية', 'الوحدة', 'المبلغ', 'سعر الوحدة', 'ملاحظة'],
                for (final p in list.reversed)
                  [
                    p.date,
                    nameOf(p),
                    fmtDec(p.qty),
                    store.ingredientById(p.ingredientId)?.unit ?? '',
                    p.price.round(),
                    (p.qty > 0 && p.price > 0) ? fmtDec(p.price / p.qty) : '',
                    p.note,
                  ],
                [],
                ['إجمالي المشتريات', total.round()],
                [],
                ['حسب الخامة', 'عدد العمليات', 'الكمية', 'الإجمالي'],
                for (final g in groups)
                  [g.label, g.count, fmtDec(g.qty), g.total.round()],
              ];
              _export('تقرير-المشتريات', rows);
            },
            icon: const Icon(Icons.ios_share),
            label: const Text('مشاركة تقرير المشتريات (CSV يفتح في Excel)'),
          ),
        ],
      ],
    );
  }

  // ---------------- المصروفات ----------------
  Widget _expenses(BuildContext context, List<String> rng) {
    final list = store.expenses.where((e) => _in(e.date, rng)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final total = list.fold<double>(0, (s, e) => s + e.amount);
    final by = <String, _Grp>{};
    final byMonth = <String, double>{};
    for (final e in list) {
      final k = e.cat.isEmpty ? 'أخرى' : e.cat;
      final grp = by.putIfAbsent(k, () => _Grp(k));
      grp.total += e.amount;
      grp.count += 1;
      final m = e.date.length >= 7 ? e.date.substring(0, 7) : e.date;
      byMonth[m] = (byMonth[m] ?? 0) + e.amount;
    }
    final groups = by.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _filters(),
        if (list.isEmpty)
          const EmptyState(
            title: 'مفيش مصروفات في الفترة دي',
            text: 'سجّل المصروفات من التقارير ثم أيقونة المحفظة.',
          )
        else ...[
          StatGrid([
            StatTile('إجمالي المصروفات', money(total)),
            StatTile('عدد المصروفات', '${list.length}'),
            StatTile('أكبر بند',
                groups.isEmpty ? '—' : groups.first.label),
            StatTile('متوسط المصروف', money(total / list.length)),
          ]),
          if (!detailed) ...[
            const SectionTitle('حسب البند'),
            _groups(context, groups, total, withQty: false),
            const SectionTitle('حسب الشهر'),
            _monthTable(byMonth),
          ] else ...[
            SectionTitle('تفاصيل المصروفات', trailing: '${list.length}'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('التاريخ')),
                  DataColumn(label: Text('البند')),
                  DataColumn(label: Text('المبلغ')),
                  DataColumn(label: Text('ملاحظة')),
                ],
                rows: [
                  for (final e in list)
                    DataRow(cells: [
                      DataCell(Text(fmtDay(e.date))),
                      DataCell(Text(e.cat)),
                      DataCell(Text(fmtInt(e.amount))),
                      DataCell(Text(e.note)),
                    ]),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              final rows = <List<Object?>>[
                ['التاريخ', 'البند', 'المبلغ', 'ملاحظة'],
                for (final e in list.reversed)
                  [e.date, e.cat, e.amount.round(), e.note],
                [],
                ['إجمالي المصروفات', total.round()],
                [],
                ['حسب البند', 'عدد المصروفات', 'الإجمالي'],
                for (final g in groups) [g.label, g.count, g.total.round()],
              ];
              _export('تقرير-المصروفات', rows);
            },
            icon: const Icon(Icons.ios_share),
            label: const Text('مشاركة تقرير المصروفات (CSV يفتح في Excel)'),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تقارير المشتريات والمصروفات'),
          bottom: const TabBar(
            tabs: [Tab(text: 'المشتريات'), Tab(text: 'المصروفات')],
          ),
        ),
        body: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final rng = periodRange(period);
            return TabBarView(
              children: [_purchases(context, rng), _expenses(context, rng)],
            );
          },
        ),
      ),
    );
  }
}
