import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'util.dart';

String _dir = '';

/// بيجهّز فولدر صور التورت جوه مساحة التطبيق (بيتنادى مرة عند التشغيل).
Future<void> initPhotos() async {
  try {
    final d = await getApplicationDocumentsDirectory();
    final p = Directory('${d.path}/photos');
    if (!p.existsSync()) p.createSync(recursive: true);
    _dir = p.path;
  } catch (_) {}
}

File? photoFile(String name) =>
    (name.isEmpty || _dir.isEmpty) ? null : File('$_dir/$name');

bool hasPhoto(String name) {
  final f = photoFile(name);
  return f != null && f.existsSync();
}

/// بيفتح المعرض أو الكاميرا وبينسخ الصورة لمساحة التطبيق. بيرجّع اسم الملف.
Future<String?> pickPhoto(ImageSource src) async {
  try {
    final x = await ImagePicker()
        .pickImage(source: src, maxWidth: 1400, imageQuality: 82);
    if (x == null) return null;
    final name = '${uid()}.jpg';
    await File(x.path).copy('$_dir/$name');
    return name;
  } catch (_) {
    return null;
  }
}

void deletePhoto(String name) {
  try {
    final f = photoFile(name);
    if (f != null && f.existsSync()) f.deleteSync();
  } catch (_) {}
}

/// صورة صغيرة مربعة (للقوايم).
class PhotoThumb extends StatelessWidget {
  final String name;
  final double size;
  final double radius;
  const PhotoThumb(
      {super.key, required this.name, this.size = 54, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    final f = photoFile(name);
    if (f == null || !f.existsSync()) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => showPhoto(context, name),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.file(
          f,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * 3).round(),
          errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
        ),
      ),
    );
  }
}

/// عرض الصورة بالحجم الكامل مع إمكانية التكبير.
void showPhoto(BuildContext context, String name) {
  final f = photoFile(name);
  if (f == null || !f.existsSync()) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: InteractiveViewer(
            maxScale: 5,
            child: Image.file(f, fit: BoxFit.contain),
          ),
        ),
      ),
    ),
  );
}
