part of 'desktop.dart';

/// Basic debug log for "on-screen" (where else? ^^) display. Holds the ten last [RawEvent]s
/// received from the terminal.
class DebugLog {
  final _entries = <(DateTime, String)>[];

  void clear() => _entries.clear();

  void add(message) {
    while (_entries.length >= 100) {
      _entries.removeAt(0);
    }
    _entries.add((DateTime.now(), message.toString()));
  }

  Iterable<String> get reversed => _entries.reversed.map((e) {
        // lovely :-D
        final timestamp = e.$1.toIso8601String().split("T").last;
        return "$timestamp: ${e.$2}";
      });
}

final eventDebugLog = DebugLog();
