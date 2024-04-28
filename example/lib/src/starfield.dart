import 'dart:async';
import 'dart:math';

import 'package:dart_consul/common.dart';
import 'package:dart_consul/dart_consul.dart';
import 'package:dart_minilog/dart_minilog.dart';

final _width = 64;
final _height = 20;
late final Window _window;

/// Draw a horizontally moving starfield in a window.
starfield(Desktop desktop) {
  final running = desktop.findWindow("stars");
  if (running != null) {
    desktop.raiseWindow(running);
  } else {
    _window = Window(
      "stars",
      "✷✸✹ Stars ✹✸✷",
      position: RelativePosition.fromTopLeft(xOffset: 2, yOffset: 1),
      size: WindowSize.fixed(Size(_width, _height)),
    );

    _create();

    _window.onStateChanged.add(_update);
    _update();

    _window.onKey('k', description: 'Move up', action: () => _player.dy = -1);
    _window.onKey('j', description: 'Move down', action: () => _player.dy = 1);
    _window.onKey('<Space>',
        description: 'Fire weapon', action: () => _player.fire = 1);

    desktop.openWindow(_window);
  }
}

void _create() {
  final buffer = Buffer(_width, _height);
  _starfield = _Starfield(_width * 2, _height * 4);
  _player = _Player(_width, _height);
  _window.redrawBuffer = () {
    buffer.drawBuffer(0, 0, _starfield.render());
    _player.renderInto(buffer);
    for (final p in _entities) {
      p.renderInto(buffer);
    }
    return buffer.frame();
  };
}

void _update() {
  _window.dispose("tick");
  _paused = _window.isClosed || _window.isMinimized;
  if (_paused) return;

  final tick = Timer.periodic(FPS(60).milliseconds, (timer) {
    _spawner.tick();
    _starfield.tick();
    _player.tick();
    for (final p in _entities) {
      p.tick();
    }
    _entities.removeWhere((e) => e.expired);
    _window.requestRedraw();
  });

  _window.autoDispose("tick", tick);
}

bool _paused = false;
late final _Starfield _starfield;
late final _Player _player;

final _spawner = _Spawner();
final _entities = <_Entity>[];

abstract interface class _Particle {
  bool get expired;

  tick();

  drawInto(ColorCanvas canvas);
}

class _Explosion implements _Particle {
  double _x;
  double _y;
  double _dx;
  double _dy;
  double _intensity = 1;

  _Explosion(this._x, this._y, this._dx, this._dy);

  @override
  var expired = false;

  @override
  tick() {
    _x += _dx;
    _y += _dy;
    _dx *= 0.9;
    _dy *= 0.9;
    _intensity *= 0.9;
    if (_intensity < 0.1) expired = true;
  }

  @override
  drawInto(ColorCanvas canvas) {
    final color = switch (_intensity) {
      < 0.2 => gray,
      < 0.5 => red,
      < 0.75 => yellow,
      _ => whiteBright,
    };
    canvas.set(_x.round(), _y.round(), color);
  }
}

class _Starfield {
  final rnd = Random(0);
  final List<_Star> stars = [];
  final List<_Particle> _particles = [];

  int width;

  int height;

  ColorCanvas canvas;

  _Starfield(this.width, this.height) : canvas = ColorCanvas(width, height) {
    _placeStarsRandomly();
  }

  void _placeStarsRandomly() {
    final count = ((width * height) ~/ 200).clamp(50, 100);
    while (stars.length < count) {
      final star = _Star();
      star.place(width, height, rnd);
      stars.add(star);
    }
  }

  addExplosionAt(double x, double y) {
    for (var i = 0; i < 10; i++) {
      final dir = rnd.nextDouble() * 2 * pi;
      final dx = sin(dir) * 3;
      final dy = cos(dir) * 3;
      _particles.add(_Explosion(x, y, dx, dy));
    }
    for (var i = 0; i < 10; i++) {
      final dir = rnd.nextDouble() * 2 * pi;
      final dx = sin(dir) * 3;
      final dy = cos(dir) * 3;
      _particles.add(_Explosion(x + dx * 3, y + dy * 3, dx, dy));
    }
    for (var i = 0; i < 10; i++) {
      final dir = rnd.nextDouble() * 2 * pi;
      final dx = sin(dir) * 2;
      final dy = cos(dir) * 2;
      _particles.add(_Explosion(x + dx * 3, y + dy * 3, dx, dy));
    }
  }

  tick() {
    for (final star in stars) {
      star.tick();
      if (star.x < 0) star.reset(width, height, rnd);
    }
    for (final p in _particles) {
      p.tick();
    }
    _particles.removeWhere((e) => e.expired);
  }

  String render() {
    canvas.clear();
    for (final star in stars) {
      star.drawInto(canvas);
    }
    for (final p in _particles) {
      p.drawInto(canvas);
    }
    return canvas.frame();
  }
}

class _Star {
  double x = 0, y = 0, vx = 0, vy = 0;
  double _blinky = 0;

  place(int width, int height, Random rnd) {
    x = rnd.nextInt(width).toDouble();
    y = rnd.nextInt(height ~/ 4).toDouble() * 4 + 2;
    vx = rnd.nextDouble() * 4;
    vy = 0.0;
    _blinky = rnd.nextDouble();
  }

  reset(int width, int height, Random rnd) {
    place(width, height, rnd);
    x = width.toDouble() + 1;
  }

  tick() {
    x -= vx / 10;
    _blinky += 0.005;
    if (_blinky > 1) _blinky -= 1;
  }

  drawInto(ColorCanvas canvas) {
    final c = switch (_blinky) {
      < 0.1 => yellow,
      _ => gray,
    };
    var xx = x.round();
    var yy = y.round();
    if (vx < 0.5) {
      canvas.set(xx, yy, c);
    } else if (vx < 1.5) {
      canvas.set(xx + 0, yy + 0);
      canvas.set(xx + 1, yy + 0);
      canvas.set(xx + 0, yy + 1);
      canvas.set(xx + 1, yy + 1);
    } else {
      canvas.set(xx + 0, yy + 0);
      canvas.set(xx - 1, yy + 0);
      canvas.set(xx + 1, yy + 0);
      canvas.set(xx + 0, yy - 1);
      canvas.set(xx + 0, yy + 1);
    }
  }
}

class _Player {
  double dx = 0;
  double dy = 0;
  double fire = 0;

  final int _width;
  final int _height;

  _Player(this._width, this._height);

  late double _x = _width / 8;
  late double _y = _height / 2;

  double _frame = 0;
  double _firing = 0;

  final _Weapon _weapon = _Weapon.gun;

  void tick() {
    _frame += 0.2;
    if (_frame >= _manta.length) _frame -= _manta.length;

    if (fire > 0) {
      final wasNotFiring = _firing < 0.5;
      _firing += 0.2;
      if (_firing >= 1.0) {
        _firing -= 1.0;
      } else if (_firing >= 0.5 && !wasNotFiring) {
        _addProjectile(_x + 3, _y, weapon: _weapon);
      }
      fire -= 0.2;
    }
    _x += dx / 5;
    _y += dy / 5;
    dx = dx - dx / 10;
    dy = dy - dy / 10;
  }

  void renderInto(Buffer buffer) {
    final x = _x.round();
    final y = _y.round();

    final frame = _manta[_frame.toInt()];
    buffer.drawBuffer(x - 3, y - 1, frame);

    final exhaust = buffer.grab(x - 3, y, 2, 1).stripped().yellow();
    buffer.drawBuffer(x - 3, y, exhaust);
  }
}

final _manta = [_manta1, _manta2, _manta3, _manta4, _manta5]
    .map((e) => e.split('\n').map((e) => e.gray()).join('\n'))
    .toList();

final _manta1 = [
  r'  ▗▄ ▖~ ',
  r'|:█████▶',
  r'  ▝▀ ▘~ ',
].join('\n');
final _manta2 = [
  r'  ▗▄ ▖~ ',
  r':-█████▶',
  r'  ▝▀ ▘~ ',
].join('\n');
final _manta3 = [
  r'  ▗▄ ▖~ ',
  r'-◦█████▶',
  r'  ▝▀ ▘~ ',
].join('\n');
final _manta4 = [
  r'  ▗▄ ▖~ ',
  r'◦|█████▶',
  r'  ▝▀ ▘~ ',
].join('\n');
final _manta5 = [
  r'  ▗▄ ▖~ ',
  r'||█████▶',
  r'  ▝▀ ▘~ ',
].join('\n');

void _addProjectile(double x, double y, {_Weapon weapon = _Weapon.gun}) {
  final it = switch (weapon) {
    _Weapon.gun => _GunProjectile(_width, _height, x, y),
  };
  _entities.add(it);
}

enum _Weapon {
  gun,
}

abstract interface class _Entity {
  bool get expired;

  void tick();

  void renderInto(Buffer buffer);
}

bool _isOutside(double x, double y) {
  final xx = x.round();
  final yy = y.round();
  if (xx < -1 || yy < -1) return true;
  if (xx > _width) return true;
  if (yy > _height) return true;
  return false;
}

class _GunProjectile implements _Entity {
  double dx = 4;
  double dy = 0;

  final int _width;
  final int _height;

  _GunProjectile(this._width, this._height, this._x, this._y);

  late double _x = _width / 4;
  late double _y = _height / 2;

  @override
  bool expired = false;

  @override
  void tick() {
    _x += dx / 5;
    _y += dy / 5;

    final hits = _enemies.where((e) => e.isHit(_x, _y));
    for (final e in hits) {
      e.onHit();
    }

    if (_isOutside(_x, _y)) expired = true;
  }

  @override
  void renderInto(Buffer buffer) {
    final x = _x.round();
    final y = _y.round();
    buffer.drawBuffer(x, y, '●'.yellow());
  }
}

Iterable<_EnemyEntity> get _enemies => _entities.whereType<_EnemyEntity>();

enum _Enemy {
  snaily,
}

class _Spawner {
  final _rnd = Random(0);

  int _ticks = 0;

  int _nextWaveId = 0;
  double _releaseWave = 0;
  late double _releaseY;
  late _Enemy _waveEnemy;

  bool get _hasActiveEnemies => _entities.whereType<_EnemyEntity>().isNotEmpty;

  void tick() {
    if (_releaseWave > 0) {
      _onReleaseWave();
    } else if (!_hasActiveEnemies) {
      _onIdleTick();
    }
  }

  void _onReleaseWave() {
    final before = _releaseWave.toInt();
    _releaseWave -= 0.05;
    if (_releaseWave.toInt() != before) {
      logInfo('spawn enemy @ $before');
      final waveIndex = _entities
          .whereType<_EnemyEntity>()
          .count((e) => e.waveId == _nextWaveId);
      final enemy = switch (_waveEnemy) {
        _Enemy.snaily => _Snaily(_width + 2, _releaseY, _nextWaveId, waveIndex),
      };
      _entities.add(enemy);
      logInfo(_entities.map((e) => e.runtimeType));
    }
    if (_releaseWave <= 0) {
      _releaseWave = 0;
      _nextWaveId++;
    }
  }

  void _onIdleTick() {
    _ticks++;
    if (_ticks >= 120) {
      _releaseWave = 6;
      _waveEnemy = _Enemy.snaily;
      _releaseY = _rnd.nextInt(_height ~/ 2) + _height / 4;
      _ticks = 0;
    }
  }
}

abstract interface class _EnemyEntity {
  int get waveId;

  bool isHit(double x, double y);

  void onHit();
}

class _Snaily implements _Entity, _EnemyEntity {
  double dx = -1;
  double dy = 0;

  @override
  final int waveId;
  final int _waveIndex;
  final double _baseY;

  _Snaily(
    this._x,
    this._y,
    this.waveId,
    this._waveIndex,
  ) : _baseY = _y;

  double _frame = 0;
  double _x;
  double _y;

  @override
  bool isHit(double x, double y) {
    final dx = (_x - x).abs();
    final dy = (_y - y).abs();
    return dx <= 1 && dy <= 1;
  }

  @override
  void onHit() {
    _starfield.addExplosionAt(_x.round() * 2, _y.round() * 4);
    expired = true;
  }

  @override
  bool expired = false;

  @override
  void tick() {
    _frame += 0.2;
    if (_frame >= _snaily.length) _frame -= _snaily.length;

    _x += dx / 5;
    _y = _baseY + sin(_x * pi * 6 / _width) * 4;
    if (_x < -3) expired = true;
  }

  @override
  void renderInto(Buffer buffer) {
    final x = _x.round();
    final y = _y.round();
    final frame = _snaily[_frame.toInt()];
    buffer.drawBuffer(x - 1, y - 1, frame);
  }
}

final _snaily = [
  _snaily1,
  _snaily2,
  _snaily3,
  _snaily4,
  _snaily5,
  _snaily6,
  _snaily7,
  _snaily8,
  _snaily9,
  _snailyA,
].map((e) => e.split('\n').map((e) => e.blue()).join('\n')).toList();

final _snaily1 = [
  r'◯◎◎',
  r'◯ ◎',
  r'◎◎◎',
].join('\n');
final _snaily2 = [
  r'◯◯◎',
  r'◯ ◎',
  r'◎◎◎',
].join('\n');
final _snaily3 = [
  r'◯◯◯',
  r'◎ ◎',
  r'◎◎◎',
].join('\n');
final _snaily4 = [
  r'◯◯◯',
  r'◎ ◯',
  r'◎◎◎',
].join('\n');
final _snaily5 = [
  r'◎◯◯',
  r'◎ ◯',
  r'◎◎◯',
].join('\n');
final _snaily6 = [
  r'◎◎◯',
  r'◎ ◯',
  r'◎◯◯',
].join('\n');
final _snaily7 = [
  r'◎◎◎',
  r'◎ ◯',
  r'◯◯◯',
].join('\n');
final _snaily8 = [
  r'◎◎◎',
  r'◯ ◎',
  r'◯◯◯',
].join('\n');
final _snaily9 = [
  r'◎◎◎',
  r'◯ ◎',
  r'◯◯◎',
].join('\n');
final _snailyA = [
  r'◯◎◎',
  r'◯ ◎',
  r'◯◎◎',
].join('\n');

extension<T> on Iterable<T> {
  int count(bool Function(T) pred) => where(pred).length;
}
