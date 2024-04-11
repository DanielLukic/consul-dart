import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';

final ansiReset = '\u001B[0m';
final ansiMatcher = RegExp(r'\u001B\[[^m]+m');

String ansiStripped(String it) => it.replaceAll(ansiMatcher, '');

/// Throw an [ArgumentError] with [message] and [value] if [check] is false.
require(bool check, String message, String value) {
  if (!check) {
    throw ArgumentError(message, value);
  }
}

/// Execute [block], ignoring any exceptions, merely logging them via [logError].
safely(Function block) {
  try {
    block();
  } catch (it, trace) {
    logError("safely failed - ignored: $it", trace);
  }
}

extension ConsulIterableOps<E> on Iterable<E> {
  Iterable<E> operator +(Iterable<E> other) sync* {
    for (final e in this) {
      yield e;
    }
    for (final o in other) {
      yield o;
    }
  }
}

extension ConsulKotlinEsqueOps<T> on T {
  /// Kotlin-esque "operator" to take `this` if [condition] is `true`, or else return `null`.
  T? takeIf(bool condition) => condition ? this : null;

  /// Kotlin-esque "operator" to execute [transform] on `this`. Allows `?.let(...)` instead of
  /// `if (something != null) something."transform"` in case the latter reads worse.
  R let<R>(R Function(T) transform) => transform(this);

  /// Kotlin-esque "operator" to execute [func] on `this`, but returning `this`.
  T also(Function(T) func) {
    func(this);
    return this;
  }
}

extension ConsulListExtensions<E> on List<E> {
  /// Drop first [count] items from `this` list, returning the remainder as a new list.
  List<E> drop(int count) => sublist(min(count, length));

  /// Drop last [count] items from `this` list, returning the remainder as a new list.
  List<E> dropLast(int count) => sublist(0, max(0, length - count));

  /// Find first item in this list fulfilling [predicate]. Will not evaluate on the remaining
  /// items after the first match is found.
  E? firstWhereOrNull(bool Function(E) predicate) {
    for (final it in this) {
      if (predicate(it)) return it;
    }
    return null;
  }

  /// Find last item in this list fulfilling [predicate]. Will not evaluate on the remaining
  /// items before the found match.
  E? lastWhereOrNull(bool Function(E) predicate) {
    for (final it in reversed) {
      if (predicate(it)) return it;
    }
    return null;
  }

  /// Returns a list of all non-null items returned by applying [predicate] on the items of this
  /// list.
  List<R> mapNotNull<R>(R? Function(E) predicate) {
    final result = <R>[];
    for (final it in this) {
      final mapped = predicate(it);
      if (mapped != null) result.add(mapped);
    }
    return result;
  }

  /// Take [count] items from the front of this list, returning the result as a list.
  List<E> take_(int count) => take(count).toList();

  /// Take [count] items from the end of this list, returning the result as a list.
  List<E> takeLast(int count) => sublist(max(0, length - count));
}

extension ConsulHexList on List<int> {
  /// Convert the given `List<int>` into a hex string representation of the low 8 bits of each int.
  String toByteHexString({String delimiter = ""}) =>
      map((e) => e.toHex(2).toUpperCase()).join(delimiter);
}

extension ConsulIntExtensions on int {
  // Turn this int into a hex string, limiting to the given [length]. For
  // bytes the length would be 2 etc.
  String toHex(int length) => toRadixString(16).padLeft(length).take(length);

  /// Turn this int into a [Duration] of milliseconds.
  Duration get millis => Duration(milliseconds: this);

  /// Turn this int into a [Duration] of minutes.
  Duration get minutes => Duration(minutes: this);

  /// Turn this int into a [Duration] of seconds.
  Duration get seconds => Duration(seconds: this);
}

extension ConsulStringExtensions on String {
  /// Remove the first [count] bytes from this [String]. Returns empty
  /// [String] if [count] >= [length].
  String drop(int count) => substring(min(count, length));

  /// Remove the last [count] bytes from this [String]. Returns empty
  /// [String] if [count] >= [length].
  String dropLast(int count) => substring(0, max(0, length - count));

  /// Take the first [count] characters from this. Ignoring special unicode character handling.
  /// This operates on the "pure bytes" only.
  String take(int count) => substring(0, min(count, length));

  /// Take the last [count] characters from this. Ignoring special unicode character handling.
  /// This operates on the "pure bytes" only.
  String takeLast(int count) => substring(max(length - count, 0), length);

  /// ANSI aware take variant. Includes all ANSI sequences without counting
  /// them towards [count].
  String ansiTake(int count) {
    var at = 0;
    final it = StringBuffer();
    while (ansiStripped(it.toString()).length < count) {
      var match = ansiMatcher.matchAsPrefix(this, at);
      if (match != null) {
        it.write(match.group(0));
        at = match.end;
      } else {
        it.write(this[at]);
        at++;
      }
    }
    return it.toString();
  }

  /// Pad string to the left, ignoring embedded ansi sequences.
  String ansiPadLeft(int length, {String pad = " "}) {
    final it = StringBuffer(this);
    while (ansiStripped(it.toString()).length < length) {
      final swap = it.toString();
      it.clear();
      it.write(pad);
      it.write(swap);
    }
    return it.toString();
  }

  /// Pad string to the right, ignoring embedded ansi sequences.
  String ansiPadRight(int length, {String pad = " "}) {
    final it = StringBuffer(this);
    while (ansiStripped(it.toString()).length < length) {
      it.write(pad);
    }
    return it.toString();
  }

  /// Pad string from both sides, ignoring embedded ansi sequences.
  String ansiPad(int length, {String pad = " "}) {
    var it = this;
    while (it.ansiLength < length) {
      it = pad + it + pad;
    }
    return it.ansiTake(length);
  }

  /// Removes all embedded ANSI sequences.
  String stripped() => ansiStripped(this);

  /// Length without ANSI sequences.
  int get ansiLength => stripped().length;

// TODO Revisit this naming madness.. :-D
}
