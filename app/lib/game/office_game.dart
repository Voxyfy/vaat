import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Ofisin dışarıdan görünen hâli. Şemanın sayıları buraya çevrilir.
class OfficeSnapshot {
  const OfficeSnapshot({
    required this.investors,
    required this.suspicion,
    required this.bankRun,
  });

  final int investors;
  final double suspicion;
  final bool bankRun;

  /// Ofis seviyesi: dükkân, plaza, yalı. Yatırımcı sayısı büyüdükçe mekân
  /// büyür. Görünürlük hem oyuncuya haz verir hem şüpheyi besler.
  int get level => investors >= 2000
      ? 2
      : investors >= 200
          ? 1
          : 0;

  /// Sahnede kaç çalışan dolaşsın. Kalabalık ofis büyüklüğün göstergesi.
  int get staff => (1 + math.log(1 + investors) / 1.6).clamp(1, 6).toInt();

  /// Kapıda birileri var mı: gazeteci, sonra savcı.
  bool get watcher => suspicion >= 35 || bankRun;
}

/// Ofis sahnesi. Yalnız gösterir, oyunu değiştirmez.
///
/// Neden Flame: yürüyen karakterler ve kare kare animasyon için Flutter
/// widget'larıyla uğraşmak gereksiz zor. Yönetim ekranları saf Flutter kalıyor,
/// yalnız bu sahne oyun motoruna veriliyor.
class OfficeGame extends FlameGame {
  OfficeGame({required this.background});

  /// Sahne dışı zemin rengi; temadan geliyor ki iki dünya aynı görünsün.
  final Color background;

  /// Sanal çözünürlük. Pixel art tam sayı ölçekte keskin kalsın diye sabit.
  static const sceneWidth = 160.0;
  static const sceneHeight = 96.0;
  static const tile = 16.0;

  /// Zeminin başladığı yükseklik. Üstü duvar, altı yürünebilir alan.
  static const floorTop = 48.0;

  final _rng = math.Random(7);
  final _staff = <_Worker>[];

  late final Sprite _floor;
  late final Sprite _wall;
  late final Sprite _wallBase;
  late final Map<String, Sprite> _props;
  late final List<SpriteAnimation> _walks;

  _Watcher? _watcher;
  OfficeSnapshot _snapshot =
      const OfficeSnapshot(investors: 0, suspicion: 0, bankRun: false);
  int _builtLevel = -1;

  @override
  Color backgroundColor() => background;

  @override
  Future<void> onLoad() async {
    // Flame varsayılan olarak assets/images altına bakar; sprite'lar kendi
    // klasöründe dursun diye ön eki değiştiriyoruz.
    images.prefix = 'assets/sprites/';

    camera = CameraComponent.withFixedResolution(
      width: sceneWidth,
      height: sceneHeight,
      world: world,
    );
    // Kamera dünyayı merkezler; sahne (0,0)'dan başladığı için görüşü
    // ortasına taşımazsak oda köşeye sıkışıyor.
    camera.viewfinder.position = Vector2(sceneWidth / 2, sceneHeight / 2);

    _floor = await loadSprite('floor.png');
    _wall = await loadSprite('wall.png');
    _wallBase = await loadSprite('wall_base.png');
    _props = {
      for (final name in ['desk', 'cabinet', 'plant', 'safe'])
        name: await loadSprite('$name.png'),
    };
    _walks = [
      for (var i = 0; i < 5; i++)
        SpriteAnimation.fromFrameData(
          await images.load('person_$i.png'),
          SpriteAnimationData.sequenced(
            amount: 3,
            stepTime: 0.22,
            textureSize: Vector2.all(16),
          ),
        ),
    ];

    _buildRoom();
    _applySnapshot();
  }

  /// Oyun durumu değişince çağrılır. Sahne yalnız gerektiğinde yeniden kurulur.
  void update2(OfficeSnapshot snapshot) {
    _snapshot = snapshot;
    if (isLoaded) _applySnapshot();
  }

  void _applySnapshot() {
    if (_snapshot.level != _builtLevel) _buildRoom();
    _syncStaff();
    _syncWatcher();
  }

  /// Zemin, duvar ve seviyeye göre mobilya.
  void _buildRoom() {
    _builtLevel = _snapshot.level;
    world.children
        .whereType<_RoomPiece>()
        .toList()
        .forEach((c) => c.removeFromParent());

    for (var x = 0.0; x < sceneWidth; x += tile) {
      for (var y = 0.0; y < floorTop; y += tile) {
        // Zemine bitişik sıra süpürgelikli, üstü düz: böylece duvar yukarı
        // tekrar ederken tile sınırları çizgi olarak görünmüyor.
        final isBase = y + tile >= floorTop;
        world.add(_RoomPiece(
            sprite: isBase ? _wallBase : _wall, position: Vector2(x, y)));
      }
      for (var y = floorTop; y < sceneHeight; y += tile) {
        world.add(_RoomPiece(sprite: _floor, position: Vector2(x, y)));
      }
    }

    // Mobilya seviyeye göre artıyor: dükkândan plazaya, plazadan yalıya.
    final layout = <(String, double)>[
      ('desk', 16),
      ('plant', 128),
      if (_builtLevel >= 1) ...[('desk', 56), ('cabinet', 96)],
      if (_builtLevel >= 2) ...[('desk', 76), ('safe', 112)],
    ];
    for (final (name, x) in layout) {
      world.add(_RoomPiece(
        sprite: _props[name]!,
        position: Vector2(x, floorTop - tile),
        priority: 1,
      ));
    }
  }

  void _syncStaff() {
    final want = _snapshot.staff;
    while (_staff.length > want) {
      _staff.removeLast().removeFromParent();
    }
    while (_staff.length < want) {
      final worker = _Worker(
        animation: _walks[_staff.length % _walks.length],
        rng: _rng,
        position: Vector2(
          _rng.nextDouble() * (sceneWidth - tile),
          floorTop + 8 + _rng.nextDouble() * (sceneHeight - floorTop - tile - 8),
        ),
      );
      _staff.add(worker);
      world.add(worker);
    }
  }

  /// Kapıdaki figür: şüphe yükselince belirir, yaklaşır, gitmez.
  void _syncWatcher() {
    if (_snapshot.watcher && _watcher == null) {
      _watcher = _Watcher(
        animation: _walks.last,
        position: Vector2(sceneWidth - tile - 2, floorTop + 4),
      );
      world.add(_watcher!);
    } else if (!_snapshot.watcher && _watcher != null) {
      _watcher!.removeFromParent();
      _watcher = null;
    }
  }
}

/// Zemin, duvar veya mobilya parçası. Hareketsiz.
class _RoomPiece extends SpriteComponent {
  _RoomPiece({
    required super.sprite,
    required super.position,
    super.priority = 0,
  }) : super(size: Vector2.all(OfficeGame.tile));
}

/// Masalar arasında dolaşan çalışan.
class _Worker extends SpriteAnimationComponent {
  _Worker({
    required SpriteAnimation animation,
    required this.rng,
    required super.position,
  }) : super(
          animation: animation,
          size: Vector2.all(OfficeGame.tile),
          priority: 2,
        );

  final math.Random rng;
  late Vector2 _target = _pickTarget();
  double _idle = 0;

  Vector2 _pickTarget() => Vector2(
        rng.nextDouble() * (OfficeGame.sceneWidth - OfficeGame.tile),
        OfficeGame.floorTop +
            8 +
            rng.nextDouble() *
                (OfficeGame.sceneHeight - OfficeGame.floorTop - OfficeGame.tile - 8),
      );

  @override
  void update(double dt) {
    super.update(dt);
    if (_idle > 0) {
      _idle -= dt;
      playing = false;
      return;
    }
    playing = true;
    final delta = _target - position;
    if (delta.length < 1.5) {
      // Hedefe vardı: biraz dursun, sonra yeni bir yere gitsin. Sürekli
      // hareket eden ofis huzursuz görünüyor.
      _idle = 0.6 + rng.nextDouble() * 2.4;
      _target = _pickTarget();
      return;
    }
    final step = delta.normalized() * 12 * dt;
    position.add(step);
    // Gittiği yöne baksın.
    if (step.x.abs() > 0.001) {
      scale.x = step.x < 0 ? -1 : 1;
    }
  }
}

/// Kapıda bekleyen figür. Yürümez, sadece durur ve bakar.
class _Watcher extends SpriteAnimationComponent {
  _Watcher({required SpriteAnimation animation, required super.position})
      : super(
          animation: animation,
          size: Vector2.all(OfficeGame.tile),
          priority: 3,
        );

  @override
  void onMount() {
    super.onMount();
    playing = false;
    scale.x = -1;
  }
}
