part of 'desktop.dart';

sealed class MouseEvent {
  final int x;
  final int y;

  const MouseEvent(this.x, this.y);

  MouseEvent relativeTo(AbsolutePosition p);

  bool get isUp {
    final self = this;
    return self is MouseButtonEvent && self.kind.isUp;
  }
}

enum MouseWheelKind {
  wheelDown,
  wheelUp,
}

class MouseWheelEvent extends MouseEvent {
  final MouseWheelKind kind;

  const MouseWheelEvent(this.kind, super.x, super.y);

  @override
  MouseEvent relativeTo(AbsolutePosition p) => MouseWheelEvent(kind, x - p.x, y - p.y);

  @override
  String toString() => "$kind,$x,$y";
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

  const MouseButtonEvent(this.kind, super.x, super.y);

  @override
  MouseEvent relativeTo(AbsolutePosition p) => MouseButtonEvent(kind, x - p.x, y - p.y);

  @override
  String toString() => "$kind,$x,$y";
}

enum MouseMotionKind {
  lmb,
  mmb,
  rmb,
}

class MouseMotionEvent extends MouseEvent {
  final MouseMotionKind kind;

  const MouseMotionEvent(this.kind, super.x, super.y);

  @override
  MouseEvent relativeTo(AbsolutePosition p) => MouseMotionEvent(kind, x - p.x, y - p.y);

  @override
  String toString() => "$kind,$x,$y";
}

typedef MouseHandler = Function(MouseEvent);
