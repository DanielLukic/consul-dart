part of 'desktop.dart';

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

  bool get isUp {
    final self = this;
    return self is MouseButtonEvent && self.kind.isUp;
  }
}

MouseWheelKind mouseWheelKind(bool down) =>
    down ? MouseWheelKind.wheelDown : MouseWheelKind.wheelUp;

enum MouseWheelKind {
  wheelDown,
  wheelUp,
}

class MouseWheelEvent extends MouseEvent {
  final MouseWheelKind kind;

  const MouseWheelEvent(this.kind, int x, int y, [int? xAbs, int? yAbs]) : super(x, y, xAbs, yAbs);

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

  bool get isUp =>
      this == MouseButtonKind.lmbUp ||
      this == MouseButtonKind.mmbUp ||
      this == MouseButtonKind.rmbUp;
}

class MouseButtonEvent extends MouseEvent {
  final MouseButtonKind kind;

  const MouseButtonEvent(this.kind, int x, int y, [int? xAbs, int? yAbs]) : super(x, y, xAbs, yAbs);

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

  const MouseMotionEvent(this.kind, int x, int y, [int? xAbs, int? yAbs]) : super(x, y, xAbs, yAbs);

  @override
  MouseEvent relativeTo(AbsolutePosition p) =>
      MouseMotionEvent(kind, xAbs - p.x, yAbs - p.y, xAbs, yAbs);

  @override
  String toString() => "$kind,$x,$y,$xAbs,$yAbs";
}

typedef MouseHandler = Function(MouseEvent);
