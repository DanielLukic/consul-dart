import 'package:dart_consul/dart_consul.dart';
import 'package:dart_consul/src/util/common.dart';

strip(String? it) => ansiStripped(it!);

Window minimalWindow({String? n, Position? p, Size? s, Set<WindowFlag>? f}) =>
    Window(
      "id",
      n ?? "name",
      position: p ?? AbsolutePosition(0, 0),
      size: WindowSize.min(s ?? Size(20, 5)),
      flags: f,
      redraw: () => "X",
    );

fromTopLeft(int xo, int yo) =>
    RelativePosition.fromTopLeft(xOffset: xo, yOffset: yo);

fromBottomRight(int xo, int yo) =>
    RelativePosition.fromBottomRight(xOffset: xo, yOffset: yo);

extension BufferExtensions on Buffer {
  void dump() => print(render());

  List<String> raw() => render().split('\n');

  List<String> lines() => render().stripped().split('\n');
}
