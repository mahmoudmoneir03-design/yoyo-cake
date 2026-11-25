import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';
import 'util.dart';

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
bool _ready = false;

/// الساعة اللي بيجيلك فيها إشعار "تسليم النهارده" صباح يوم التسليم.
const int morningHour = 8;

/// بيجيلك إشعار قبل ميعاد التسليم بالمدة دي.
const Duration beforeDelivery = Duration(hours: 1);

const NotificationDetails _details = NotificationDetails(
  android: AndroidNotificationDetails(
    'delivery',
    'مواعيد التسليم',
    channelDescription: 'تنبيهات تسليم الطلبات',
    importance: Importance.max,
    priority: Priority.high,
  ),
);

Future<void> initNotifications() async {
  try {
    tzdata.initializeTimeZones();
    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(init);
    final a = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await a?.requestNotificationsPermission();
    _ready = true;
  } catch (_) {
    _ready = false;
  }
}

int _hash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0x7fffffff;
  }
  return h;
}

/// رقم إشعار ثابت لكل طلب (k=0 الصبح، k=1 قبل التسليم).
int _nid(String orderId, int k) => (_hash(orderId) % 1000000000) * 2 + k;

Future<void> _at(int id, DateTime when, String title, String body) async {
  // نفس اللحظة بالظبط، من غير ما نحتاج منطقة زمنية للجهاز.
  final t = tz.TZDateTime.from(when, tz.UTC);
  try {
    await _plugin.zonedSchedule(id, title, body, t, _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
  } catch (_) {
    try {
      await _plugin.zonedSchedule(id, title, body, t, _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle);
    } catch (_) {}
  }
}

Future<void> cancelOrderNotifications(String orderId) async {
  if (!_ready) return;
  try {
    await _plugin.cancel(_nid(orderId, 0));
    await _plugin.cancel(_nid(orderId, 1));
  } catch (_) {}
}

/// بيلغي إشعارات الطلب القديمة ويجدولها من جديد حسب تاريخه وميعاده.
Future<void> syncOrderNotifications(Order o) async {
  if (!_ready) return;
  await cancelOrderNotifications(o.id);
  if (!o.isOpen || o.date.isEmpty) return;

  final d = parseDate(o.date);
  final now = DateTime.now();
  DateTime? due;
  if (o.time.contains(':')) {
    final p = o.time.split(':');
    due = DateTime(d.year, d.month, d.day, int.parse(p[0]), int.parse(p[1]));
  }

  final bal = o.balance > 0 ? ' · باقي عليه ${money(o.balance)}' : '';
  final what = '${o.name} · ${o.occasion}${o.time.isEmpty ? '' : ' · ${o.time}'}$bal';

  final morning = DateTime(d.year, d.month, d.day, morningHour, 0);
  final before = due?.subtract(beforeDelivery);

  if (morning.isAfter(now) && (before == null || before.isAfter(morning))) {
    await _at(_nid(o.id, 0), morning, 'تسليم النهارده 🎂', what);
  }
  if (before != null && before.isAfter(now)) {
    await _at(_nid(o.id, 1), before, 'باقي ساعة على التسليم ⏰', what);
  }
}

Future<void> resyncAllNotifications(List<Order> orders) async {
  for (final o in orders) {
    await syncOrderNotifications(o);
  }
}

Future<void> testNotification() async {
  if (!_ready) return;
  try {
    await _plugin.show(
        0, 'الإشعارات شغّالة ✅', 'هيجيلك تنبيه صباح يوم التسليم وقبله بساعة.', _details);
  } catch (_) {}
}
