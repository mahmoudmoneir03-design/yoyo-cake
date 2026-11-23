import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../store.dart';
import '../util.dart';
import '../widgets.dart';
import 'orders.dart';

class CustStat {
  final Customer c;
  final List<Order> orders;
  final double sales, paid;
  CustStat(this.c, this.orders, this.sales, this.paid);
  double get due => sales - paid;
}

CustStat statFor(Customer c) {
  final os = store.orders.where((o) => o.customerId == c.id).toList();
  var s = 0.0, p = 0.0;
  for (final o in os) {
    if (o.status == 'cancelled') continue;
    s += o.price;
    p += o.paid;
  }
  return CustStat(c, os, s, p);
}

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('العملاء')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CustomerFormPage())),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('عميل جديد'),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final s = q.trim().toLowerCase();
          final dq = digitsOf(s);
          final stats = store.customers
              .where((c) =>
                  s.isEmpty ||
                  c.name.toLowerCase().contains(s) ||
                  (dq.isNotEmpty && digitsOf(c.phone).contains(dq)))
              .map(statFor)
              .toList()
            ..sort((a, b) => b.sales.compareTo(a.sales));
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
              const SizedBox(height: 12),
              if (store.customers.isEmpty)
                const EmptyState(
                  title: 'مفيش عملاء لسه',
                  text:
                      'العملاء بيتسجّلوا لوحدهم مع كل طلب، وتقدر تضيف عميل بنفسك كمان.',
                )
              else if (stats.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('مفيش عميل بالاسم ده.')))
              else
                for (final st in stats) ...[
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: Text(st.c.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${st.c.phone.isEmpty ? '' : '${st.c.phone} · '}${st.orders.length} طلب'),
                          if (st.due > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Pill('باقي عليه ${fmtInt(st.due)}',
                                  color: warnC(context)),
                            ),
                        ],
                      ),
                      trailing: Text(money(st.sales),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CustomerDetailPage(id: st.c.id))),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }
}

class CustomerDetailPage extends StatelessWidget {
  final String id;
  const CustomerDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = store.customerById(id);
        if (c == null) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('العميل اتمسح')));
        }
        final st = statFor(c);
        final wa = waLink(c.phone);
        final orders = [...st.orders]..sort((a, b) => b.date.compareTo(a.date));
        return Scaffold(
          appBar: AppBar(
            title: Text(c.name),
            actions: [
              IconButton(
                tooltip: 'تعديل',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CustomerFormPage(customer: c))),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (c.phone.isNotEmpty)
                Row(
                  children: [
                    Expanded(child: Text(c.phone)),
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: c.phone));
                        snack(context, 'اتنسخ الرقم');
                      },
                      child: const Text('نسخ'),
                    ),
                    if (wa.isNotEmpty)
                      FilledButton.tonal(
                        onPressed: () => launchUrl(Uri.parse(wa),
                            mode: LaunchMode.externalApplication),
                        child: const Text('واتساب'),
                      ),
                  ],
                ),
              if (c.address.isNotEmpty) Text('العنوان: ${c.address}'),
              if (c.notes.isNotEmpty) Text('ملاحظات: ${c.notes}'),
              const SizedBox(height: 12),
              StatGrid([
                StatTile('إجمالي طلباته', money(st.sales)),
                StatTile('باقي عليه', money(st.due < 0 ? 0 : st.due),
                    color: st.due > 0 ? badC(context) : null),
              ]),
              SectionTitle('طلباته', trailing: '${orders.length}'),
              if (orders.isEmpty) const Text('مفيش طلبات لسه.'),
              for (final o in orders) ...[
                OrderTile(o),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

class CustomerFormPage extends StatefulWidget {
  final Customer? customer;
  const CustomerFormPage({super.key, this.customer});

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  late final TextEditingController name, phone, addr, notes;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    name = TextEditingController(text: c?.name ?? '');
    phone = TextEditingController(text: c?.phone ?? '');
    addr = TextEditingController(text: c?.address ?? '');
    notes = TextEditingController(text: c?.notes ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    addr.dispose();
    notes.dispose();
    super.dispose();
  }

  void _save() {
    final nm = name.text.trim();
    if (nm.isEmpty) {
      snack(context, 'اكتب اسم العميل');
      return;
    }
    final c = widget.customer ?? Customer(id: uid(), name: nm);
    c.name = nm;
    c.phone = toLatin(phone.text).trim();
    c.address = addr.text.trim();
    c.notes = notes.text.trim();
    store.putCustomer(c);
    Navigator.pop(context);
  }

  Future<void> _pickContact() async {
    final r = await pickPhoneContact(context);
    if (r == null) return;
    setState(() {
      if (r[0].isNotEmpty) name.text = r[0];
      phone.text = r[1];
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    return Scaffold(
      appBar: AppBar(title: Text(c == null ? 'عميل جديد' : 'تعديل عميل')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: _pickContact,
              icon: const Icon(Icons.contacts_outlined),
              label: const Text('استيراد من جهات الاتصال'),
            ),
          ),
          const SizedBox(height: 12),
          textField('الاسم', name),
          const SizedBox(height: 12),
          textField('رقم الموبايل', phone, type: TextInputType.phone),
          const SizedBox(height: 12),
          textField('العنوان', addr),
          const SizedBox(height: 12),
          textField('ملاحظات', notes,
              maxLines: 3, hint: 'مثلاً: بتحب الشوكولاتة، عيد ميلاد ابنها في مارس'),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('حفظ'),
          ),
          if (c != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                final ok = await confirmDialog(
                    context, 'تمسح العميل؟ الطلبات بتاعته هتفضل زي ما هي.');
                if (ok) {
                  store.deleteCustomer(c.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                  foregroundColor: badC(context),
                  minimumSize: const Size.fromHeight(48)),
              child: const Text('مسح العميل'),
            ),
          ],
        ],
      ),
    );
  }
}
