part of 'desktop.dart';

mixin _KeyHandling {
  var _keyTimeoutMillis = 400;

  int get keyTimeoutMillis => _keyTimeoutMillis;

  set keyTimeoutMillis(int value) {
    _keyTimeoutMillis = value < 0 ? 0 : value;
  }

  final _matchers = <_Matcher>[];
  Timer? _autoReset;

  _onKeyEvent(KeyEvent it) {
    _autoReset?.cancel();

    // provide the current event to all registered handlers:
    for (final matcher in _matchers) {
      matcher.consume(it);
    }

    final matches = _matchers.where((element) => element.isMatch());
    final partials = _matchers.where((element) => element.isPartialMatch());

    eventDebugLog.add("matchers: $_matchers");

    // if match found, but no partials, reset matching, trigger first match, and be done here:
    if (matches.isNotEmpty && partials.isEmpty) {
      matches.firstOrNull?.trigger();
      _resetMatchers();
      return;
    }

    // if nothing matched at all, immediately reset and be done:
    if (matches.isEmpty && partials.isEmpty) {
      _resetMatchers();
      return;
    }

    // otherwise we have partial matches. auto reset these after a timeout:
    if (_keyTimeoutMillis != 0) {
      _autoReset = Timer(keyTimeoutMillis.millis, () {
        final matches = _matchers.where((element) => element.isMatch());
        matches.firstOrNull?.trigger();
        _resetMatchers();
      });
    }
  }

  void _resetMatchers() {
    for (var element in _matchers) {
      element.reset();
    }
  }

  Disposable onKey(String pattern, Function handler) {
    var it = _Matcher(pattern, handler);
    _matchers.add(it);
    return Disposable(() => _matchers.remove(it));
  }
}

class _Matcher {
  final String _pattern;
  final Function _handler;

  String _buffer = "";

  _Matcher(this._pattern, this._handler);

  void consume(KeyEvent it) => _buffer = _buffer + it.printable;

  bool isPartialMatch() => !isMatch() && _pattern.startsWith(_buffer);

  bool isMatch() => _pattern == _buffer;

  void trigger() => _handler();

  void reset() => _buffer = "";

  @override
  String toString() => "$_pattern <=> $_buffer";
}
