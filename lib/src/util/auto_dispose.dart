import 'dart:async';

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
