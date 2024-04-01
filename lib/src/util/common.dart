import 'dart:math';

import 'log.dart';

require(bool check, String message, String value) {
  if (!check) {
    throw ArgumentError(message, value);
  }
}

safely(Function block) {
  try {
    block();
  } catch (it) {
    logError("safely failed- ignored: $it");
  }
}

extension TakeIf<T> on T {
  T? takeIf(bool condition) => condition ? this : null;

  R let<R>(R Function(T) transform) => transform(this);

  T also(Function(T) transform) {
    transform(this);
    return this;
  }
}

extension ListExtensions<E> on List<E> {
  List<E> drop(int count) => sublist(min(count, length));

  List<E> dropLast(int count) => sublist(0, max(0, length - count));

  E? lastWhereOrNull(bool Function(E) predicate) => where(predicate).lastOrNull;

  List<E> take_(int count) => take(count).toList();

  List<E> takeLast(int count) => sublist(max(0, length - count));
}

extension HexList on List<int> {
  String toByteHexString({String delimiter = ""}) =>
      map((e) => e.toRadixString(16).padLeft(2).take(2).toUpperCase()).join(delimiter);
}

extension IntExtensions on int {
  Duration get millis => Duration(milliseconds: this);

  Duration get minutes => Duration(minutes: this);

  Duration get seconds => Duration(seconds: this);
}

extension StringExtensions on String {
  String take(int count) => substring(0, min(count, length));

  String takeLast(int count) => substring(max(length - count, 0), length);
}

class Disposable {
  final Function _disposable;

  Disposable(this._disposable);

  void dispose() => _disposable();
}
