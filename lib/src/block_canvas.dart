class BlockCanvas {
  static const int xGrid = 2;
  static const int yGrid = 2;

  static final List<List<int>> _map = [
    [0x1, 0x2],
    [0x4, 0x8],
  ];

  static final Map<int, String> _unmap = {
    0x1: '▘',
    0x2: '▝',
    0x3: '▀',
    0x4: '▖',
    0x5: '▌',
    0x6: '▞',
    0x7: '▛',
    0x8: '▗',
    0x9: '▚',
    0xA: '▐',
    0xB: '▜',
    0xC: '▄',
    0xD: '▙',
    0xE: '▟',
    0xF: '█',
  };

  final int width;
  final int height;

  late List<int> content;

  BlockCanvas(this.width, this.height) {
    if (width % xGrid != 0) {
      throw Exception('Width must be a multiple of $xGrid!');
    }

    if (height % yGrid != 0) {
      throw Exception('Height must be a multiple of $yGrid!');
    }

    content = List<int>.filled(width * height ~/ (xGrid * yGrid), 0);
    _fillContent();
  }

  void _doIt(int x, int y, void Function(int coord, int mask) func) {
    if (!(x >= 0 && x < width && y >= 0 && y < height)) {
      return;
    }

    var nx = (x ~/ xGrid);
    var ny = (y ~/ yGrid);
    var coord = (nx + width ~/ xGrid * ny).toInt();
    var mask = _map[y % yGrid][x % xGrid];
    func(coord, mask);
  }

  void _fillContent([int byte = 0]) {
    for (var i = 0; i < content.length; i++) {
      content[i] = byte;
    }
  }

  void clear() {
    _fillContent();
  }

  void set(int x, int y) {
    _doIt(x, y, (coord, mask) {
      content[coord] |= mask;
    });
  }

  void unset(int x, int y) {
    _doIt(x, y, (coord, mask) {
      content[coord] &= ~mask;
    });
  }

  void toggle(int x, int y) {
    _doIt(x, y, (coord, mask) {
      content[coord] ^= mask;
    });
  }

  String frame([String delimiter = '\n']) {
    var result = [];
    for (var i = 0, j = 0; i < content.length; i++, j++) {
      if (j == width / xGrid) {
        result.add(delimiter);
        j = 0;
      }
      result.add(_unmap[content[i]] ?? " ");
    }
    result.add(delimiter);
    return result.join();
  }
}
