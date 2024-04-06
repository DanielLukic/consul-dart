import 'package:dart_consul/dart_consul.dart';
import 'package:dart_consul/src/util/common.dart';
import 'package:test/test.dart';

extension on MockWindowHandling {
  void dump() {
    print(lines.values.join("\n"));
    print("");
  }
}

strip(String? it) => ansiStripped(it!);

void main() {
  setUp(() {});

  test("draws all output lines", () {
    final sut = MockWindowHandling();
    sut.drawFrame();
    expect(sut.lines.length, equals(10));
  });

  test("draws background", () {
    final sut = MockWindowHandling();
    sut.drawFrame();
    expect(sut.lines[0], "".padRight(40, sut.background));
  });

  test("draws window titlebar", () {
    final sut = MockWindowHandling();
    sut.addWindow(minimalWindow());
    sut.drawFrame();
    sut.dump();
    expect(sut.lines[0], startsWith("≡ name ≡≡≡ [_][O][X]\x1B[0m"));
  });

  test("draws window resize control", () {
    final sut = MockWindowHandling();
    sut.addWindow(minimalWindow());
    sut.drawFrame();
    sut.dump();
    expect(sut.lines[5], startsWith("                   ◢\x1B[0m"));
  });

  test("draws auto centered window", () {
    final sut = MockWindowHandling();
    sut.addWindow(minimalWindow(p: Position.unsetInitially));
    sut.drawFrame();
    sut.dump();
    expect(strip(sut.lines[2]!), startsWith("░░░░░░░░░░≡ name ≡≡≡ [_][O][X]"));
  });

  test("draws window with top left relative position", () {
    final sut = MockWindowHandling();
    sut.addWindow(
        minimalWindow(p: RelativePosition.fromTopLeft(xOffset: 1, yOffset: 1)));
    sut.drawFrame();
    sut.dump();
    expect(strip(sut.lines[1]!), startsWith("░≡ name ≡≡≡ [_][O][X]"));
  });

  test("draws window with bottom right relative position", () {
    final sut = MockWindowHandling();
    sut.addWindow(minimalWindow(
        p: RelativePosition.fromBottomRight(xOffset: -19, yOffset: -3)));
    sut.drawFrame();
    sut.dump();
    expect(strip(sut.lines[1]), startsWith("░≡ name ≡≡≡ [_][O][X]"));
  });
}

Window minimalWindow({Position? p}) => Window(
      "id",
      "name",
      position: p ?? AbsolutePosition(0, 0),
      size: WindowSize.min(Size(20, 5)),
      redraw: () => "X",
    );
