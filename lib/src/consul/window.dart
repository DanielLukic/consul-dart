part of 'desktop.dart';

class Window with AutoDispose, KeyHandling {
  String id;
  String name;
  Set<WindowFlag> flags = {};
  Position position;
  WindowSize size;

  WindowState _state;

  WindowState get state => _state;

  set state(WindowState value) {
    _state = value;
    onStateChanged();
  }

  bool get focusable => !flags.contains(WindowFlag.undecorated);

  bool get undecorated => flags.contains(WindowFlag.undecorated);

  bool get isClosed => state == WindowState.closed;

  bool get isMaximized => state == WindowState.maximized;

  bool get isMinimized => state == WindowState.minimized;

  bool get isFocused => _isFocused(this);

  int get width => size.current.width;

  int get height => size.current.height;

  bool Function(Window) _isFocused = (_) => false;

  String? Function() redrawBuffer = () => null;

  void Function() onSizeChanged = () {};
  void Function() onStateChanged = () {};

  /// Call this to request a redraw. Note that it will be a nop until the window is actually opened
  /// on the desktop via [Desktop.openWindow]. (And it will be a nop after closing the window. Doh.)
  Function requestRedraw = () {};

  Window(
    this.id,
    this.name, {
    this.position = Position.unsetInitially,
    this.size = const WindowSize.defaultMinMax(Size(40, 20)),
    WindowState state = WindowState.normal,
    Set<WindowFlag>? flags,
    String? Function()? redraw,
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

  resize(int width, int height) {
    // TODO restrict min/max
    size = WindowSize(Size(width, height), size.min, size.max);
    onSizeChanged();
  }

  resize_(Size size) => resize(size.width, size.height);

  final _overlays = <WindowOverlay>[];

  void addOverlay(WindowOverlay it) => _overlays.add(it);

  void removeOverlay(WindowOverlay it) => _overlays.remove(it);

  @override
  String toString() {
    final s = size.current;
    final f = flags.map((e) => e.name.take(2)).join(",");
    return "Window(name=$name,id=$id,position=$position,size=$s,flags=$f,state=${state.name}))";
  }
}
