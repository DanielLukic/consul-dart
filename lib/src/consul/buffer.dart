part of 'desktop.dart';

/// Generic char code buffer for pre-rendering a "screen" before dumping it into the console.
class Buffer {
  int width;
  int height;
  List<List<Cell>> _buffer;

  /// Create a new buffer with the given [width] and [height] as initial size.
  Buffer(this.width, this.height)
      : _buffer = List.generate(height, (it) => List.filled(width, Cell(0)));

  /// Resize the buffer to the given [width] and [height], dropping all content if the size actually
  /// changed.
  update(int width, int height) {
    if (this.width == width && this.height == height) return;
    this.width = width;
    this.height = height;
    _buffer = List.generate(height, (it) => List.filled(width, Cell(0)));
  }

  /// Fill the buffer with the given character code.
  fill(int charCode) {
    for (var i = 0; i < _buffer.length; i++) {
      for (var j = 0; j < _buffer[i].length; j++) {
        _buffer[i][j] = Cell(charCode);
      }
    }
  }

  /// Fill the buffer with the given cell, allowing for ANSI sequences.
  fillWithCell(Cell cell) {
    for (var i = 0; i < _buffer.length; i++) {
      for (var j = 0; j < _buffer[i].length; j++) {
        _buffer[i][j] = cell;
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

      // determine if end of replaced area is visible. if so, we need to "continue" any potential
      // ansi sequences "underneath".
      _preserveAnsi(target, x + cells.length);

      final newAnsi = StringBuffer(x > 0 ? ansiReset : "");

      for (var j = 0; j < cells.length; j++) {
        var cell = cells[j];

        // collect all ansi codes outside the left boundary:
        if (x + j < 0) newAnsi.write(cell.toAnsiOnly());

        // after the right boundary just ignore everything:
        if (x + j < 0 || x + j >= target.length) continue;

        // copy the new cell now, but note the potential modifications below!
        target[x + j] = cell;

        // for the first visible cell, add all collected ansi codes:
        if (newAnsi.isNotEmpty) {
          target[x + j] = cell.withBeforePrepended(newAnsi.toString());
          newAnsi.clear();
        }

        // for the last cell enforce an ansi reset always:
        if (j == cells.length - 1) {
          target[x + j] = target[x + j].withReset();
        }

        // note that both above modifications may apply to the same cell if the copied are is
        // only one char wide.
      }
    }
  }

  void _preserveAnsi(List<Cell> line, int upUntil) {
    // nothing to do if line is replaced until the end:
    if (upUntil >= line.length) return;

    // collect the ansi that is about to be broken. it will be placed at the end of the
    // replaced area to have it "continue" underneath.
    final oldAnsi = StringBuffer();
    for (var o = 0; o < upUntil; o++) {
      oldAnsi.write(line[o].toAnsiOnly());
    }
    line[upUntil] = line[upUntil].withBeforePrepended(oldAnsi.toString());
  }

  /// Return this buffer as a String with '\n' as line separator for dumping into the console.
  String frame() => _buffer.map((line) => line.join()).join('\n');
}

/// Represents an ansi cell: A character, plus an optional ansi sequence before it and a "reset
/// ansi after me" flag.
class Cell {
  final int charCode;
  final String before;
  final bool reset;

  Cell(this.charCode, {this.before = '', this.reset = false});

  /// Add more ansi sequence to this cell, before any existing.
  Cell withBeforePrepended(String moreBefore) =>
      Cell(charCode, before: moreBefore + before, reset: reset);

  /// Add more ansi sequence to this cell, after any existing.
  Cell withBeforeExtended(String moreBefore) =>
      Cell(charCode, before: before + moreBefore, reset: reset);

  /// Mark this cell to reset any ansi style after it.
  Cell withReset() => Cell(charCode, before: before, reset: true);

  /// The character in this cell, without any ansi.
  String get char => String.fromCharCode(charCode);

  /// Provide the ansi of this cell only.
  String toAnsiOnly() => before + (reset ? ansiReset : "");

  /// Provide the actual representation of this cell for on-screen display: any ansi sequence,
  /// the character, and a potential reset after it.
  @override
  String toString() => before + char + (reset ? ansiReset : "");
}

extension on String {
  List<Cell> asCells() {
    final cells = <Cell>[];
    var scan = 0;
    String ansi = '';
    while (scan < length) {
      final open = ansiMatcher.matchAsPrefix(this, scan);
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

/// Helper for drawing [WindowOverlay]s.
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
