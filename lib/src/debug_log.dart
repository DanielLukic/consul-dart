import '../dart_consul.dart';

Window addDebugLog(
  Desktop desktop, {
  required LogView log,
  String name = "Log",
  String? key,
  WindowState state = WindowState.normal,
  Size size = const Size.autoWidth(10),
  Position position = const RelativePosition.fromBottom(yOffset: -1),
  bool Function(String)? filter,
}) {
  final window = Window(
    "log",
    name,
    state: state,
    size: WindowSize.min(size),
    position: position,
  );

  final f = filter ?? (e) => true;
  scrolled(
    window,
    () => log.entries.where(f).join("\n"),
    ellipsize: true,
  );

  if (key != null) _addToggleKey(desktop, key, window);

  desktop.openWindow(window);

  return window;
}

void _addToggleKey(Desktop desktop, String key, Window window) {
  desktop.onKey(key, description: "Toggle showing debug log", action: () {
    final it = desktop.findWindow("debug");
    switch (it?.state) {
      case null:
      case WindowState.closed:
        desktop.openWindow(window);
      case WindowState.minimized:
        desktop.raiseWindow(window);
      case WindowState.maximized:
      case WindowState.normal:
        desktop.minimizeWindow(window);
    }
  });
}
