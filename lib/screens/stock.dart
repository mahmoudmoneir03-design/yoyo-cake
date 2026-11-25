import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../util.dart';
import '../widgets.dart';

class StockTab extends StatelessWidget {
  const StockTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = [...store.ingredients]
          ..sort((a, b) => a.name.compareTo(b.name));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            StatGrid([
              StatTile('قيمة المخزن', money(store.totalStockValue)),
              StatTile('عدد الخامات', '${list.length}'),
            ]),
            Text(
              'المخزن = اللي اشتريته − اللي اتستخدم في الطلبات اللي بقت "قيد التحضير" أو بعدها. سجّل أي شراء بزرار +، وسجّل اللي عندك دلوقتي كأول كمية.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              const EmptyState(
                title: 'مفيش خامات لسه',
                text: 'سجّل الخامات الأول من تاب "الخامات" وبعدها ضيف كمياتها هنا.',
              ),
            for (final g in list) ...[
              _StockCard(g),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _StockCard extends StatelessWidget {
  final Ingredient g;
  const _StockCard(this.g);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final q = store.stockQty(g.id);
    final reserved = store.reservedQty(g.id);
    final bought = store.purchasedQty(g.id);
    final pills = <Widget>[];
    if (bought == 0) {
      pills.add(const Pill('لسه ما اشتريتش منه'));
    } else if (q < 0) {
      pills.add(Pill('ناقص ${fmtQty(-q, g.unit)}', color: badC(context)));
    } else if (g.minQty > 0 && q <= g.minQty) {
      pills.add(Pill('قرّب يخلص', color: warnC(context)));
    }
    if (reserved > 0) {
      pills.add(Pill('محجوز للطلبات الجاية ${fmtQty(reserved, g.unit)}'));
    }
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => StockDetailPage(id: g.id))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('فاضل: ${fmtQty(q < 0 ? 0 : q, g.unit)}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    if (pills.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 4, children: pills),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(money(store.stockValue(g)),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text('قيمته',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  IconButton.filledTonal(
                    tooltip: 'إضافة كمية',
                    icon: const Icon(Icons.add),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PurchaseFormPage(ing: g))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StockDetailPage extends StatelessWidget {
  final String id;
  const StockDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final g = store.ingredientById(id);
        if (g == null) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('الخامة اتمسحت')));
        }
        final q = store.stockQty(g.id);
        final ps = store.purchases.where((p) => p.ingredientId == g.id).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        return Scaffold(
          appBar: AppBar(title: Text(g.name)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              StatGrid([
                StatTile('فاضل', fmtQty(q < 0 ? 0 : q, g.unit),
                    color: q < 0 ? badC(context) : null),
                StatTile('قيمته', money(store.stockValue(g))),
                StatTile('متوسط سعر الشراء',
                    '${fmtDec(store.avgCost(g))} ج.م لكل ${g.unit}'),
                StatTile('محجوز للطلبات الجاية',
                    fmtQty(store.reservedQty(g.id), g.unit)),
                StatTile('اتشترى إجمالي', fmtQty(store.purchasedQty(g.id), g.unit)),
                StatTile('اتستخدم', fmtQty(store.usedQty(g.id), g.unit)),
              ]),
              if (q < 0)
                Text(
                  'الكمية ناقصة: الطلبات استخدمت أكتر من اللي سجّلته. سجّل مشترياتك عشان الرصيد يتظبط.',
                  style: TextStyle(color: badC(context)),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => PurchaseFormPage(ing: g))),
                icon: const Icon(Icons.add),
                label: const Text('إضافة كمية'),
              ),
              SectionTitle('المشتريات', trailing: '${ps.length}'),
              if (ps.isEmpty) const Text('لسه مفيش مشتريات.'),
              for (final p in ps)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('+ ${fmtQty(p.qty, g.unit)}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      '${fmtDay(p.date)}${p.note.isEmpty ? '' : ' · ${p.note}'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(money(p.price)),
                      IconButton(
                        tooltip: 'مسح',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final ok =
                              await confirmDialog(context, 'تمسح عملية الشراء دي؟');
                          if (ok) store.deletePurchase(p.id);
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class PurchaseFormPage extends StatefulWidget {
  final Ingredient ing;
  const PurchaseFormPage({super.key, required this.ing});

  @override
  State<PurchaseFormPage> createState() => _PurchaseFormPageState();
}

class _PurchaseFormPageState extends State<PurchaseFormPage> {
  final qty = TextEditingController();
  final price = TextEditingController();
  final note = TextEditingController();
  String date = today();

  @override
  void dispose() {
    qty.dispose();
    price.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: parseDate(date),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );
    if (d != null) setState(() => date = isoDate(d));
  }

  void _save() {
    final g = widget.ing;
    final q = parseNum(qty.text);
    final p = parseNum(price.text);
    if (q <= 0) {
      snack(context, 'اكتب الكمية');
      return;
    }
    store.putPurchase(Purchase(
      id: uid(),
      ingredientId: g.id,
      qty: q,
      price: p,
      date: date,
      note: note.text.trim(),
    ));
    if (p > 0) {
      // آخر سعر شراء هو السعر الحالي للخامة في الطلبات الجديدة.
      g.packQty = q;
      g.packPrice = p;
      store.putIngredient(g);
    }
    final m = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    m.showSnackBar(const SnackBar(content: Text('اتضافت الكمية للمخزن')));
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.ing;
    final cs = Theme.of(context).colorScheme;
    final q = parseNum(qty.text);
    final p = parseNum(price.text);
    return Scaffold(
      appBar: AppBar(title: Text('إضافة ${g.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PickField(
            label: 'تاريخ الشراء',
            value: fmtDay(date),
            icon: Icons.calendar_month,
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          numField('الكمية (${g.unit})', qty,
              suffix: g.unit, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          numField('إجمالي اللي دفعته', price, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          textField('ملاحظة (اختياري)', note, hint: 'اسم المحل مثلاً'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(12)),
            child: Text(
              q > 0 && p > 0
                  ? 'سعر ال${g.unit} الواحد: ${fmtDec(p / q)} ج.م'
                  : 'اكتب الكمية والسعر وهتظهر تكلفة الوحدة. لو كمية افتتاحية من غير سعر، سيب السعر فاضي.',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سعر الشراء ده بيبقى هو السعر الحالي للخامة في الطلبات الجديدة. الطلبات القديمة بتحتفظ بتكلفتها.',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
