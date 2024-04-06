part of 'desktop.dart';

/// Basic window abstraction for the [Desktop] system. Boils down to a [String] as the "buffer".
/// May contain ansi control sequences. Buffer can be smaller or bigger than the window size.
/// Will be restricted properly when drawn. Return the data to be shown via [redrawBuffer].
///
/// Various hooks available to react to changes: [onSizeChanged], [onStateChanged] and
/// [onMouseEvent] for now.
class Window with AutoDispose, KeyHandling {
  final String id;

  String name;
  Set<WindowFlag> flags = {};
  Position position;
  WindowSize size;

  WindowState _state;

  /// Used to restore back from [WindowState.minimized] when state before minimize was
  /// [WindowState.maximized].
  WindowState? _restoreState;

  WindowState get state => _state;

  set state(WindowState value) {
    _state = value;
    onStateChanged();
  }

  Size Function() _desktopSize = () => Size.zero;
  bool Function(Window) _isFocused = (_) => false;

  /// Implement this to provide the data to be shown for your window.
  OnRedraw redrawBuffer = () => null;

  /// Override this to intercept/receive mouse events. It is important to return true here as long
  /// as mouse events are consumed. Then end with a false after some action is done. Only after
  /// returning false here, another consumer and/or new action is allowed to start.
  OngoingMouseAction? Function(MouseEvent) onMouseEvent = (event) => null;

  /// Install hook to get notified on size changes.
  void Function() onSizeChanged = () {};

  /// Install hook to get notified on state changes.
  void Function() onStateChanged = () {};

  /// Call this to request a redraw. Note that it will be a nop until the window is actually opened
  /// on the desktop via [Desktop.openWindow]. (And it will be a nop after closing the window. Doh.)
  Function requestRedraw = () {};

  /// Shortcut to [Desktop.sendMessage]. Available from after [Desktop.openWindow] up until
  /// [Desktop.closeWindow]. Primary use case is internal functionality. But open for use by
  /// client code.
  Function(dynamic) sendMessage = (_) {};

  /// Construct a new window with potentially many default settings. Note that only the [id] is
  /// fixed for now. Everything else can be changed after construction. Note also that windows
  /// are not shown unless [Desktop.openWindow] is called.
  Window(
    this.id,
    this.name, {
    this.position = Position.unsetInitially,
    this.size = const WindowSize.defaultMinMax(Size(40, 20)),
    WindowState state = WindowState.normal,
    Set<WindowFlag>? flags,
    OnRedraw? redraw,
  }) : _state = state {
    this.flags = flags ??
        {
          WindowFlag.closeable,
          WindowFlag.resizable,
          WindowFlag.minimizable,
          WindowFlag.maximizable,
        };
    if (size.current == size.min && size.current == size.max) {
      this.flags.remove(WindowFlag.resizable);
    }
    if (redraw != null) {
      redrawBuffer = redraw;
    }
  }

  final _overlays = <WindowOverlay>[];

  /// Used primarily to draw "system" overlays when moving or resizing windows. But can be used
  /// for anything really. Like additional layers per window.
  void addOverlay(WindowOverlay it) => _overlays.add(it);

  /// Counterpart to [addOverlay] for removing an overlay.
  void removeOverlay(WindowOverlay it) => _overlays.remove(it);

  @override
  String toString() {
    final s = size.current;
    final f = flags.map((e) => e.name.take(2)).join(",");
    return "Window(name=$name,id=$id,position=$position,size=$s,flags=$f,state=${state.name}))";
  }
}

extension WindowExtensions on Window {
  bool get closeable => flags.contains(WindowFlag.closeable);

  // TODO Note the negation. Should this be a proper flag, too, right?
  bool get focusable => !flags.contains(WindowFlag.undecorated);

  bool get maximizable => flags.contains(WindowFlag.maximizable);

  bool get minimizable => flags.contains(WindowFlag.minimizable);

  bool get movable => !flags.contains(WindowFlag.unmovable);

  bool get resizable => flags.contains(WindowFlag.resizable);

  bool get undecorated => flags.contains(WindowFlag.undecorated);

  bool get isClosed => state == WindowState.closed;

  bool get isMaximized => state == WindowState.maximized;

  bool get isMinimized => state == WindowState.minimized;

  bool get isFocused => _isFocused(this);

  int get width => size.current.width;

  int get height => size.current.height;

  /// Ensure the window [position] is an [AbsolutePosition]. This is required for many operations.
  /// At least for now.
  void fixPosition() =>
      position = position.toAbsolute(_desktopSize(), size.current);

  /// Keeping this private for now, too. It handles restricting to min/max now, but still to
  /// fiddly to expose imho.
  _resizeClamped(int width, int height) {
    final desktop = _desktopSize();

    // fix the current position because it is the origin against which the resize happens:
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

  /// Keeping this private for now as it directly manipulates without restricting. Restricting has
  /// to happen in [Desktop] instead for now.
  _resize(int width, int height) {
    size = WindowSize(Size(width, height), size.min, size.max);
    onSizeChanged();
  }

  /// Keeping this private for now as it directly manipulates without restricting. Restricting has
  /// to happen in [Desktop] instead for now.
  _resize_(Size size) => _resize(size.width, size.height);
}
