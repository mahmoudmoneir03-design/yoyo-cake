import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../util.dart';
import '../widgets.dart';

class OrderFormPage extends StatefulWidget {
  final Order? order;
  const OrderFormPage({super.key, this.order});

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  late final TextEditingController name, phone, addr, size, desc, flavor;
  late final TextEditingController price, dep, cPack, cDel, cOther, notes;
  late String occasion;
  late String date;
  String time = '';
  late List<Line> lines;

  bool get isNew => widget.order == null;

  @override
  void initState() {
    super.initState();
    final o = widget.order;
    String n(double v) => v == 0 ? '' : fmtDec(v);
    name = TextEditingController(text: o?.name ?? '');
    phone = TextEditingController(text: o?.phone ?? '');
    addr = TextEditingController(text: o?.address ?? '');
    size = TextEditingController(text: o?.size ?? '');
    desc = TextEditingController(text: o?.desc ?? '');
    flavor = TextEditingController(text: o?.flavor ?? '');
    price = TextEditingController(text: n(o?.price ?? 0));
    dep = TextEditingController();
    cPack = TextEditingController(text: n(o?.cPack ?? 0));
    cDel = TextEditingController(text: n(o?.cDel ?? 0));
    cOther = TextEditingController(text: n(o?.cOther ?? 0));
    notes = TextEditingController(text: o?.notes ?? '');
    occasion = (o?.occasion.isNotEmpty ?? false) ? o!.occasion : occasions.first;
    date = o?.date ?? addDays(today(), 3);
    time = o?.time ?? '';
    lines = o == null ? [] : o.lines.map((l) => Line.fromJson(l.toJson())).toList();
  }

  @override
  void dispose() {
    for (final c in [
      name, phone, addr, size, desc, flavor, price, dep, cPack, cDel, cOther, notes
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _cost =>
      lines.fold<double>(0, (s, l) => s + l.cost) +
      parseNum(cPack.text) +
      parseNum(cDel.text) +
      parseNum(cOther.text);

  Future<void> _pickCustomer() async {
    final c = await pickOne<Customer>(
      context,
      'اختار عميل',
      store.customers,
      (c) => c.name,
      sub: (c) => c.phone,
    );
    if (c == null) return;
    setState(() {
      name.text = c.name;
      phone.text = c.phone;
      addr.text = c.address;
    });
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

  Future<void> _pickTime() async {
    final t = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 17, minute: 0));
    if (t != null) {
      setState(() => time =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _addRecipe() async {
    if (store.recipes.isEmpty) {
      snack(context, 'مفيش وصفات لسه. اعمل وصفة من تاب المكونات');
      return;
    }
    final r = await pickOne<Recipe>(
      context,
      'اختار وصفة',
      store.recipes,
      (r) => r.name,
      sub: (r) => 'تكلفتها ${money(store.recipeCost(r))}',
    );
    if (r == null || !mounted) return;
    final mult = await askNumber(context, 'كام مرة من الوصفة دي؟', 1);
    if (mult == null || mult <= 0) return;
    setState(() {
      for (final l in r.lines) {
        final ing = store.ingredientById(l.ingredientId);
        if (ing == null) continue;
        addLine(lines, ing, l.qty * mult);
      }
    });
  }

  void _save() {
    final nm = name.text.trim();
    final p = parseNum(price.text);
    if (nm.isEmpty) {
      snack(context, 'اكتب اسم العميل');
      return;
    }
    if (p <= 0) {
      snack(context, 'اكتب سعر التورتة');
      return;
    }
    final ph = toLatin(phone.text).trim();
    final ad = addr.text.trim();
    final cid = store.ensureCustomer(nm, ph, ad);
    final o = widget.order ?? Order(id: uid(), name: nm, date: date, price: p);
    o.name = nm;
    o.phone = ph;
    o.address = ad;
    o.customerId = cid;
    o.occasion = occasion;
    o.size = size.text.trim();
    o.desc = desc.text.trim();
    o.flavor = flavor.text.trim();
    o.date = date;
    o.time = time;
    o.price = p;
    o.cPack = parseNum(cPack.text);
    o.cDel = parseNum(cDel.text);
    o.cOther = parseNum(cOther.text);
    o.notes = notes.text.trim();
    o.lines = lines;
    if (isNew) {
      final d = parseNum(dep.text);
      if (d > 0) {
        o.payments.add(Payment(
            id: uid(), amount: d > p ? p : d, date: today(), note: 'عربون'));
      }
    }
    store.putOrder(o);
    final m = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    m.showSnackBar(
        SnackBar(content: Text(isNew ? 'اتسجّل الطلب' : 'اتحفظ التعديل')));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = parseNum(price.text);
    final cost = _cost;
    final profit = p - cost;
    final margin = p > 0 ? profit / p * 100 : 0;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'طلب جديد' : 'تعديل الطلب')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          FormCard('بيانات العميل', [
            textField('اسم العميل', name),
            if (store.customers.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: _pickCustomer,
                  icon: const Icon(Icons.person_search),
                  label: const Text('اختار عميل سابق'),
                ),
              ),
            textField('رقم الموبايل', phone, type: TextInputType.phone),
            textField('العنوان (لو توصيل)', addr),
          ]),
          FormCard('التورتة', [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final o in occasions)
                  ChoiceChip(
                    label: Text(o),
                    selected: occasion == o,
                    onSelected: (_) => setState(() => occasion = o),
                  ),
              ],
            ),
            textField('الحجم', size, hint: 'مثلاً ٢ كيلو'),
            textField('وصف التورتة', desc,
                maxLines: 3, hint: 'الشكل، الكتابة، الألوان'),
            textField('النكهة / الحشو', flavor),
            Row(
              children: [
                Expanded(
                  child: PickField(
                    label: 'تاريخ التسليم',
                    value: fmtDay(date),
                    icon: Icons.calendar_month,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PickField(
                    label: 'الميعاد',
                    value: time,
                    icon: Icons.schedule,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
          ]),
          FormCard('مكونات التورتة', [
            LinesEditor(
              lines: lines,
              onChanged: () => setState(() {}),
              onAddRecipe: _addRecipe,
            ),
          ]),
          FormCard('الفلوس', [
            Row(
              children: [
                Expanded(
                    child: numField('سعر التورتة', price,
                        onChanged: (_) => setState(() {}))),
                const SizedBox(width: 10),
                Expanded(
                  child: isNew
                      ? numField('العربون المدفوع', dep)
                      : Text('الدفعات بتتسجّل من شاشة تفاصيل الطلب',
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurfaceVariant)),
                ),
              ],
            ),
            const Text('تكاليف تانية غير الخامات',
                style: TextStyle(fontWeight: FontWeight.w600)),
            Row(
              children: [
                Expanded(
                    child: numField('تغليف وعلبة', cPack,
                        onChanged: (_) => setState(() {}))),
                const SizedBox(width: 10),
                Expanded(
                    child: numField('توصيل', cDel,
                        onChanged: (_) => setState(() {}))),
              ],
            ),
            numField('تكاليف تانية', cOther, onChanged: (_) => setState(() {})),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تكلفة الطلب: ${money(cost)}'),
                  const SizedBox(height: 2),
                  if (p > 0)
                    Text(
                      'ربح الطلب: ${money(profit)} · هامش ${margin.round()}٪',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: profit < 0 ? badC(context) : goodC(context),
                      ),
                    )
                  else if (cost > 0)
                    Text(
                      'سعر مقترح: ${money(cost / 0.7)} (هامش ٣٠٪) · ${money(cost / 0.6)} (٤٠٪) · ${money(cost / 0.5)} (٥٠٪)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    )
                  else
                    const Text('اكتب السعر والتكاليف وهيظهر ربحك هنا.'),
                ],
              ),
            ),
          ]),
          textField('ملاحظات', notes, maxLines: 2),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: Text(isNew ? 'حفظ الطلب' : 'حفظ التعديل'),
          ),
        ],
      ),
    );
  }
}
