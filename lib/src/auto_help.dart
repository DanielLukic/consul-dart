// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:dart_consul/common.dart';
import 'package:dart_consul/dart_consul.dart';
import 'package:dart_minilog/dart_minilog.dart';

void addAutoHelp(
  Desktop desktop, {
  String key = "<C-?>",
  List<String> aliases = const [],
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
  desktop.onKey(
    key,
    aliases: aliases,
    description: "Show help screen",
    action: () => _showKeymap(desktop, window),
  );

  desktop.openWindow(button);
}

OngoingMouseAction? _showKeymapOnClick(
  MouseEvent it,
  Desktop desktop,
  Window window,
) {
  if (it.x >= 0 && it.x < 3 && it.y == 0 && it.isUp) {
    _showKeymap(desktop, window);
  }
  return null;
}

void _showKeymap(Desktop desktop, Window window) {
  Window? focused = desktop.focused;

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

  final content = _gatherKeymap(desktop.keyMap()).join('\n');
  _scrolled.content = () => content;

  final offset = _sections.firstWhereOrNull((e) => e.$1 == focused?.name)?.$2;
  if (offset != null && offset > 0) {
    // minus one because of the scroll indicators at top for non-zero offset:
    _scrolled.scrollOffset = offset - 1;
  }

  logInfo(_sections);
}

late ScrolledContent _scrolled;

Window _prepareKeymapWindow(Desktop desktop) {
  final window = Window(
    "keymap",
    "Keymap",
    size: WindowSize.min(Size(60, 20)),
    position: RelativePosition.autoCentered(),
  );

  window.flags.remove(WindowFlag.resizable);

  _scrolled = scrolled(window, () => '', borderStyle: doubleBorder);

  window.onFocusChanged.add(() {
    if (!window.isFocused) desktop.minimizeWindow(window);
  });

  window.onKey(
    "x",
    aliases: ["<Escape>", "q"],
    description: "Close the keymap window",
    action: () => desktop.closeWindow(window),
  );

  return window;
}

List<(String, int)> _sections = [];

List<String> _gatherKeymap(KeyMap keyMap) {
  final sections =
      List<MapEntry<String, Iterable<(String, String)>>>.from(keyMap.entries);
  sections.sort((a, b) {
    if (a.key == "Desktop") return -1;
    return a.key.compareTo(b.key);
  });

  final lines = <String>[];
  for (final section in sections) {
    final header = section.key;
    final entries = section.value.map((e) => '${e.$1}: ${e.$2}').toList();
    entries.sort();

    // empty line before every section but the first:
    if (lines.isNotEmpty) lines.add('');

    _sections.add((header, lines.length));

    final sectionName = header.replaceFirst(RegExp(r'\[.*]'), '');
    lines.add(bold('◉ $sectionName ◉'));
    lines.add('');
    lines.addAll(entries);
  }
  return lines;
}
