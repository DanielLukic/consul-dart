import 'dart:async';
import 'dart:math';

import 'package:console/console.dart';
import 'package:consul/consul.dart';

/// Create or restore a Game Of Life window.
gameOfLife(Desktop desktop) {
  final running = desktop.findWindow("gol");
  if (running != null) {
    desktop.restore(running);
  } else {
    final gol = GOL(60, 60);
    final window = Window(
      "gol",
      "Game Of Life",
      size: WindowSize.min(Size(30, 20)),
      position: RelativePosition.fromTopRight(xOffset: -2, yOffset: 1),
    );
    window.redrawBuffer = gol.render;
    desktop.openWindow(window);

    //window.onState.listen ...
    Timer.periodic(FPS(30).milliseconds, (timer) {
      gol.iterate();
      window.requestRedraw();
    });
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
    // make sure it never stops, we place a random pixel before every iteration. this will break up
    // static patterns constantly...
    final x = _random.nextInt(_grid[0].length);
    final y = _random.nextInt(_grid.length);
    _grid[x][y] = 1;

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
