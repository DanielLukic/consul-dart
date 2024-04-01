part of 'desktop.dart';

extension type FPS(int fps) {
  Duration get milliseconds => Duration(milliseconds: 1000 ~/ fps);
}

enum RelativePositionMode {
  autoCentered,
  fromStart,
  fromEnd,
}

sealed class Position {
  const Position();

  static const unsetInitially = UnsetInitially();

  AbsolutePosition toAbsolute(Size desktop, Size window);
}

class UnsetInitially extends Position {
  const UnsetInitially();

  @override
  AbsolutePosition toAbsolute(Size desktop, Size window) {
    final x = (desktop.width - window.width) ~/ 2;
    final y = (desktop.height - window.height) ~/ 2;
    return AbsolutePosition(x, y);
  }
}

class RelativePosition extends Position {
  final RelativePositionMode xMode;
  final RelativePositionMode yMode;
  final int xOffset;
  final int yOffset;

  const RelativePosition(this.xMode, this.yMode, this.xOffset, this.yOffset);

  const RelativePosition.autoCentered()
      : this(RelativePositionMode.autoCentered, RelativePositionMode.autoCentered, 0, 0);

  const RelativePosition.autoCenterX(RelativePositionMode yMode, {int yOffset = 0})
      : this(RelativePositionMode.autoCentered, yMode, 0, yOffset);

  const RelativePosition.autoCenterY(RelativePositionMode xMode, {int xOffset = 0})
      : this(xMode, RelativePositionMode.autoCentered, xOffset, 0);

  const RelativePosition.fromTopRight({int xOffset = 0, int yOffset = 0})
      : this(RelativePositionMode.fromEnd, RelativePositionMode.fromStart, xOffset, yOffset);

  const RelativePosition.fromTopLeft({int xOffset = 0, int yOffset = 0})
      : this(RelativePositionMode.fromStart, RelativePositionMode.fromStart, xOffset, yOffset);

  const RelativePosition.fromBottomRight({int xOffset = 0, int yOffset = 0})
      : this(RelativePositionMode.fromEnd, RelativePositionMode.fromEnd, xOffset, yOffset);

  const RelativePosition.fromBottomLeft({int xOffset = 0, int yOffset = 0})
      : this(RelativePositionMode.fromStart, RelativePositionMode.fromEnd, xOffset, yOffset);

  const RelativePosition.fromBottom({int xOffset = 0, int yOffset = 0})
      : this(RelativePositionMode.autoCentered, RelativePositionMode.fromEnd, xOffset, yOffset);

  @override
  AbsolutePosition toAbsolute(Size desktop, Size window) {
    final x = _applyMode(xMode, desktop.width, window.width, xOffset);
    final y = _applyMode(yMode, desktop.height, window.height, yOffset);
    return AbsolutePosition(x, y);
  }

  int _applyMode(RelativePositionMode mode, int desktop, int window, int offset) {
    return switch (mode) {
      RelativePositionMode.autoCentered => (desktop - window) ~/ 2 + offset,
      RelativePositionMode.fromStart => offset,
      RelativePositionMode.fromEnd => desktop - window + offset,
    };
  }
}

class AbsolutePosition extends Position {
  final int x;
  final int y;

  const AbsolutePosition(this.x, this.y);

  static const int autoCenter = -1000000;

  @override
  AbsolutePosition toAbsolute(Size desktop, Size window) => this;
}

class Size {
  final int width;
  final int height;

  const Size(this.width, this.height);

  static const Size autoFill = Size(-2, -2);
}
