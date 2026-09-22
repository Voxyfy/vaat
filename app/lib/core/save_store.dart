import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Kayıtları diske yazan katman.
///
/// Neden veritabanı değil: oyunun kaydı tek bir blob, sorgulanacak bir şey
/// yok. İki JSON dosyası hem daha az bağımlılık hem elle okunabilir kayıt
/// demek. Skor tablosu büyürse burası değişir, oyun değişmez.
class SaveStore {
  SaveStore(this._dir);

  final Directory _dir;

  /// Yazmalar sıraya giriyor. Bir hafta kapanışı arka arkaya birkaç kayıt
  /// tetikleyebiliyor; aynı geçici dosyayı paylaşan iki yazma birbirini
  /// eziyordu ve biri "dosya yok" hatasıyla düşüyordu.
  Future<void> _queue = Future<void>.value();

  Future<void> _enqueue(Future<void> Function() job) {
    final next = _queue.then((_) => job(), onError: (_) => job());
    // Hata zinciri kırmasın: sıradaki yazma yine çalışsın.
    _queue = next.catchError((_) {});
    return next;
  }

  static const _currentFile = 'career.json';
  static const _scoresFile = 'scores.json';

  /// Kayıt biçimi sürümü. Uyuşmayan kayıt yüklenmez, atılır: yarım okunmuş
  /// bir kariyer, hiç kayıt olmamasından daha kötü.
  static const formatVersion = 1;

  static Future<SaveStore> open() async {
    final dir = await getApplicationSupportDirectory();
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return SaveStore(dir);
  }

  File get _current => File('${_dir.path}/$_currentFile');
  File get _scores => File('${_dir.path}/$_scoresFile');

  bool get hasSave => _current.existsSync();

  /// Devam eden oyunu yazar. Önce geçici dosyaya, sonra yerine taşınır:
  /// yazma sırasında uygulama kapanırsa eski kayıt bozulmasın.
  Future<void> writeCurrent(Map<String, dynamic> data) {
    final payload = jsonEncode({'version': formatVersion, 'data': data});
    return _enqueue(() async {
      final tmp = File('${_current.path}.tmp');
      await tmp.writeAsString(payload, flush: true);
      await tmp.rename(_current.path);
    });
  }

  /// Devam eden oyunu okur. Bozuk veya eski sürüm kayıt sessizce atılır.
  Future<Map<String, dynamic>?> readCurrent() async {
    if (!_current.existsSync()) return null;
    try {
      final raw = jsonDecode(await _current.readAsString());
      if (raw is! Map<String, dynamic>) return null;
      if (raw['version'] != formatVersion) {
        await clearCurrent();
        return null;
      }
      return raw['data'] as Map<String, dynamic>;
    } catch (_) {
      // Yarım yazılmış veya elle kurcalanmış kayıt: atıp yeni oyuna başla.
      await clearCurrent();
      return null;
    }
  }

  Future<void> clearCurrent() async {
    if (_current.existsSync()) await _current.delete();
  }

  /// Biten kariyerleri okur, en yüksek skor başta.
  Future<List<Map<String, dynamic>>> readScores() async {
    if (!_scores.existsSync()) return const [];
    try {
      final raw = jsonDecode(await _scores.readAsString());
      if (raw is! List) return const [];
      return [
        for (final e in raw)
          if (e is Map<String, dynamic>) e,
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Biten kariyeri tabloya ekler. Liste sınırlı tutulur; kimse yüzüncü
  /// kariyerine bakmıyor.
  Future<void> addScore(Map<String, dynamic> entry) => _enqueue(() async {
        final all = [...await readScores(), entry]
          ..sort((a, b) =>
              ((b['score'] as num?) ?? 0).compareTo((a['score'] as num?) ?? 0));
        final top = all.take(25).toList();
        final tmp = File('${_scores.path}.tmp');
        await tmp.writeAsString(jsonEncode(top), flush: true);
        await tmp.rename(_scores.path);
      });

  @visibleForTesting
  Future<void> wipe() async {
    await clearCurrent();
    if (_scores.existsSync()) await _scores.delete();
  }
}

/// main() içinde override edilir.
final saveStoreProvider = Provider<SaveStore>(
  (_) => throw UnimplementedError('saveStoreProvider main() içinde override edilmeli'),
);
