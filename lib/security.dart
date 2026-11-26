import 'dart:math';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _alpha = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

int _fnv(String s, int seed) {
  var h = seed;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 16777619) & 0xFFFFFFFF;
  }
  return h;
}

String _pinHash(String device, String pin) =>
    '${_fnv('pin:$device:$pin', 0x811C9DC5).toRadixString(16)}'
    '${_fnv('$pin:pin:$device', 0x9E3779B1).toRadixString(16)}';

final Security security = Security();

/// الرقم السري والبصمة.
class Security extends ChangeNotifier {
  SharedPreferences? _p;
  String device = '';
  String _pin = '';
  bool bio = false;
  bool locked = false;
  int _fails = 0;
  DateTime? _blockedUntil;

  Future<void> load() async {
    try {
      _p = await SharedPreferences.getInstance();
      device = _p!.getString('sec_device') ?? '';
      if (device.isEmpty) {
        final r = Random.secure();
        device = List.generate(8, (_) => _alpha[r.nextInt(_alpha.length)]).join();
        await _p!.setString('sec_device', device);
      }
      _pin = _p!.getString('sec_pin') ?? '';
      bio = _p!.getBool('sec_bio') ?? false;
    } catch (_) {}
    locked = hasPin;
  }

  bool get hasPin => _pin.isNotEmpty;

  void setPin(String pin) {
    _pin = _pinHash(device, pin);
    _p?.setString('sec_pin', _pin);
    _fails = 0;
    notifyListeners();
  }

  bool matches(String pin) => hasPin && _pin == _pinHash(device, pin);

  int get blockedSeconds {
    final b = _blockedUntil;
    if (b == null) return 0;
    final s = b.difference(DateTime.now()).inSeconds + 1;
    return s > 0 ? s : 0;
  }

  /// تحقق من الرقم مع إيقاف مؤقت بعد ٥ محاولات غلط.
  bool checkPin(String pin) {
    if (blockedSeconds > 0) return false;
    if (matches(pin)) {
      _fails = 0;
      return true;
    }
    _fails++;
    if (_fails >= 5) {
      _fails = 0;
      _blockedUntil = DateTime.now().add(const Duration(seconds: 30));
    }
    return false;
  }

  void setBio(bool v) {
    bio = v;
    _p?.setBool('sec_bio', v);
    notifyListeners();
  }

  void lock() {
    if (!hasPin || locked) return;
    FocusManager.instance.primaryFocus?.unfocus();
    locked = true;
    notifyListeners();
  }

  void unlock() {
    if (!locked) return;
    FocusManager.instance.primaryFocus?.unfocus();
    locked = false;
    notifyListeners();
  }

  /// بصمة أو قفل الموبايل (نمط / رقم). بيرجّع false لو مش متاح أو اتلغى.
  Future<bool> authenticateDevice() async {
    try {
      final a = LocalAuthentication();
      if (!await a.isDeviceSupported()) return false;
      return await a.authenticate(
        localizedReason: 'افتح Yoyo Cake',
        options: const AuthenticationOptions(
            biometricOnly: false, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}
