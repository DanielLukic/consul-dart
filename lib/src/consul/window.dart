part of 'desktop.dart';

enum WindowFlag {
  closeable,
  resizable,
  minimizable,
  maximizable,
  undecorated,
}

class WindowSize {
  final Size current;
  final Size min;
  final Size max;

  const WindowSize(this.current, this.min, this.max);

  const WindowSize.max(this.current)
      : min = const Size(0, 0),
        max = current;

  const WindowSize.min(this.current)
      : min = current,
        max = Size.autoFill;

  const WindowSize.defaultMinMax(this.current)
      : min = const Size(0, 0),
        max = Size.autoFill;

  const WindowSize.fixed(this.current)
      : min = current,
        max = current;

  const WindowSize.fillScreen()
      : current = Size.autoFill,
        min = Size.autoFill,
        max = Size.autoFill;
}

enum WindowState {
  maximized,
  minimized,
  normal,
}

// TODO create once only per window... not once per frame... :-D ^^
class DecoratedWindow implements Window {
  final Window _window;
  final bool focused;

  DecoratedWindow.decorate(this._window, {required this.focused});

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Quick hack for now to prototype this...
    final symbol = invocation.memberName.toString();
    final name = symbol.split('"')[1];
    final result = switch (name) {
      "flags" => _window.flags,
      "height" => _window.height,
      "id" => _window.id,
      "name" => _window.name,
      "position" => _window.position,
      "redrawBuffer" => _decorateBuffer(),
      "size" => _decoratedSize(),
      "state" => _window.state,
      "width" => _window.width,
      _ => throw NoSuchMethodError.withInvocation(_window, invocation),
    };
    return result;
  }

  bool get undecorated => _window.flags.contains(WindowFlag.undecorated);

  String? Function() _decorateBuffer() {
    var buffer = _window.redrawBuffer();
    if (undecorated || buffer == null) return () => buffer;

    final controls = _buildControls();
    final title = _buildTitle(controls);
    final titlebar = focused ? "$title$controls".inverse() : "$title$controls";

    final lines = [titlebar, ...buffer.split("\n")];
    var fitted = lines.map((line) => _fitLineWidth(line, width)).toList();

    if (flags.contains(WindowFlag.resizable)) {
      var bottom = fitted.takeLast(1).single;
      bottom = bottom.replaceRange(bottom.length - 1, bottom.length, "◢");
      fitted = fitted.dropLast(1) + [bottom];
    }

    return () => fitted.join("\n");
  }

  String _fitLineWidth(String line, int width) {
    final stripped = _ansiStripped(line);
    if (stripped.length == width) return line; // nothing to do

    final pad = (width - stripped.length).clamp(0, width);
    if (pad > 0) return (line + "".padRight(pad)); // simply extend to fill window width

    // ignore longer lines for now... ‾\_('')_/‾
    return line;
  }

  String _buildControls() {
    final controls = StringBuffer();
    if (flags.contains(WindowFlag.resizable)) controls.write("[_]");
    if (flags.contains(WindowFlag.maximizable)) controls.write("[O]");
    if (flags.contains(WindowFlag.closeable)) controls.write("[X]");
    if (controls.isNotEmpty) return " $controls";
    return "";
  }

  String _buildTitle(String controls) {
    final left = "≡ ";
    var right = " ≡";
    final available = width - controls.length - left.length - right.length;
    if (name.length > available) {
      right = "…≡";
    }
    final snip = name.take(available);
    final title = "$left$snip$right";
    return title.padRight(width - controls.length, "≡");
  }

  WindowSize _decoratedSize() {
    if (_window.flags.contains(WindowFlag.undecorated)) {
      return _window.size;
    }
    // one one row for the title bar:
    return WindowSize(
      Size(_window.width, _window.height + 1),
      _window.size.min,
      _window.size.max,
    );
  }
}

class Window {
  String id;
  String name;
  Set<WindowFlag> flags = {};
  Position position;
  WindowSize size;
  WindowState state;

  bool get focusable => !flags.contains(WindowFlag.undecorated);
  bool get isMinimized => state == WindowState.minimized;

  int get width => size.current.width;

  int get height => size.current.height;

  String? Function() redrawBuffer = () => null;

  /// Call this to request a redraw. Note that it will be a nop until the window is actually opened
  /// on the desktop via [Desktop.openWindow].
  Function requestRedraw = () {};

  Window(
    this.id,
    this.name, {
    this.position = Position.unsetInitially,
    this.size = const WindowSize.defaultMinMax(Size(40, 20)),
    this.state = WindowState.normal,
    Set<WindowFlag>? flags,
    String? Function()? redraw,
  }) {
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
  }
}
