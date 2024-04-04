import 'dart:async';
import 'dart:math';

import 'log.dart';

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
  } catch (it) {
    logError("safely failed - ignored: $it");
  }
}

extension KotlinEsqueOps<T> on T {
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

extension ListExtensions<E> on List<E> {
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

extension HexList on List<int> {
  /// Convert the given `List<int>` into a hex string representation of the low 8 bits of each int.
  String toByteHexString({String delimiter = ""}) =>
      map((e) => e.toRadixString(16).padLeft(2).take(2).toUpperCase()).join(delimiter);
}

extension IntExtensions on int {
  /// Turn this int into a [Duration] of milliseconds.
  Duration get millis => Duration(milliseconds: this);

  /// Turn this int into a [Duration] of minutes.
  Duration get minutes => Duration(minutes: this);

  /// Turn this int into a [Duration] of seconds.
  Duration get seconds => Duration(seconds: this);
}

extension StringExtensions on String {
  /// Take the first [count] characters from this. Ignoring special unicode character handling.
  /// This operates on the "pure bytes" only.
  String take(int count) => substring(0, min(count, length));

  /// Take the last [count] characters from this. Ignoring special unicode character handling.
  /// This operates on the "pure bytes" only.
  String takeLast(int count) => substring(max(length - count, 0), length);
}

/// Generic "disposable" to dispose/cancel/free some wrapped object.
class Disposable {
  final Function _disposable;

  /// Wrap some dispose call into this disposable for later disposition.
  Disposable(this._disposable);

  /// Dispose the object wrapped by this disposable.
  void dispose() => _disposable();
}

/// Auto-dispose system to manage [Disposable] instances and dispose all of them at once, or
/// specific ones individually. Uses [String] tags to identify disposables. By assigning a new
/// disposable using the same tag, any previously assigned disposable for the same tag is
/// auto-disposed. Therefore, effectively replacing the previous disposable.
mixin AutoDispose {
  final _disposables = <String, Disposable>{};

  /// Dispose all [Disposable]s currently registered with this [AutoDispose] instance.
  void disposeAll() {
    for (var it in _disposables.values) {
      it.dispose();
    }
  }

  /// Dispose the [Disposable] associated with the given [tag]. Nop if nothing registered for this
  /// tag.
  void dispose(String tag) => _disposables[tag]?.dispose();

  /// Set up a [Disposable] for the given [something], using the given [tag]. If the tag already
  /// has a [Disposable] assigned, the assigned one is disposed and the new one replaces it.
  /// Otherwise, the new one is assigned to this tag. [something] is turned into a [Disposable]
  /// by inspecting the [Object.runtimeType]. Raises an [ArgumentError] if the given [something]
  /// has an unsupported type. In that case, wrap it into a [Disposable] before passing it to
  /// [autoDispose].
  void autoDispose(String tag, dynamic something) {
    final Disposable it;
    if (something is Timer) {
      it = Disposable(() => something.cancel());
    } else if (something is StreamController) {
      it = Disposable(() => something.close());
    } else if (something is StreamSubscription) {
      it = Disposable(() => something.cancel());
    } else if (something is Disposable) {
      it = something;
    } else {
      throw ArgumentError("${something.runtimeType} not supported (yet)", "something");
    }
    _disposables.remove(tag)?.dispose();
    _disposables[tag] = it;
  }
}
