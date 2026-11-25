import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models.dart';
import '../store.dart';
import '../util.dart';
import '../widgets.dart';
import 'expenses.dart';
import 'spend_reports.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String period = 'month';
  bool onlyDel = false;

  static const periods = {
    'month': 'الشهر ده',
    'last': 'الشهر اللي فات',
    'q3': 'آخر ٣ شهور',
    'year': 'السنة دي',
    'all': 'الكل',
  };

  Future<void> _export(Rep r) async {
    String q(Object? v) {
      final s = '$v'.replaceAll('"', '""');
      return '"$s"';
    }

    final rows = <List<Object?>>[
      [
        'التاريخ', 'العميل', 'الموبايل', 'المناسبة', 'الحالة', 'السعر',
        'المدفوع', 'المتبقي', 'تكلفة الخامات', 'تكاليف تانية', 'الربح'
      ],
    ];
    final sorted = [...r.orders]..sort((a, b) => a.date.compareTo(b.date));
    for (final o in sorted) {
      rows.add([
        o.date, o.name, o.phone, o.occasion, statusLabel[o.status] ?? '',
        o.price.round(), o.paid.round(), (o.balance > 0 ? o.balance : 0).round(),
        o.ingCost.round(), o.extraCost.round(), o.profit.round(),
      ]);
    }
    rows.add([]);
    rows.add(['المبيعات', r.sales.round()]);
    rows.add(['تكلفة الطلبات', r.direct.round()]);
    rows.add(['مصروفات عامة', r.general.round()]);
    rows.add(['صافي الربح', r.net.round()]);
    final csv = '﻿${rows.map((x) => x.map(q).join(',')).join('\r\n')}';
    try {
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/report-${today()}.csv');
      await f.writeAsString(csv);
      await Share.shareXFiles([XFile(f.path)], text: 'تقرير المبيعات');
    } catch (_) {
      if (mounted) snack(context, 'مقدرتش أجهّز الملف');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
        actions: [
          IconButton(
            tooltip: 'تقارير المشتريات والمصروفات',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SpendReportsPage())),
          ),
          IconButton(
            tooltip: 'المصروفات',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ExpensesPage())),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final rng = periodRange(period);
          final r = store.report(rng[0], rng[1], onlyDel);
          final series = store.monthSeries(6, onlyDel);
          var maxV = 0.0;
          for (final s in series) {
            if (s.sales > maxV) maxV = s.sales;
          }

          // حسب المناسبة
          final occ = <String, List<double>>{};
          for (final o in r.orders) {
            final k = o.occasion.isEmpty ? 'أخرى' : o.occasion;
            final b = occ.putIfAbsent(k, () => [0, 0, 0]);
            b[0] += o.price;
            b[1] += o.profit;
            b[2] += 1;
          }
          final occKeys = occ.keys.toList()
            ..sort((a, b) => occ[b]![0].compareTo(occ[a]![0]));
          final occMax = occKeys.isEmpty ? 1.0 : occ[occKeys.first]![0];

          // أحسن العملاء
          final cm = <String, List<Object>>{};
          for (final o in r.orders) {
            final k = o.customerId.isEmpty ? o.name : o.customerId;
            final b = cm.putIfAbsent(k, () => [o.name, 0.0, 0]);
            b[1] = (b[1] as double) + o.price;
            b[2] = (b[2] as int) + 1;
          }
          final top = cm.values.toList()
            ..sort((a, b) => (b[1] as double).compareTo(a[1] as double));

          final sorted = [...r.orders]..sort((a, b) => b.date.compareTo(a.date));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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
                    label: const Text('كل الطلبات (غير الملغية)'),
                    selected: !onlyDel,
                    onSelected: (_) => setState(() => onlyDel = false),
                  ),
                  ChoiceChip(
                    label: const Text('المتسلّمة بس'),
                    selected: onlyDel,
                    onSelected: (_) => setState(() => onlyDel = true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (store.orders.isEmpty && store.expenses.isEmpty)
                const EmptyState(
                  title: 'مفيش بيانات للتقرير',
                  text: 'أول ما تسجّل طلبات ومصروفات هتلاقي هنا المبيعات والربح الصافي.',
                )
              else ...[
                HeroCard(
                  label: 'صافي الربح${r.net < 0 ? ' (خسارة)' : ''}',
                  value: money(r.net),
                  trio: [
                    MapEntry('المبيعات', money(r.sales)),
                    MapEntry('هامش الربح', '${r.margin.round()}٪'),
                    MapEntry('عدد الطلبات', '${r.count}'),
                  ],
                ),
                const SizedBox(height: 14),
                StatGrid([
                  StatTile('اتحصّل فعلاً', money(r.paid)),
                  StatTile('لسه عند العملاء', money(r.due),
                      color: r.due > 0 ? badC(context) : null),
                  StatTile('تكلفة الطلبات', money(r.direct)),
                  StatTile('مجمل الربح', money(r.gross),
                      color: r.gross >= 0 ? goodC(context) : badC(context)),
                  StatTile('مصروفات عامة', money(r.general)),
                  StatTile('متوسط الطلب', money(r.avg)),
                ]),
                Text(
                  'صافي الربح = المبيعات − تكلفة الطلبات (خامات وتغليف وتوصيل) − المصروفات العامة. الطلبات بتتحسب على تاريخ التسليم.',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
                const SectionTitle('آخر ٦ شهور'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _legend(cs.primary, 'المبيعات'),
                          const SizedBox(width: 16),
                          _legend(cs.tertiary, 'صافي الربح'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (final s in series) ...[
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                              '${monthName(s.key)} · ${fmtInt(s.sales)} / ${s.net < 0 ? '−' : ''}${fmtInt(s.net.abs())}',
                              style: const TextStyle(fontSize: 13)),
                        ),
                        const SizedBox(height: 4),
                        _bar(context, s.sales, maxV, cs.primary),
                        const SizedBox(height: 3),
                        _bar(context, s.net, maxV, cs.tertiary),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('الشهر')),
                      DataColumn(label: Text('المبيعات')),
                      DataColumn(label: Text('تكلفة الطلبات')),
                      DataColumn(label: Text('مصروفات')),
                      DataColumn(label: Text('صافي الربح')),
                    ],
                    rows: [
                      for (final s in series.reversed)
                        DataRow(cells: [
                          DataCell(Text(fmtMonth(s.key))),
                          DataCell(Text(fmtInt(s.sales))),
                          DataCell(Text(fmtInt(s.direct))),
                          DataCell(Text(fmtInt(s.general))),
                          DataCell(Text(
                            '${s.net < 0 ? '−' : ''}${fmtInt(s.net.abs())}',
                            style: TextStyle(
                                color: s.net < 0
                                    ? badC(context)
                                    : goodC(context)),
                          )),
                        ]),
                    ],
                  ),
                ),
                if (occKeys.isNotEmpty) ...[
                  const SectionTitle('حسب المناسبة'),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        for (final k in occKeys) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$k (${occ[k]![2].round()})'),
                              Text(money(occ[k]![0]),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _bar(context, occ[k]![0], occMax, cs.primary),
                          const SizedBox(height: 2),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text('ربح الطلبات: ${money(occ[k]![1])}',
                                style: TextStyle(
                                    fontSize: 12.5, color: cs.onSurfaceVariant)),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ],
                if (top.isNotEmpty) ...[
                  const SectionTitle('أحسن العملاء'),
                  for (final c in top.take(5))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text('${c[0]}'),
                      subtitle: Text('${c[2]} طلب'),
                      trailing: Text(money(c[1] as double),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                ],
                SectionTitle('تفاصيل الطلبات', trailing: '${sorted.length}'),
                if (sorted.isEmpty)
                  const Text('مفيش طلبات في الفترة دي.')
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('التاريخ')),
                        DataColumn(label: Text('العميل')),
                        DataColumn(label: Text('المناسبة')),
                        DataColumn(label: Text('السعر')),
                        DataColumn(label: Text('التكلفة')),
                        DataColumn(label: Text('الربح')),
                        DataColumn(label: Text('باقي')),
                      ],
                      rows: [
                        for (final o in sorted)
                          DataRow(cells: [
                            DataCell(Text(fmtDay(o.date))),
                            DataCell(Text(o.name)),
                            DataCell(Text(o.occasion)),
                            DataCell(Text(fmtInt(o.price))),
                            DataCell(Text(fmtInt(o.cost))),
                            DataCell(Text(
                              '${o.profit < 0 ? '−' : ''}${fmtInt(o.profit.abs())}',
                              style: TextStyle(
                                  color: o.profit < 0
                                      ? badC(context)
                                      : goodC(context)),
                            )),
                            DataCell(Text(o.balance > 0 ? fmtInt(o.balance) : '—')),
                          ]),
                      ],
                    ),
                  ),
                if (sorted.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => _export(r),
                    icon: const Icon(Icons.ios_share),
                    label: const Text('مشاركة التقرير (CSV يفتح في Excel)'),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _legend(Color c, String t) => Row(
        children: [
          Container(
              width: 12,
              height: 12,
              decoration:
                  BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text(t, style: const TextStyle(fontSize: 13)),
        ],
      );

  Widget _bar(BuildContext context, double v, double max, Color color) {
    final f = (max > 0 && v > 0) ? (v / max).clamp(0.02, 1.0) : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 8,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: f,
          child: Container(color: color),
        ),
      ),
    );
  }
}
