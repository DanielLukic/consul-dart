part of 'desktop.dart';

/// Helper for keeping [DecoratedWindow] focused more on the logic, while this mixin contains the
/// text mangling.
mixin _WindowDecoration {
  /// Put the titlebar above the window content and put a resize control in the bottom right
  /// corner. Unless the window is [WindowFlag.undecorated], in which case the window buffer is
  /// returned without any decoration.
  String? Function() _decorateBuffer(Window window) {
    var buffer = window.redrawBuffer();
    if (window.undecorated || buffer == null) return () => buffer;

    final controls = _buildControls(window);
    final title = _buildTitle(window, controls);
    final titlebar = window.isFocused ? "$title$controls".inverse() : "$title$controls";

    final lines = [titlebar, ...buffer.split("\n").take(window.height)];
    final extraLines = List.filled(max(0, window.height - lines.length), "");
    var fitted = (lines + extraLines).map((line) => _fitLineWidth(line, window.width)).toList();

    if (window.resizable) {
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

    // if the line is too long, remove from the end. but check first if the end is an ansi escape.
    // in that case, skip the entire escape in one step. otherwise, remove a single character. then
    // repeat.
    var result = line;
    while (_ansiStripped(result).length > width) {
      final lastAnsi = _ansiMatcher.allMatches(result).lastOrNull;
      if (lastAnsi?.end == result.length) {
        result = result.substring(0, lastAnsi!.start);
      } else {
        result = result.substring(0, result.length - 1);
      }
    }

    // ignore longer lines for now... ‾\_('')_/‾
    return result;
  }

  String _buildControls(Window window) {
    final controls = StringBuffer();
    if (window.resizable) controls.write("[_]");
    if (window.maximizable) controls.write("[O]");
    if (window.closeable) controls.write("[X]");
    if (controls.isNotEmpty) return " $controls";
    return "";
  }

  String _buildTitle(Window window, String controls) {
    final left = "≡ ";
    var right = " ≡";
    final available = window.width - controls.length - left.length - right.length;
    if (window.name.length > available) {
      right = "…≡";
    }
    final snip = window.name.take(available);
    final title = "$left$snip$right";
    return title.padRight(window.width - controls.length, "≡");
  }

  WindowSize _decoratedSize(Window window) {
    if (window.flags.contains(WindowFlag.undecorated)) {
      return window.size;
    }
    // plus one row for the title bar:
    return WindowSize(
      Size(window.width, window.height + 1),
      window.size.min,
      window.size.max,
    );
  }
}
