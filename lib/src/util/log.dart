import 'package:ansi/ansi.dart';

var logLevel = LogLevel.info;

enum LogLevel { verbose, debug, info, warn, error, none }

extension on LogLevel {
  tag() => name.substring(0, 1).toUpperCase();
}

log(Object? message, [LogLevel? level, StackTrace? trace]) {
  level ??= LogLevel.info;
  if (level.index < logLevel.index) return;

  var (name, where) = StackTrace.current.caller;
  if (message is Function) {
    try {
      message = message();
    } catch (it, trace) {
      logError(it, trace);
      return;
    }
  }

  var full = "[${level.tag()}] $message [$name] $where";
  switch (level) {
    case LogLevel.verbose:
      full = gray(full);
    case LogLevel.debug:
      full = cyan(full);
    case LogLevel.info:
      full = green(full);
    case LogLevel.warn:
      full = magenta(full);
    case LogLevel.error:
      full = red(full);
    case LogLevel.none:
      break;
  }
  print(full);

  if (trace != null) print(trace.toString());
}

logInfo(Object? message) => log(message, LogLevel.info);

logWarn(Object? message) => log(message, LogLevel.warn);

logError(Object? message, [StackTrace? trace]) => log(message, LogLevel.error, trace);

logDebug(Object? message) => log(message, LogLevel.debug);

logVerbose(Object? message) => log(message, LogLevel.verbose);

extension on StackTrace {
  (String function, String location) get caller {
    caller(String it) => !it.contains("log.dart");
    var lines = toString().split("\n");
    var trace = lines.firstWhere(caller, orElse: () => "");
    var parts = trace.replaceAll(RegExp(r"#\d\s+"), "").split(" ");
    return (parts[0], parts[1]);
  }
}
