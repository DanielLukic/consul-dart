part of 'desktop.dart';

typedef Callback = void Function();

extension NotifyAllCallbacks on Set<Callback> {
  void notifyAll() => forEach((e) => e());
}

typedef KeyMap = Map<String, Iterable<(String, String)>>;

/// Window buffers are simply [String]s with newlines after every row.
/// Windows can return `null` in their [Window.redrawBuffer] method to
/// indicate "no content atm". This typedef captures the function signature.
typedef OnRedraw = String? Function();

typedef OnMouseEvent = OngoingMouseAction? Function(MouseEvent);

extension type FPS(int fps) {
  Duration get milliseconds => Duration(milliseconds: 1000 ~/ fps);
}

enum RelativePositionMode {
  autoCentered,
  fromStart,
  fromEnd,
}

/// Represents the various types available for positioning items. For now
/// this is used for [Window]s only.
sealed class Position {
  const Position();

  static const AbsolutePosition topLeft = AbsolutePosition(0, 0);

  static const unsetInitially = UnsetInitially();

  /// Turn any kind of position into an [AbsolutePosition]. This is used in many
  /// places in which a defined reference position is required.
  AbsolutePosition toAbsolute(Size desktop, Size window);

  /// Create a new [Position], with the given [dx] and [dy] added.
  Position moved(int dx, int dy);
}

/// Special position to represent "not positioned, yet". Will be resolved
/// dynamically when needed. By default, falls back to "center" in
/// [toAbsolute] and to "zero" in [moved].
class UnsetInitially extends Position {
  const UnsetInitially();

  @override
  AbsolutePosition toAbsolute(Size desktop, Size window) {
    final x = (desktop.width - window.width) ~/ 2;
    final y = (desktop.height - window.height) ~/ 2;
    return AbsolutePosition(x, y);
  }

  @override
  Position moved(int dx, int dy) => AbsolutePosition(dx, dy);

  @override
  String toString() => "Unset";
}

/// Position relative to "something". Uses [RelativePositionMode] and offsets
/// to position elements somewhat dynamically.
class RelativePosition extends Position {
  final RelativePositionMode xMode;
  final RelativePositionMode yMode;
  final int xOffset;
  final int yOffset;

  const RelativePosition(this.xMode, this.yMode, this.xOffset, this.yOffset);

  const RelativePosition.autoCentered()
      : this(RelativePositionMode.autoCentered,
            RelativePositionMode.autoCentered, 0, 0);

  const RelativePosition.autoCenterX(RelativePositionMode yMode,
      {int yOffset = 0})
      : this(RelativePositionMode.autoCentered, yMode, 0, yOffset);

  const RelativePosition.autoCenterY(RelativePositionMode xMode,
      {int xOffset = 0})
      : this(xMode, RelativePositionMode.autoCentered, xOffset, 0);

  const RelativePosition.fromTopRight({int xOffset = 0, int yOffset = 0})
      : this(RelativePositionMode.fromEnd, RelativePositionMode.fromStart,
            xOffset, yOffset);

  const RelativePosition.fromTopLeft({int xOffset = 0, int yOffset = 0})
      : this(RelativePositionMode.fromStart, RelativePositionMode.fromStart,
            xOffset, yOffset);

  const RelativePosition.fromBottomRight({int xOffset = 0, int yOffset = 0})
      : this(RelativePositionMode.fromEnd, RelativePositionMode.fromEnd,
            xOffset, yOffset);

  const RelativePosition.fromBottomLeft({int xOffset = 0, int yOffset = 0})
      : this(RelativePositionMode.fromStart, RelativePositionMode.fromEnd,
            xOffset, yOffset);

  const RelativePosition.fromBottom({int xOffset = 0, int yOffset = 0})
      : this(RelativePositionMode.autoCentered, RelativePositionMode.fromEnd,
            xOffset, yOffset);

  const RelativePosition.fromTop({int xOffset = 0, int yOffset = 0})
      : this(RelativePositionMode.autoCentered, RelativePositionMode.fromStart,
            xOffset, yOffset);

  @override
  AbsolutePosition toAbsolute(Size desktop, Size window) {
    final x = _applyMode(xMode, desktop.width, window.width, xOffset);
    final y = _applyMode(yMode, desktop.height, window.height, yOffset);
    return AbsolutePosition(x, y);
  }

  @override
  Position moved(int dx, int dy) =>
      RelativePosition(xMode, yMode, xOffset + dx, yOffset + dy);

  int _applyMode(
      RelativePositionMode mode, int desktop, int window, int offset) {
    return switch (mode) {
      RelativePositionMode.autoCentered => (desktop - window) ~/ 2 + offset,
      RelativePositionMode.fromStart => offset,
      RelativePositionMode.fromEnd => desktop - window + offset,
    };
  }

  @override
  String toString() =>
      "Relative(${xMode.name}:$xOffset,${yMode.name}:$yOffset)";
}

class AbsolutePosition extends Position {
  final int x;
  final int y;

  const AbsolutePosition(this.x, this.y);

  static const int autoCenter = -1000000;

  @override
  AbsolutePosition toAbsolute(Size desktop, Size window) => this;

  @override
  Position moved(int dx, int dy) => AbsolutePosition(x + dx, y + dy);

  @override
  String toString() => "Absolute($x,$y)";
}

/// Somewhat generic size type. Uses [autoSize] constant to represent
/// adaptive sizes.
///
/// TODO Revisit: Sealed instead
class Size {
  final int width;
  final int height;

  const Size(this.width, this.height);

  const Size.autoHeight(this.width) : height = autoSize;

  const Size.autoWidth(this.height) : width = autoSize;

  static const int autoSize = -1;

  static const Size zero = Size(0, 0);

  /// Special size to auto-limit (either min or max). Effectively same as [autoFill] for max. But
  /// for min will make sure titlebar and resize control is visible. However, these minimums are
  /// enforced always anyways. So this is mostly a formality. ‾\_('')_/‾
  static const Size autoLimit = Size(-1, -1);

  /// Auto fill the available space (desktop). Useful really only for max size.
  static const Size autoFill = Size(-2, -2);

  /// Limit `this` to the given [width] and [height]. Returns `this` if within these limits.
  Size limit(int width, int height) {
    if (this.width == width && this.height == height) return this;
    final w = min(this.width, width);
    final h = min(this.height, height);
    return Size(w, h);
  }

  /// Create new size, with [width] and [height] modified by [dx] and [dy].
  Size plus(int dx, int dy) => Size(width + dx, height + dy);

  @override
  String toString() => "Size(${width}x$height)";
}

/// [Window]s can have any combination of these flags set to change their
/// behavior.
enum WindowFlag {
  closeable,
  maximizable,
  minimizable,
  unmovable,
  resizable,
  undecorated,
}

/// Somewhat over-engineered class for representing current, min and max size
/// of a [Window].
class WindowSize {
  final Size current;
  final Size min;
  final Size max;

  @override
  String toString() => 'current=$current,min=$min,max=$max';

  const WindowSize(this.current, this.min, this.max);

  const WindowSize.max(this.current)
      : min = Size.autoLimit,
        max = current;

  const WindowSize.min(this.current)
      : min = current,
        max = Size.autoFill;

  const WindowSize.defaultMinMax(this.current)
      : min = Size.autoLimit,
        max = Size.autoFill;

  const WindowSize.fixed(this.current)
      : min = current,
        max = current;

  const WindowSize.fillScreen()
      : current = Size.autoFill,
        min = Size.autoFill,
        max = Size.autoFill;
}

/// Primary window state. [Window]s can be in exactly one primary state only.
enum WindowState {
  closed,
  maximized,
  minimized,
  normal,
}

/// Low-ceremony interface for drawing overlays into [Window]s.
abstract interface class WindowOverlay {
  void decorate(OverlayBuffer buffer);
}

/// TODO Why not [VirtualBuffer] only? Or [OverlayBuffer] only? Revisit!
abstract class OverlayBuffer {
  int get height;

  int get width;

  draw(int x, int y, String buffer);
}
