import '../dart_consul.dart';

addDebugLog(
  Desktop desktop, {
  String key = "<C-w>l",
  WindowState state = WindowState.normal,
  Size size = const Size.autoWidth(10),
  Position position = const RelativePosition.fromBottom(yOffset: -1),
}) {
  final window = Window(
    "debug",
    "Event Debug Log",
    state: state,
    size: WindowSize.min(size),
    position: position,
  );

  eventDebugLog.redraw = () => window.requestRedraw();

  scrolled(
    window,
    () => eventDebugLog.allReversed().join("\n"),
    ellipsize: true,
  );

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

  desktop.openWindow(window);
}
