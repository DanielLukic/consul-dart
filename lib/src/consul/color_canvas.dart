typedef CanvasColor = String Function(String);

class ColorCanvas {
  static final List<List<int>> _map = [
    [0x1, 0x8],
    [0x2, 0x10],
    [0x4, 0x20],
    [0x40, 0x80]
  ];

  final int width;
  final int height;
  late final List<int> content;
  late final List<CanvasColor?> coloring;

  ColorCanvas(this.width, this.height) {
    if (width % 2 != 0) {
      throw ArgumentError('Width must be a multiple of 2');
    }

    if (height % 4 != 0) {
      throw ArgumentError('Height must be a multiple of 4');
    }

    content = List<int>.filled(width * height ~/ 8, 0);
    coloring = List<CanvasColor?>.filled(width * height ~/ 8, null);

    clear();
  }

  void clear([int byte = 0]) {
    for (var i = 0; i < content.length; i++) {
      content[i] = byte;
      coloring[i] = null;
    }
  }

  void set(int x, int y, [CanvasColor? color]) {
    if (x < 0 || y < 0 || x >= width || y >= width) return;
    x = x.floor();
    y = y.floor();
    final nx = (x / 2).floor();
    final ny = (y / 4).floor();
    final index = (nx + width / 2 * ny).toInt();
    if (index < 0 || index >= content.length) return;
    final mask = _map[y % 4][x % 2];
    content[index] |= mask;
    coloring[index] = color;
  }

  String frame([String delimiter = '\n']) {
    var result = [];
    for (var i = 0, j = 0; i < content.length; i++, j++) {
      if (j == width / 2) {
        result.add(delimiter);
        j = 0;
      }

      if (content[i] == 0) {
        result.add(' ');
      } else {
        var char = String.fromCharCode(0x2800 + content[i]);
        final color = coloring[i];
        if (color != null) char = color(char);
        result.add(char);
      }
    }
    result.add(delimiter);
    return result.join();
  }
}
