part of 'desktop.dart';

class DecoratedWindow implements Window {
  final Window _window;

  DecoratedWindow.decorate(this._window) {
    eventDebugLog.add("window decorated: $_window");
  }

  AbsolutePosition decoratedPosition(Size desktop) {
    if (_window.isMaximized) {
      return Position.topLeft;
    } else {
      return position.toAbsolute(desktop, _decoratedSize().current);
    }
  }

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
      "resizable" => _window.resizable,
      "size" => _decoratedSize(),
      "state" => _window.state,
      "undecorated" => _window.undecorated,
      "width" => _window.width,
      _ => throw NoSuchMethodError.withInvocation(_window, invocation),
    };
    return result;
  }

  String? Function() _decorateBuffer() {
    var buffer = _window.redrawBuffer();
    if (undecorated || buffer == null) return () => buffer;

    final controls = _buildControls();
    final title = _buildTitle(controls);
    final titlebar = _window.isFocused ? "$title$controls".inverse() : "$title$controls";

    final lines = [titlebar, ...buffer.split("\n").take(height)];
    final extraLines = List.filled(max(0, height - lines.length), "");
    var fitted = (lines + extraLines).map((line) => _fitLineWidth(line, width)).toList();

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
    // plus one row for the title bar:
    return WindowSize(
      Size(_window.width, _window.height + 1),
      _window.size.min,
      _window.size.max,
    );
  }
}
