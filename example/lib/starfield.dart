import 'dart:async';
import 'dart:math';

import 'package:dart_consul/dart_consul.dart';

/// Draw a horizontally moving starfield in a window.
starfield(Desktop desktop) {
  final running = desktop.findWindow("stars");
  if (running != null) {
    desktop.raiseWindow(running);
  } else {
    final window = Window(
      "stars",
      "✷✸✹ Stars ✹✸✷",
      position: RelativePosition.fromTopLeft(xOffset: 2, yOffset: 1),
      size: WindowSize.min(Size(40, 20)),
    );

    window.onSizeChanged = () => _update(window);
    window.onStateChanged = () => _update(window);
    window.onStateChanged();

    window.onKey("q", description: "Close window", action: () => desktop.closeWindow(window));

    desktop.openWindow(window);
  }
}

_Starfield? _starfield;

void _update(Window window) {
  window.dispose("tick");

  if (window.isClosed || window.isMinimized) return;

  final w = window.width * 2;
  final h = window.height * 4;
  if (_starfield?.width != w || _starfield?.height != h) {
    final starfield = _Starfield(window.width * 2, window.height * 4);
    _starfield = starfield;
    window.redrawBuffer = starfield.render;
  }

  final tick = Timer.periodic(FPS(60).milliseconds, (timer) {
    _starfield?.move();
    window.requestRedraw();
  });

  window.autoDispose("tick", tick);

  eventDebugLog.add("stars: ${_starfield?.width} x ${_starfield?.height}");
}

class _Starfield {
  final rnd = Random();
  final List<_Star> stars = [];

  int width;

  int height;

  DrawingCanvas canvas;

  _Starfield(this.width, this.height) : canvas = DrawingCanvas(width, height) {
    placeStarsRandomly();
  }

  void placeStarsRandomly() {
    final count = ((width * height) ~/ 200).clamp(50, 100);
    while (stars.length < count) {
      final star = _Star();
      star.place(width, height, rnd);
      stars.add(star);
    }
  }

  move() {
    for (var star in stars) {
      star.move();
      if (star.x < 0) star.reset(width, height, rnd);
    }
    _dirty = true;
  }

  var _dirty = false;

  String render() {
    if (_dirty) {
      if (canvas.width != width || canvas.height != height) {
        canvas = DrawingCanvas(width, height);
      } else {
        canvas.clear();
      }
      for (var star in stars) {
        star.draw(canvas);
      }
      _dirty = false;
    }
    return canvas.frame();
  }
}

class _Star {
  double x = 0, y = 0, vx = 0, vy = 0;

  place(int width, int height, Random rnd) {
    x = rnd.nextInt(width).toDouble();
    y = rnd.nextInt(height ~/ 4).toDouble() * 4 + 2;
    vx = (0.25 + rnd.nextDouble() * 5);
    vy = 0.0;
  }

  reset(int width, int height, Random rnd) {
    place(width, height, rnd);
    x = width.toDouble() + 1;
  }

  move() => x -= vx / 10;

  draw(DrawingCanvas canvas) {
    var xx = x.round();
    var yy = y.round();
    if (vx < 0.5) {
      canvas.set(xx, yy);
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
