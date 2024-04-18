part of 'desktop.dart';

extension WindowExtensions on Window {
  bool get closeable => flags.contains(WindowFlag.closeable);

  // TODO Note the negation. Should this be a proper flag, too, right?
  bool get focusable => !flags.contains(WindowFlag.undecorated);

  bool get maximizable => flags.contains(WindowFlag.maximizable);

  bool get minimizable => flags.contains(WindowFlag.minimizable);

  bool get movable => !flags.contains(WindowFlag.unmovable);

  bool get resizable => flags.contains(WindowFlag.resizable);

  bool get undecorated => flags.contains(WindowFlag.undecorated);

  bool get alwaysOnTop => flags.contains(WindowFlag.alwaysOnTop);

  bool get isClosed => state == WindowState.closed;

  bool get isMaximized => state == WindowState.maximized;

  bool get isMinimized => state == WindowState.minimized;

  bool get isFocused => _isFocused(this);

  int get width => size.current.width;

  int get height => size.current.height;

  int get decoratedHeight => size.current.height + (undecorated ? 0 : 1);

  /// Ensure the window [position] is an [AbsolutePosition]. This is required
  /// for some operations.
  void fixPosition() => position = decoratedPosition();

  /// Maps a potentially relative position onto an [AbsolutePosition] on the
  /// desktop screen space.
  AbsolutePosition decoratedPosition() {
    if (isMaximized) {
      return Position.topLeft;
    } else {
      return position.toAbsolute(_desktopSize(), _decoratedSize(this).current);
    }
  }

  _resizeClamped(int width, int height) {
    final desktop = _desktopSize();

    // fix the current position because it is the origin against which the
    // resize happens:
    fixPosition();

    final minSize = size.min.ifAutoFill(desktop);
    final maxSize = size.max.ifAutoFill(desktop);
    final ww = width.clamp(minSize.width, maxSize.width);
    final hh = height.clamp(minSize.height, maxSize.height);

    // 16 for titlebar, 2 for titlebar + resize control
    var minWidth = 16;
    if (!flags.contains(WindowFlag.closeable)) minWidth -= 3;
    if (!flags.contains(WindowFlag.maximizable)) minWidth -= 3;
    if (!flags.contains(WindowFlag.minimizable)) minWidth -= 3;
    var minHeight = 2;
    if (!flags.contains(WindowFlag.resizable)) minWidth -= 1;
    _resize(max(minWidth, ww), max(minHeight, hh));
  }

  _resize(int width, int height) {
    size = WindowSize(Size(width, height), size.min, size.max);
    onSizeChanged.notifyAll();
  }

  _resize_(Size size) => _resize(size.width, size.height);
}
