part of 'desktop.dart';

typedef MouseHandler = Function(MouseEvent);

/// Sealed type representing the various mouse events. Fields [x] and [y] are potentially relative
/// to the target object ([Window] only for now). [xAbs] and [yAbs] will hold the original event
/// position.
sealed class MouseEvent {
  final int x;
  final int y;
  final int xAbs;
  final int yAbs;

  const MouseEvent(this.x, this.y, [int? xAbs, int? yAbs])
      : xAbs = xAbs ?? x,
        yAbs = yAbs ?? y;

  MouseEvent relativeTo(AbsolutePosition p);

  bool get isDown {
    final self = this;
    return self is MouseButtonEvent && self.kind.isDown;
  }

  bool get isUp {
    final self = this;
    return self is MouseButtonEvent && self.kind.isUp;
  }

  bool get isWheelDown {
    final self = this;
    return self is MouseWheelEvent && self.kind.isDown ? true : false;
  }

  bool get isWheelUp {
    final self = this;
    return self is MouseWheelEvent && self.kind.isUp ? true : false;
  }
}

MouseWheelKind mouseWheelKind(bool down) =>
    down ? MouseWheelKind.wheelDown : MouseWheelKind.wheelUp;

enum MouseWheelKind {
  wheelDown,
  wheelUp,
}

extension MouseWheelKindExtension on MouseWheelKind {
  bool get isDown => this == MouseWheelKind.wheelDown;

  bool get isUp => this == MouseWheelKind.wheelUp;
}

class MouseWheelEvent extends MouseEvent {
  final MouseWheelKind kind;

  const MouseWheelEvent(this.kind, int x, int y, [int? xAbs, int? yAbs])
      : super(x, y, xAbs, yAbs);

  @override
  MouseEvent relativeTo(AbsolutePosition p) =>
      MouseWheelEvent(kind, xAbs - p.x, yAbs - p.y, xAbs, yAbs);

  @override
  String toString() => "$kind,$x,$y,$xAbs,$yAbs";
}

enum MouseButtonKind {
  lmbDown,
  lmbUp,
  mmbDown,
  mmbUp,
  rmbDown,
  rmbUp,
  ;

  bool get isDown =>
      this == MouseButtonKind.lmbDown ||
      this == MouseButtonKind.mmbDown ||
      this == MouseButtonKind.rmbDown;

  bool get isUp =>
      this == MouseButtonKind.lmbUp ||
      this == MouseButtonKind.mmbUp ||
      this == MouseButtonKind.rmbUp;
}

class MouseButtonEvent extends MouseEvent {
  final MouseButtonKind kind;

  const MouseButtonEvent(this.kind, int x, int y, [int? xAbs, int? yAbs])
      : super(x, y, xAbs, yAbs);

  @override
  MouseEvent relativeTo(AbsolutePosition p) =>
      MouseButtonEvent(kind, xAbs - p.x, yAbs - p.y, xAbs, yAbs);

  @override
  String toString() => "$kind,$x,$y,$xAbs,$yAbs";
}

enum MouseMotionKind {
  lmb,
  mmb,
  rmb,
}

class MouseMotionEvent extends MouseEvent {
  final MouseMotionKind kind;

  const MouseMotionEvent(this.kind, int x, int y, [int? xAbs, int? yAbs])
      : super(x, y, xAbs, yAbs);

  @override
  MouseEvent relativeTo(AbsolutePosition p) =>
      MouseMotionEvent(kind, xAbs - p.x, yAbs - p.y, xAbs, yAbs);

  @override
  String toString() => "$kind,$x,$y,$xAbs,$yAbs";
}

extension MouseEventExtensions on MouseEvent {
  /// Shortcut to handle a wheel up event without triggering an
  /// [OngoingMouseAction].
  OngoingMouseAction? onWheelUp(OnMouseEvent handler) {
    final it = this;
    if (it is MouseWheelEvent && it.kind == MouseWheelKind.wheelUp) {
      return handler(it);
    }
    return null;
  }

  /// Shortcut to handle a wheel down event without triggering an
  /// [OngoingMouseAction].
  OngoingMouseAction? onWheelDown(OnMouseEvent handler) {
    final it = this;
    if (it is MouseWheelEvent && it.kind == MouseWheelKind.wheelDown) {
      return handler(it);
    }
    return null;
  }

  /// Shortcut to handle a wheel event without triggering an
  /// [OngoingMouseAction].
  OngoingMouseAction? onWheel(OnMouseEvent handler) =>
      this is MouseWheelEvent ? handler(this) : null;
}
