import 'dart:async';
import 'dart:math';

import 'package:console/console.dart';
import 'package:consul/consul.dart';

/// Create or restore a Game Of Life window.
gameOfLife(Desktop desktop) {
  final running = desktop.findWindow("gol");
  if (running != null) {
    desktop.raiseWindow(running);
  } else {
    final window = Window(
      "gol",
      "Game Of Life",
      size: WindowSize.min(Size(32, 16)),
      position: RelativePosition.fromTopRight(xOffset: -2, yOffset: 1),
    );
    desktop.openWindow(window);

    var gol = GOL(window.width * 2, window.height * 4);

    void update() {
      window.dispose("tick");

      if (window.state == WindowState.closed) return;
      if (window.state == WindowState.minimized) return;

      final golWidth = window.width * 2;
      final golHeight = window.height * 4;
      if (gol.width != golWidth || gol.height != golHeight) {
        gol = GOL(golWidth, golHeight);
      }
      window.redrawBuffer = gol.render;
      window.autoDispose(
        "tick",
        Timer.periodic(FPS(30).milliseconds, (timer) {
          gol.iterate();
          window.requestRedraw();
        }),
      );
    }

    window.onSizeChanged = update;
    window.onStateChanged = update;
    window.onMouseEvent = (it) {
      eventDebugLog.add("???");
      gol.set(it.x * 2, it.y * 4);
      return null;
    };
  }
}

class GOL {
  final Random _random = Random();
  final int width;
  final int height;
  final List<List<int>> _grid;
  final DrawingCanvas _canvas;

  // start pattern to be placed at center:
  final _start = [
    "x x         ",
    "  x         ",
    "    x       ",
    "    x x     ",
    "    x xx    ",
    "      x     ",
  ];

  GOL(this.width, this.height)
      : _grid = List.generate(height, (i) => List.filled(width, 0)),
        _canvas = DrawingCanvas(width, height) {
    initStartPatternAtCenter();
  }

  void set(int x, int y) {
    eventDebugLog.add("set $x $y");
    for (var i = 0; i < 5; i++) {
      x += _random.nextInt(7) - 3;
      y += _random.nextInt(7) - 3;
      if (x < 0 || x >= width) return;
      if (y < 0 || y >= height) return;
      _grid[y][x] = 1;
    }
  }

  void initStartPatternAtCenter() {
    final x = width ~/ 2;
    final y = height ~/ 2;
    for (var i = 0; i < _start.length; i++) {
      final line = _start[i];
      for (var j = 0; j < line.length; j++) {
        _grid[y + i][x + j] = line[j] == "x" ? 1 : 0;
      }
    }
  }

  void iterate() {
    // restart on full die off:
    if (_grid.every((element) => element.every((element) => element == 0))) {
      initStartPatternAtCenter();
    }

    // change a random pixel every iteration, to avoid static patterns:
    final x = _random.nextInt(width);
    final y = _random.nextInt(height);
    _grid[y][x] = 1;

    // compute the next generation:
    var next = List.generate(_grid.length, (i) => List.filled(_grid[0].length, 0));
    for (var i = 0; i < _grid.length; i++) {
      for (var j = 0; j < _grid[0].length; j++) {
        var neighbors = _countNeighbors(i, j);

        if (_grid[i][j] == 1) {
          if (neighbors < 2 || neighbors > 3) {
            next[i][j] = 0;
          } else {
            next[i][j] = 1;
          }
        } else {
          if (neighbors == 3) {
            next[i][j] = 1;
          }
        }
      }
    }

    // copy next into grid:
    for (var i = 0; i < _grid.length; i++) {
      for (var j = 0; j < _grid[0].length; j++) {
        _grid[i][j] = next[i][j];
      }
    }

    // draw into buffer once per iteration:
    _canvas.clear();
    for (var i = 0; i < _grid.length; i++) {
      for (var j = 0; j < _grid[0].length; j++) {
        if (_grid[i][j] == 1) _canvas.set(j, i);
      }
    }
  }

  int _countNeighbors(int x, int y) {
    var count = 0;
    for (var i = -1; i <= 1; i++) {
      for (var j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue;

        var row = (x + i + _grid.length) % _grid.length;
        var col = (y + j + _grid[0].length) % _grid[0].length;
        count += _grid[row][col];
      }
    }
    return count;
  }

  String render() => _canvas.frame();
}
