part of 'desktop.dart';

/// Basic window abstraction for the [Desktop] system. Boils down to a [String] as the "buffer".
/// May contain ansi control sequences. Buffer can be smaller or bigger than the window size.
/// Will be restricted properly when drawn. Return the data to be shown via [redrawBuffer].
///
/// Various hooks available to react to changes: [onSizeChanged], [onStateChanged] and
/// [onMouseEvent] for now.
class Window with AutoDispose, KeyHandling, _WindowDecoration {
  final String id;

  String name;
  Set<WindowFlag> flags = {};
  Position _position;
  WindowSize _size;
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
  OnMouseEvent onMouseEvent = (event) => null;

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
    Position position = Position.unsetInitially,
    WindowSize size = const WindowSize.defaultMinMax(Size(40, 20)),
    WindowState state = WindowState.normal,
    Set<WindowFlag>? flags,
    OnRedraw? redraw,
  })  : _state = state,
        _size = size,
        _position = position {
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
  void addOverlay(WindowOverlay it) {
    _overlays.add(it);
    requestRedraw();
  }

  /// Counterpart to [addOverlay] for removing an overlay.
  void removeOverlay(WindowOverlay it) {
    _overlays.remove(it);
    requestRedraw();
  }

  @override
  String toString() {
    final s = _size.current;
    final f = flags.map((e) => e.name.take(2)).join(",");
    return "Window(name=$name,id=$id,position=$_position,size=$s,flags=$f,state=${state.name}))";
  }
}

extension WindowAccessors on Window {
  WindowSize get size => _size;

  set size(WindowSize it) {
    _size = it;
    requestRedraw();
  }

  Position get position => _position;

  set position(Position it) {
    _position = it;
    requestRedraw();
  }
}
