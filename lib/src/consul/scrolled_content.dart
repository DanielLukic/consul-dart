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
  List<String>? borderStyle,
}) {
  final it = ScrolledContent(
    window,
    content,
    header: header,
    ellipsize: ellipsize,
    borderStyle: borderStyle,
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
  List<String>? borderStyle;

  ScrolledContent(
    this.window,
    this.content, {
    this.header,
    this.ellipsize = false,
    this.borderStyle,
  });

  void scroll(int delta) {
    scrollOffset += delta;
    window.requestRedraw();
  }

  String? redrawBuffer() {
    var height = borderStyle != null ? window.height - 2 : window.height;

    final rows = content()?.split("\n");
    if (rows == null) return null;
    final headerLines = header?.split("\n") ?? [];
    height -= headerLines.length;
    final maxScroll = max(0, rows.length - height);
    scrollOffset = scrollOffset.clamp(0, maxScroll);
    final maxHeight = min(rows.length, height);
    var snap = rows.skip(scrollOffset).take(maxHeight).toList();
    if (ellipsize && rows.length > height) {
      if (scrollOffset > 0) {
        snap[0] = " ▲ ▲ ▲ ".gray().reset();
      }
      if (scrollOffset < maxScroll) {
        snap[snap.length - 1] = " ▼ ▼ ▼ ".gray().reset();
      }
    }
    final data = (headerLines + snap).join("\n");
    if (borderStyle == null) return data;

    final buffer = Buffer(window.width, window.height);
    buffer.drawBuffer(2, 1, data);
    buffer.drawBorder(0, 0, window.width, window.height, borderStyle!);
    return buffer.render();
  }
}
