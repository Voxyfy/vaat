import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vaat/core/content.dart';

/// Olay dosyaları uygulamada elle listeleniyor. Yeni bir dosya listeye
/// eklenmezse kartları oyunda hiç çıkmaz ve hiçbir şey hata vermez.
void main() {
  test('olay dosyası listesi klasörle birebir aynı', () {
    final onDisk = Directory('../content/events')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.endsWith('.json'))
        .toSet();
    expect(GameContent.eventFiles.toSet(), onDisk);
  });
}
