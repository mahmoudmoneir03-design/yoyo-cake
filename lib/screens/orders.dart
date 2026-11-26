import 'package:flutter/material.dart';

import '../photos.dart';
import '../models.dart';
import '../store.dart';
import '../util.dart';
import '../widgets.dart';
import 'order_detail.dart';
import 'order_form.dart';

void openOrder(BuildContext context, String id) {
  Navigator.push(
      context, MaterialPageRoute(builder: (_) => OrderDetailPage(id: id)));
}

void openNewOrder(BuildContext context) {
  Navigator.push(
      context, MaterialPageRoute(builder: (_) => const OrderFormPage()));
}

Widget payPill(BuildContext c, Order o) {
  if (o.status == 'cancelled') return const Pill('ملغي');
  final bal = o.balance;
  if (bal <= 0) return Pill('اتدفع بالكامل', color: goodC(c));
  if (o.paid > 0) {
    return Pill('عربون ${fmtInt(o.paid)} · باقي ${fmtInt(bal)}', color: warnC(c));
  }
  return Pill('من غير عربون', color: badC(c));
}

class OrderTile extends StatelessWidget {
  final Order o;
  const OrderTile(this.o, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final d = parseDate(o.date);
    final late = o.isOpen && o.date.compareTo(today()) < 0;
    final sub = o.desc.isEmpty ? o.occasion : '${o.occasion} · ${o.desc}';
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openOrder(context, o.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Text('${d.day}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    Text(months[d.month - 1], style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              if (hasPhoto(o.photo)) ...[
                const SizedBox(width: 10),
                PhotoThumb(name: o.photo, size: 54),
              ],
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(sub,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (late) Pill('متأخر', color: badC(context)),
                        if (o.isOpen) Pill(statusLabel[o.status] ?? ''),
                        payPill(context, o),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(money(o.price),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(o.isOpen ? relDay(o.date) : (statusLabel[o.status] ?? ''),
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String filter = 'active';
  String q = '';

  static const filters = {
    'active': 'الجاية',
    'unpaid': 'فيها باقي',
    'delivered': 'اتسلّمت',
    'cancelled': 'ملغية',
    'all': 'الكل',
  };

  bool _match(Order o) {
    final okF = filter == 'all' ||
        (filter == 'active' && o.isOpen) ||
        (filter == 'delivered' && o.status == 'delivered') ||
        (filter == 'cancelled' && o.status == 'cancelled') ||
        (filter == 'unpaid' && o.status != 'cancelled' && o.balance > 0);
    if (!okF) return false;
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return true;
    final dq = digitsOf(s);
    return o.name.toLowerCase().contains(s) ||
        o.desc.toLowerCase().contains(s) ||
        (dq.isNotEmpty && digitsOf(o.phone).contains(dq));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الطلبات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openNewOrder(context),
        icon: const Icon(Icons.add),
        label: const Text('طلب جديد'),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final list = store.orders.where(_match).toList()
            ..sort((a, b) {
              final ka = '${a.date}${a.time}';
              final kb = '${b.date}${b.time}';
              return filter == 'active' ? ka.compareTo(kb) : kb.compareTo(ka);
            });
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              TextField(
                onChanged: (v) => setState(() => q = v),
                decoration: const InputDecoration(
                  hintText: 'دوّر باسم العميل أو رقمه',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final e in filters.entries)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          label: Text(e.value),
                          selected: filter == e.key,
                          onSelected: (_) => setState(() => filter = e.key),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (store.orders.isEmpty)
                EmptyState(
                  title: 'لسه مفيش طلبات',
                  text: 'اضغط "طلب جديد" وسجّل بيانات العميل والعربون.',
                  action: 'سجّل أول طلب',
                  onAction: () => openNewOrder(context),
                )
              else if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('مفيش طلبات بالشكل ده.')),
                )
              else
                for (final o in list) ...[
                  OrderTile(o),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }
}
