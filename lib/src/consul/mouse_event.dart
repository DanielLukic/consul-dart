part of 'desktop.dart';

sealed class MouseEvent {
  final int x;
  final int y;

  const MouseEvent(this.x, this.y);
}

enum MouseWheelKind {
  wheelDown,
  wheelUp,
}

class MouseWheelEvent extends MouseEvent {
  final MouseWheelKind kind;

  const MouseWheelEvent(this.kind, super.x, super.y);

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
}

class MouseButtonEvent extends MouseEvent {
  final MouseButtonKind kind;

  const MouseButtonEvent(this.kind, super.x, super.y);

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
  String toString() => "$kind,$x,$y";
}

typedef MouseHandler = Function(MouseEvent);
