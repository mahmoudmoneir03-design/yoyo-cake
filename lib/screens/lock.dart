import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../security.dart';
import '../widgets.dart';

Widget _logo() => Image.asset('assets/icon/icon.png', height: 120);

Widget _pinField(TextEditingController c, String label,
    {ValueChanged<String>? onChanged, ValueChanged<String>? onSubmitted, bool autofocus = false}) {
  return TextField(
    controller: c,
    autofocus: autofocus,
    obscureText: true,
    keyboardType: TextInputType.number,
    textAlign: TextAlign.center,
    maxLength: 6,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    style: const TextStyle(fontSize: 22, letterSpacing: 8),
    decoration: InputDecoration(labelText: label, counterText: ''),
  );
}

/// تعيين أو تغيير الرقم السري (٤ إلى ٦ أرقام).
class PinSetupPage extends StatefulWidget {
  final String title;
  final bool askOld;
  final ValueChanged<String> onDone;
  const PinSetupPage(
      {super.key,
      required this.title,
      required this.onDone,
      this.askOld = false});

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  final old = TextEditingController();
  final p1 = TextEditingController();
  final p2 = TextEditingController();
  String error = '';

  @override
  void dispose() {
    old.dispose();
    p1.dispose();
    p2.dispose();
    super.dispose();
  }

  void _go() {
    if (widget.askOld && !security.checkPin(old.text)) {
      setState(() => error = security.blockedSeconds > 0
          ? 'استنى ${security.blockedSeconds} ثانية وجرّب تاني'
          : 'الرقم الحالي غلط');
      return;
    }
    if (p1.text.length < 4) {
      setState(() => error = 'الرقم السري لازم يكون ٤ أرقام على الأقل');
      return;
    }
    if (p1.text != p2.text) {
      setState(() => error = 'الرقمين مش زي بعض');
      return;
    }
    widget.onDone(p1.text);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: widget.askOld ? AppBar(title: Text(widget.title)) : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!widget.askOld) ...[
                    Center(child: _logo()),
                    const SizedBox(height: 12),
                    Text(widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                  ],
                  Text('اختار رقم سري من ٤ لـ ٦ أرقام.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  if (widget.askOld) ...[
                    _pinField(old, 'الرقم الحالي'),
                    const SizedBox(height: 8),
                  ],
                  _pinField(p1, 'الرقم السري الجديد'),
                  const SizedBox(height: 8),
                  _pinField(p2, 'أكّد الرقم السري', onSubmitted: (_) => _go()),
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(error,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.error)),
                    ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _go,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// شاشة القفل: رقم سري أو بصمة / قفل الموبايل.
class LockPage extends StatefulWidget {
  const LockPage({super.key});

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  final pin = TextEditingController();
  String error = '';

  @override
  void initState() {
    super.initState();
    if (security.bio) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _bio());
    }
  }

  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  Future<void> _bio() async {
    final ok = await security.authenticateDevice();
    if (ok) security.unlock();
  }

  void _submit() {
    if (security.checkPin(pin.text)) {
      security.unlock();
      return;
    }
    setState(() {
      error = security.blockedSeconds > 0
          ? 'محاولات كتير. استنى ${security.blockedSeconds} ثانية'
          : 'الرقم السري غلط';
      pin.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _logo()),
                  const SizedBox(height: 12),
                  const Text('اكتب الرقم السري',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  _pinField(
                    pin,
                    'الرقم السري',
                    autofocus: !security.bio,
                    onChanged: (v) {
                      if (v.length >= 4 && security.matches(v)) {
                        security.unlock();
                      } else if (error.isNotEmpty) {
                        setState(() => error = '');
                      }
                    },
                    onSubmitted: (_) => _submit(),
                  ),
                  if (error.isNotEmpty)
                    Text(error,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.error)),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    child: const Text('دخول'),
                  ),
                  if (security.bio) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _bio,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('بصمة / قفل الموبايل'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// شاشة إعدادات الأمان.
class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: security,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('الأمان')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('الدخول بالبصمة / قفل الموبايل'),
                subtitle: const Text('بدل ما تكتب الرقم السري كل مرة'),
                value: security.bio,
                onChanged: (v) async {
                  if (!v) {
                    security.setBio(false);
                    return;
                  }
                  final ok = await security.authenticateDevice();
                  if (ok) {
                    security.setBio(true);
                  } else if (context.mounted) {
                    snack(context,
                        'مقدرتش أفعّلها. اتأكد إن في بصمة أو قفل متسجّل على الموبايل');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.password),
                title: const Text('تغيير الرقم السري'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PinSetupPage(
                      title: 'تغيير الرقم السري',
                      askOld: true,
                      onDone: (p) {
                        security.setPin(p);
                        Navigator.pop(context);
                        snack(context, 'اتغيّر الرقم السري');
                      },
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('اقفل التطبيق دلوقتي'),
                onTap: security.lock,
              ),
              const SizedBox(height: 8),
              Text(
                'التطبيق بيتقفل لوحده لو خرجت منه أكتر من دقيقة.',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }
}
