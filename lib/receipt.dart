import 'package:url_launcher/url_launcher.dart';

import 'models.dart';
import 'util.dart';

const String shopName = 'Yoyo Cakes';

/// نص الرسيد اللي بيتبعت للعميل (من غير أي تكلفة أو ربح).
String buildReceipt(Order o) {
  final b = StringBuffer();
  final no = (o.created ~/ 1000) % 1000000;
  b.writeln('🎂 *$shopName*');
  b.writeln('*رسيد حجز* رقم #$no');
  b.writeln('────────────');
  b.writeln('العميل: ${o.name}');
  b.writeln('المناسبة: ${o.occasion}');
  b.writeln(
      'ميعاد التسليم: ${fmtDay(o.date)}${o.time.isEmpty ? '' : ' الساعة ${o.time}'}');
  if (o.desc.isNotEmpty) b.writeln('التفاصيل: ${o.desc}');
  if (o.size.isNotEmpty) b.writeln('الحجم: ${o.size}');
  if (o.flavor.isNotEmpty) b.writeln('النكهة: ${o.flavor}');
  if (o.address.isNotEmpty) b.writeln('العنوان: ${o.address}');
  b.writeln('────────────');
  b.writeln('سعر التورتة: ${money(o.price)}');
  if (o.payments.isNotEmpty) {
    for (final p in o.payments) {
      final label = p.note.isEmpty ? 'دفعة' : p.note;
      b.writeln('$label (${fmtDay(p.date)}): ${money(p.amount)}');
    }
  }
  b.writeln('إجمالي المدفوع: ${money(o.paid)}');
  final rest = o.balance < 0 ? 0 : o.balance;
  b.writeln('*المتبقي: ${money(rest)}*');
  b.writeln('────────────');
  b.writeln('شكراً لثقتكم 💛');
  return b.toString().trim();
}

/// بيفتح واتساب برسالة الرسيد جاهزة للعميل. بيرجّع false لو مقدرش يفتحه.
Future<bool> sendReceipt(Order o) async {
  final wa = waLink(o.phone); // https://wa.me/<digits> أو فاضي
  final phone = wa.isEmpty ? '' : wa.substring('https://wa.me/'.length);
  final uri = Uri.https('api.whatsapp.com', '/send', {
    if (phone.isNotEmpty) 'phone': phone,
    'text': buildReceipt(o),
  });
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
