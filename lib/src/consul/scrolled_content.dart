import 'dart:math';

import 'package:dart_consul/dart_consul.dart';

extension StrExt on String {
  String removeSuffix(String suffix) {
    if (endsWith(suffix)) {
      return substring(0, length - suffix.length);
    }
    return this;
  }
}

ScrolledContent scrolled(
  Window window,
  OnRedraw content, {
  String? header,
  String nameExtension = " ≡ ▼/▲ j/k",
  bool extendName = true,
  bool defaultShortcuts = true,
  bool mouseWheel = true,
  bool ellipsize = true,
}) {
  final it = ScrolledContent(
    window,
    content,
    header: header,
    ellipsize: ellipsize,
  );
  window.redrawBuffer = it.redrawBuffer;
  if (extendName) {
    window.onFocusChanged.add(() {
      window.name = window.name.removeSuffix(nameExtension);
      if (window.isFocused) {
        window.name = "${window.name}$nameExtension";
      }
    });
  }
  if (defaultShortcuts) {
    window.onKey("j", description: "Scroll down", action: () => it.scroll(1));
    window.onKey("k", description: "Scroll up", action: () => it.scroll(-1));
    window.onKey("<S-j>",
        description: "Scroll down", action: () => it.scroll(5));
    window.onKey("<S-k>",
        description: "Scroll up", action: () => it.scroll(-5));
  }
  if (mouseWheel) {
    window.onWheelUp(() => it.scroll(-1));
    window.onWheelDown(() => it.scroll(1));
  }
  return it;
}

class ScrolledContent {
  Window window;
  OnRedraw content;
  String? header;
  bool ellipsize;
  int scrollOffset = 0;

  ScrolledContent(
    this.window,
    this.content, {
    this.header,
    this.ellipsize = false,
  });

  void scroll(int delta) {
    scrollOffset += delta;
    window.requestRedraw();
  }

  String? redrawBuffer() {
    final rows = content()?.split("\n");
    if (rows == null) return null;
    final headerLines = header?.split("\n") ?? [];
    final offset = headerLines.length;
    final maxScroll = max(0, rows.length - window.height - offset);
    scrollOffset = scrollOffset.clamp(0, maxScroll);
    final maxHeight = min(rows.length, window.height - offset);
    var snap = rows.skip(scrollOffset).take(maxHeight).toList();
    if (ellipsize && rows.length > window.height) {
      if (scrollOffset > 0) {
        snap[0] = " ▲ ▲ ▲ ".gray().reset();
      }
      if (scrollOffset < maxScroll) {
        snap[snap.length - 1] = " ▼ ▼ ▼ ".gray().reset();
      }
    }
    return (headerLines + snap).join("\n");
  }
}
