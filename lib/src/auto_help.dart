// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:math';

import 'package:consul/consul.dart';

var _y = 0;

void addAutoHelp(
  Desktop desktop, {
  String key = "<C-?>",
  Position position = const RelativePosition.fromBottomRight(),
}) {
  final button = Window(
    "auto-help",
    "auto-help",
    flags: {WindowFlag.undecorated, WindowFlag.unmovable},
    size: WindowSize.fixed(Size(3, 1)),
    position: position,
    redraw: () => "(?)",
  );

  final window = _prepareKeymapWindow(desktop);
  button.onMouseEvent = (it) => _showKeymapOnClick(it, desktop, window);
  desktop.onKey(key, description: "Show help screen", action: () => _showKeymap(desktop, window));

  desktop.openWindow(button);
}

OngoingMouseAction? _showKeymapOnClick(MouseEvent it, Desktop desktop, Window window) {
  if (it.x >= 0 && it.x < 3 && it.y == 0 && it.isUp) {
    _showKeymap(desktop, window);
  }
  return null;
}

void _showKeymap(Desktop desktop, Window window) {
  final it = desktop.findWindow("keymap");
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
}

Window _prepareKeymapWindow(Desktop desktop) {
  final window = Window(
    "keymap",
    "Keymap",
    size: WindowSize.min(Size(60, 20)),
    position: RelativePosition.autoCentered(),
  );

  window.flags.remove(WindowFlag.resizable);

  window.redrawBuffer = () {
    final lines = _gatherKeymap(desktop.keyMap());

    final available = window.height - 4;
    final maxScroll = max(0, lines.length - available);
    _y = _y.clamp(0, maxScroll);

    final maxShown = min(_y + available, lines.length) - _y;

    // TODO There really should be a Border + Buffer concept available for something like this...
    // TODO But not for Version 1... :-D

    final maxWidth = window.width - 4;
    final controls = "Scroll down/up: <Down>/<Up> or j/k";
    final shown = ["", ...lines.sublist(_y, _y + maxShown), "", controls];
    final formatted = shown.map((e) => "║ ${e.padRight(maxWidth)} ║");
    final bottom = "╚" + "".padRight(maxWidth + 2, "═") + "╝";
    return [...formatted, bottom].join("\n");
  };

  window.onKey(
    "k",
    aliases: ["<Up>"],
    description: "Scroll one line up",
    action: () {
      _y -= 1;
      eventDebugLog.clear();
      eventDebugLog.add("UP: $_y");
      window.requestRedraw();
    },
  );

  window.onKey(
    "j",
    aliases: ["<Down>"],
    description: "Scroll one line down",
    action: () {
      _y += 1;
      eventDebugLog.clear();
      eventDebugLog.add("DOWN: $_y");
      window.requestRedraw();
    },
  );

  return window;
}

List<String> _gatherKeymap(KeyMap keyMap) {
  final lines = <String>[];
  for (final section in keyMap.entries) {
    final header = section.key;
    final entries = section.value.map((e) => "◉ ${e.$1}: ${e.$2}");

    // empty line before every section but the first:
    if (lines.isNotEmpty) lines.add("");

    lines.add(header);
    lines.add("");
    lines.addAll(entries);
  }
  return lines;
}
