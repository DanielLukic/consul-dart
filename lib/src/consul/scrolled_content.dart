import 'dart:math';

import 'package:dart_consul/dart_consul.dart';

ScrolledContent scrolled(
  Window window,
  OnRedraw content, {
  bool extendName = true,
  bool defaultShortcuts = true,
  bool mouseWheel = true,
  bool ellipsize = true,
}) {
  final it = ScrolledContent(window, content, ellipsize: ellipsize);
  window.redrawBuffer = it.redrawBuffer;
  if (extendName) {
    window.name = "${window.name} ≡ ▼/▲ j/k";
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
  bool ellipsize;
  int scrollOffset = 0;

  ScrolledContent(
    this.window,
    this.content, {
    this.ellipsize = false,
  });

  void scroll(int delta) {
    scrollOffset += delta;
    window.requestRedraw();
  }

  String? redrawBuffer() {
    final rows = content()?.split("\n");
    if (rows == null) return null;
    final maxScroll = max(0, rows.length - window.height);
    scrollOffset = scrollOffset.clamp(0, maxScroll);
    final maxHeight = min(rows.length, window.height);
    var snap = rows.skip(scrollOffset).take(maxHeight).toList();
    if (ellipsize && rows.length > window.height) {
      if (scrollOffset > 0) {
        snap[0] = " ▲ ▲ ▲ ".gray().reset();
      }
      if (scrollOffset < maxScroll) {
        snap[snap.length - 1] = " ▼ ▼ ▼ ".gray().reset();
      }
    }
    return snap.join("\n");
  }
}
