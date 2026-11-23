import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../util.dart';
import '../widgets.dart';
import '../notifications.dart';
import 'expenses.dart';
import 'orders.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.cake, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Yoyo Cake',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'جرّب الإشعارات',
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () async {
              await testNotification();
              if (context.mounted) {
                snack(context,
                    'لو الإشعار مجاش، فعّل الإشعارات للتطبيق من إعدادات الموبايل');
              }
            },
          ),
          IconButton(
            tooltip: 'المصروفات',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ExpensesPage())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openNewOrder(context),
        icon: const Icon(Icons.add),
        label: const Text('طلب جديد'),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (store.orders.isEmpty && store.expenses.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  title: 'أهلاً في دفتر التورت',
                  text:
                      'ابدأ بتسجيل الخامات وأسعارها من تاب "المكونات"، وبعدها سجّل أول طلب وهتعرف ربحك الصافي.',
                  action: 'سجّل أول طلب',
                  onAction: () => openNewOrder(context),
                ),
              ),
            );
          }
          final r = periodRange('month');
          final rep = store.report(r[0], r[1], false);
          final upcoming = store.orders.where((o) => o.isOpen).toList()
            ..sort((a, b) => '${a.date}${a.time}'.compareTo('${b.date}${b.time}'));
          final owed = store.orders
              .where((o) => o.status == 'delivered' && o.balance > 0)
              .toList()
            ..sort((a, b) => b.balance.compareTo(a.balance));
          final label = 'صافي ربحك في ${monthName(r[0].substring(0, 7))}'
              '${rep.net < 0 ? ' (خسارة)' : ''}';
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              HeroCard(
                label: label,
                value: money(rep.net),
                trio: [
                  MapEntry('المبيعات', money(rep.sales)),
                  MapEntry('اتحصّل', money(rep.paid)),
                  MapEntry('لسه عند العملاء', money(rep.due)),
                ],
              ),
              SectionTitle('الطلبات الجاية', trailing: '${upcoming.length}'),
              if (upcoming.isEmpty)
                const Text('مفيش طلبات مفتوحة دلوقتي.')
              else
                for (final o in upcoming.take(5)) ...[
                  OrderTile(o),
                  const SizedBox(height: 10),
                ],
              if (owed.isNotEmpty) ...[
                const SectionTitle('فلوس لسه عند العملاء'),
                for (final Order o in owed.take(4)) ...[
                  OrderTile(o),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
