part of 'desktop.dart';

final _ansiReset = '\u001B[0m';
final _ansiMatcher = RegExp(r'\u001B\[[^m]+m');

String _ansiStripped(String it) => it.replaceAll(_ansiMatcher, '');

/// Generic char code buffer for pre-rendering a "screen" before dumping it into the console.
class Buffer {
  int width;
  int height;
  List<List<Cell>> _buffer;

  /// Create a new buffer with the given [width] and [height] as initial size.
  Buffer(this.width, this.height)
      : _buffer = List.generate(height, (index) => List.filled(width, Cell(0), growable: true));

  /// Resize the buffer to the given [width] and [height], dropping all content if the size actually
  /// changed.
  update(int width, int height) {
    if (this.width == width && this.height == height) return;
    this.width = width;
    this.height = height;
    _buffer = List.generate(height, (index) => List.filled(width, Cell(0), growable: true));
  }

  /// Fill the buffer with the given character code.
  fill(int charCode) {
    for (var i = 0; i < _buffer.length; i++) {
      for (var j = 0; j < _buffer[i].length; j++) {
        _buffer[i][j] = Cell(charCode);
      }
    }
  }

  /// Draw [data], given as a String with '\n' as line separators, at the position [x], [y] into the
  /// buffer.
  drawBuffer(int x, int y, String data) {
    final lines = data.split("\n");
    for (var i = 0; i < lines.length; i++) {
      if (y + i < 0 || y + i >= _buffer.length) continue;

      final target = _buffer[y + i];
      final cells = lines[i].asCells();
      final ansi = StringBuffer();

      for (var j = 0; j < cells.length; j++) {
        // collect all ansi codes outside the left boundary:
        if (x + j < 0) {
          ansi.write(cells[j].before);
          ansi.write(cells[j].after);
        }

        // after the right boundary just ignore everything:
        if (x + j < 0 || x + j >= target.length) continue;

        // for the first visible cell, add all collected ansi codes:
        if (ansi.isNotEmpty) {
          target[x + j] = cells[j].withBeforeExtended(ansi.toString());
          ansi.clear();
        } else
        // for all following cells just copy:
        {
          target[x + j] = cells[j];
        }

        // for the last cell enforce an ansi reset always:
        if (j == cells.length - 1) {
          target[x + j] = target[x + j].withReset();
        }
      }
    }
  }

  /// Return this buffer as a String with '\n' as line separator for dumping into the console.
  String frame() => _buffer.map((line) => line.join()).join('\n');
}

class Cell {
  final int charCode;
  final String before;
  final String after;
  final bool reset;

  Cell(this.charCode, {this.before = '', this.after = '', this.reset = false});

  Cell withBeforeExtended(String moreBefore) =>
      Cell(charCode, before: before + moreBefore, after: after, reset: reset);

  Cell withReset() => Cell(charCode, before: before, after: after, reset: true);

  @override
  String toString() => before + String.fromCharCode(charCode) + after + (reset ? _ansiReset : "");
}

extension on String {
  List<Cell> asCells() {
    final cells = <Cell>[];
    var scan = 0;
    String ansi = '';
    while (scan < length) {
      final open = _ansiMatcher.matchAsPrefix(this, scan);
      if (open != null) {
        ansi += open.group(0) ?? '';
        scan = open.end;
      } else {
        var char = codeUnitAt(scan++);
        cells.add(Cell(char, before: ansi));
        ansi = "";
      }
    }
    return cells;
  }
}

class VirtualBuffer extends OverlayBuffer {
  final Buffer _targetBuffer;
  final AbsolutePosition _offset;
  final Size _size;

  @override
  int get height => _size.height;

  @override
  int get width => _size.width;

  VirtualBuffer(this._targetBuffer, this._offset, this._size);

  @override
  draw(int x, int y, String buffer) {
    _targetBuffer.drawBuffer(x + _offset.x, y + _offset.y, buffer);
  }
}
