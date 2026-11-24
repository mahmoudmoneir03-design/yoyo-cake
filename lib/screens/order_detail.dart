import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../store.dart';
import '../util.dart';
import '../widgets.dart';
import 'order_form.dart';

class OrderDetailPage extends StatefulWidget {
  final String id;
  const OrderDetailPage({super.key, required this.id});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final pay = TextEditingController();

  @override
  void dispose() {
    pay.dispose();
    super.dispose();
  }

  void _addPayment(Order o, double a, String note) {
    if (a <= 0) return;
    o.payments.add(Payment(id: uid(), amount: a, date: today(), note: note));
    store.putOrder(o);
    snack(context, 'اتسجّلت الدفعة');
  }

  Future<void> _openWa(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) snack(context, 'مقدرتش أفتح واتساب');
    }
  }

  Widget _row(String k, Widget v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(k), v],
        ),
      );

  Widget _info(BuildContext context, String k, String v) {
    if (v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(k,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final o = store.orderById(widget.id);
        if (o == null) {
          return Scaffold(
              appBar: AppBar(), body: const Center(child: Text('الطلب اتمسح')));
        }
        final cs = Theme.of(context).colorScheme;
        final wa = waLink(o.phone);
        final when = '${o.occasion} · ${fmtDay(o.date)}${o.time.isEmpty ? '' : ' · ${o.time}'}';
        return Scaffold(
          appBar: AppBar(
            title: Text(o.name),
            actions: [
              IconButton(
                tooltip: 'تعديل',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => OrderFormPage(order: o))),
              ),
              IconButton(
                tooltip: 'مسح',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await confirmDialog(
                      context, 'تمسح الطلب ده نهائياً؟');
                  if (ok) {
                    store.deleteOrder(o.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(when, style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final e in statusLabel.entries)
                    ChoiceChip(
                      label: Text(e.value),
                      selected: o.status == e.key,
                      onSelected: (_) {
                        o.status = e.key;
                        store.putOrder(o);
                        if (e.key == 'delivered' && o.balance > 0) {
                          snack(context, 'اتسلّم. لسه باقي ${money(o.balance)}');
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _info(context, 'الوصف', o.desc),
              _info(context, 'الحجم', o.size),
              _info(context, 'النكهة', o.flavor),
              _info(context, 'العنوان', o.address),
              _info(context, 'ملاحظات', o.notes),
              if (o.phone.isNotEmpty)
                Row(
                  children: [
                    Expanded(child: Text(o.phone)),
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: o.phone));
                        snack(context, 'اتنسخ الرقم');
                      },
                      child: const Text('نسخ'),
                    ),
                    if (wa.isNotEmpty)
                      FilledButton.tonal(
                        onPressed: () => _openWa(wa),
                        child: const Text('واتساب'),
                      ),
                  ],
                ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Column(
                  children: [
                    _row('سعر التورتة', Text(money(o.price),
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                    _row('اتدفع', Text(money(o.paid),
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                    _row(
                      'المتبقي على العميل',
                      Text(
                        money(o.balance < 0 ? 0 : o.balance),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: o.balance > 0 ? badC(context) : goodC(context),
                        ),
                      ),
                    ),
                    const Divider(),
                    _row('تكلفة الخامات', Text(money(o.ingCost))),
                    _row('تغليف وتوصيل وغيره', Text(money(o.extraCost))),
                    _row('تكلفة الطلب', Text(money(o.cost))),
                    _row(
                      'ربح الطلب',
                      Text(
                        money(o.profit),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: o.profit < 0 ? badC(context) : goodC(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (o.lines.isNotEmpty) ...[
                const SectionTitle('مكونات التورتة'),
                for (final l in o.lines)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(l.name),
                    subtitle: Text('${fmtDec(l.qty)} ${l.unit}'),
                    trailing: Text(money(l.cost)),
                  ),
              ],
              const SectionTitle('الدفعات والعربون'),
              if (o.payments.isEmpty) const Text('لسه مفيش دفعات.'),
              for (final p in o.payments)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(money(p.amount),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      '${fmtDay(p.date)}${p.note.isEmpty ? '' : ' · ${p.note}'}'),
                  trailing: IconButton(
                    tooltip: 'مسح الدفعة',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      o.payments.remove(p);
                      store.putOrder(o);
                    },
                  ),
                ),
              if (o.status != 'cancelled') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: numField('مبلغ الدفعة', pay)),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () {
                        final a = parseNum(pay.text);
                        if (a <= 0) {
                          snack(context, 'اكتب مبلغ الدفعة');
                          return;
                        }
                        pay.clear();
                        _addPayment(o, a, '');
                      },
                      child: const Text('سجّل دفعة'),
                    ),
                  ],
                ),
                if (o.balance > 0)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () => _addPayment(o, o.balance, 'الباقي'),
                      child: Text('سدّد المتبقي (${fmtInt(o.balance)})'),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
