import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models.dart';
import '../receipt.dart';
import '../store.dart';
import '../util.dart';
import '../widgets.dart';

// ألوان اللوجو
const Color _pink = Color(0xFFE8336D);
const Color _yellow = Color(0xFFF9B91A);
const Color _blue = Color(0xFF29A8E0);
const Color _ink = Color(0xFF3A1A14);
const Color _soft = Color(0xFFFFF6E0);

/// شاشة الرسيد: بتعرض الرسيد بتصميم مرتب وبتبعته كصورة.
class ReceiptPage extends StatefulWidget {
  final String orderId;
  const ReceiptPage({super.key, required this.orderId});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  final GlobalKey _key = GlobalKey();
  bool _busy = false;

  Future<void> _shareImage(Order o) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final b = _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 3);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw Exception('no data');
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/receipt-${o.id}.png');
      await f.writeAsBytes(data.buffer.asUint8List());
      await Share.shareXFiles(
        [XFile(f.path, mimeType: 'image/png')],
        text: 'رسيد حجز - $shopName',
      );
    } catch (_) {
      if (mounted) snack(context, 'مقدرتش أجهّز صورة الرسيد');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final o = store.orderById(widget.orderId);
        if (o == null) {
          return Scaffold(
              appBar: AppBar(), body: const Center(child: Text('الطلب اتمسح')));
        }
        return Scaffold(
          appBar: AppBar(title: const Text('رسيد الحجز')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: RepaintBoundary(
                    key: _key,
                    child: ReceiptCard(order: o),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy ? null : () => _shareImage(o),
                icon: const Icon(Icons.image_outlined),
                label: Text(_busy ? 'بجهّز الصورة...' : 'ابعت الرسيد كصورة'),
                style:
                    FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
              const SizedBox(height: 4),
              Text(
                'هتفتحلك قايمة المشاركة، اختار واتساب وبعدها اختار العميل.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await sendReceipt(o);
                  if (!ok && context.mounted) {
                    snack(context, 'مقدرتش أفتح واتساب');
                  }
                },
                icon: const Icon(Icons.chat_outlined),
                label: const Text('ابعته كنص على رقم العميل'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReceiptCard extends StatelessWidget {
  final Order order;
  const ReceiptCard({super.key, required this.order});

  Widget _row(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 92,
              child: Text(k,
                  style: const TextStyle(
                      color: Color(0xFF8A6A60), fontSize: 14)),
            ),
            Expanded(
              child: Text(v,
                  style: TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _dots() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: LayoutBuilder(
          builder: (context, c) {
            final n = (c.maxWidth / 8).floor();
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < n; i++)
                  Container(
                      width: 4,
                      height: 2,
                      color: _yellow.withValues(alpha: 0.9)),
              ],
            );
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final o = order;
    final no = (o.created ~/ 1000) % 1000000;
    final rest = o.balance < 0 ? 0.0 : o.balance;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTextStyle(
        style: const TextStyle(color: _ink),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _yellow, width: 3),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Image.asset('assets/icon/icon.png',
                    height: 150, fit: BoxFit.contain),
              ),
              Container(
                color: _pink,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('رسيد حجز',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text('#$no',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Container(height: 5, color: _blue),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _row('العميل', o.name, bold: true),
                    _row('المناسبة', o.occasion),
                    _row('التسليم',
                        '${fmtDay(o.date)}${o.time.isEmpty ? '' : ' - ${o.time}'}',
                        bold: true),
                    if (o.desc.isNotEmpty) _row('التفاصيل', o.desc),
                    if (o.size.isNotEmpty) _row('الحجم', o.size),
                    if (o.flavor.isNotEmpty) _row('النكهة', o.flavor),
                    if (o.address.isNotEmpty) _row('العنوان', o.address),
                    _dots(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _soft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _amount('سعر التورتة', money(o.price), true),
                          for (final p in o.payments)
                            _amount(
                              '${p.note.isEmpty ? 'دفعة' : p.note} (${fmtDay(p.date)})',
                              money(p.amount),
                              false,
                            ),
                          const Divider(height: 14),
                          _amount('إجمالي المدفوع', money(o.paid), true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        color: rest > 0 ? _pink : const Color(0xFF2E9E5B),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(rest > 0 ? 'المتبقي عند الاستلام' : 'خالص',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          Text(money(rest),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Center(
                      child: Text('شكراً لثقتكم 💛',
                          style: TextStyle(
                              color: _pink,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amount(String k, String v, bool bold) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(k,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
            ),
            Text(v,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
          ],
        ),
      );
}
