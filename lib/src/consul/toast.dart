part of 'desktop.dart';

abstract mixin class ToastHandling {
  final _pending = <String>[];
  Window? _active;

  void openWindow(Window window);

  void closeWindow(Window window);

  void toast(anything, {Duration duration = const Duration(seconds: 1)}) {
    if (_active != null) {
      _pending.add(anything.toString());
      return;
    }

    final lines = anything.toString().split("\n").take(3);
    final width = lines.reduce((a, b) => a.length < b.length ? b : a).length;
    final padded = lines.map((e) => e.padRight(width));
    final decorated = padded.map((e) => "║ $e ║");
    final border = "".padRight(width + 2, "═");
    final top = /*****/ "╔$border╗";
    final bottom = /**/ "╚$border╝";
    final message = [top, ...decorated, bottom].join("\n");

    final window = Window(
      "_toast",
      "Toast: $anything",
      size: WindowSize.fixed(Size(width + 4, 3)),
      position: RelativePosition.fromBottom(yOffset: -3),
      flags: {WindowFlag.undecorated},
      redraw: () => message,
    );

    openWindow(window);
    _active = window;

    Timer(duration, () {
      final window = _active;
      _active = null;
      if (window != null) closeWindow(window);
      if (_pending.isEmpty) return;
      toast(_pending.removeAt(0));
    });
  }
}
