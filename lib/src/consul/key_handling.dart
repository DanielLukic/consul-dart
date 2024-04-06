part of 'desktop.dart';

enum _MatchResult {
  gotNothing,
  matchedAndTriggered,
  partialOnly,
}

mixin KeyHandling {
  var _keyTimeoutMillis = 600;

  int get keyTimeoutMillis => _keyTimeoutMillis;

  set keyTimeoutMillis(int value) {
    _keyTimeoutMillis = value < 0 ? 0 : value;
  }

  final _matchers = <_Matcher>[];
  Timer? _autoReset;

  KeyHandling? _nested;

  _onKeyEvent(KeyEvent it) {
    // if nested handler matched and triggered, reset "this" and stop here:
    if (_nested?._match(it) == _MatchResult.matchedAndTriggered) {
      _reset();
    } else
    // if "this" matched and triggered, reset the nested handler:
    if (_match(it) == _MatchResult.matchedAndTriggered) {
      _nested?._reset();
    }
  }

  void _reset() {
    _autoReset?.cancel();
    _resetMatchers();
  }

  _MatchResult _match(KeyEvent it) {
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
      return _MatchResult.matchedAndTriggered;
    }

    // if nothing matched at all, immediately reset and be done:
    if (matches.isEmpty && partials.isEmpty) {
      _resetMatchers();
      return _MatchResult.gotNothing;
    }

    // otherwise we have partial matches.

    // auto reset these after a timeout if a timeout is set:
    if (_keyTimeoutMillis != 0) {
      _autoReset = Timer(keyTimeoutMillis.millis, () {
        final matches = _matchers.where((element) => element.isMatch());
        matches.firstOrNull?.trigger();
        _resetMatchers();
      });
    }

    return _MatchResult.partialOnly;
  }

  void _resetMatchers() {
    for (var element in _matchers) {
      element.reset();
    }
  }

  /// Add a key handler matching the given [pattern] or any of the given [aliases], if any.
  /// [description] is used when showing the current keymap configuration. [action] will be
  /// executed when the [pattern] or one of the [aliases] is matched to user input.
  Disposable onKey(
    String pattern, {
    List<String> aliases = const [],
    required String description,
    required Function action,
  }) {
    var it = _Matcher([pattern, ...aliases], description, action);
    _matchers.add(it);
    return Disposable(() => _matchers.remove(it));
  }

  Iterable<(String, String)> keyMapEntries() =>
      _matchers.map((e) => (e.patterns.toString(), e.description));
}

class _Matcher {
  final List<String> patterns;
  final String description;
  final Function _handler;

  String _buffer = "";

  _Matcher(this.patterns, this.description, this._handler);

  void consume(KeyEvent it) => _buffer = _buffer + it.printable;

  bool isPartialMatch() => !isMatch() && patterns.any((it) => it.startsWith(_buffer));

  bool isMatch() => patterns.any((it) => it == _buffer);

  void trigger() => _handler();

  void reset() => _buffer = "";

  @override
  String toString() => "$patterns <=> $_buffer";
}
