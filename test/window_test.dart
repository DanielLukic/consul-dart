import 'package:dart_consul/dart_consul.dart';
import 'package:dart_consul/src/util/common.dart';
import 'package:test/test.dart';

strip(String? it) => ansiStripped(it!);

void main() {
  late MockWindowHandling sut;

  setUp(() => sut = MockWindowHandling());

  test("draws window titlebar", () {
    //given
    sut.addWindow(minimalWindow());
    //when
    sut.drawFrame();
    //then
    expect(sut.line(0), startsWith("≡ name ≡≡≡ [_][O][X]"));
  });

  test("draws ellipsis for long title", () {
    //given
    sut.addWindow(minimalWindow(n: "Somewhat too long"));
    //when
    sut.drawFrame();
    //then
    expect(sut.line(0), startsWith("≡ Somewh…≡ [_][O][X]"));
  });

  // bug fix
  test("draws all controls for non-resizable window", () {
    //given
    final window = minimalWindow();
    window.flags.remove(WindowFlag.resizable);
    sut.addWindow(window);
    //when
    sut.drawFrame();
    //then
    expect(sut.line(0), startsWith("≡ name ≡≡≡ [_][O][X]"));
  });

  test("draws window resize control", () {
    //given
    sut.addWindow(minimalWindow());
    //when
    sut.drawFrame();
    //then
    expect(sut.line(5), startsWith("                   ◢"));
  });

  test("draws auto centered window", () {
    //given
    sut.addWindow(minimalWindow(p: Position.unsetInitially));
    //when
    sut.drawFrame();
    //then
    expect(sut.line(2), startsWith("░░░░░░░░░░≡ name ≡≡≡ [_][O][X]"));
  });

  test("draws window with top left relative position", () {
    //given
    sut.addWindow(minimalWindow(p: fromTopLeft(1, 1)));
    //when
    sut.drawFrame();
    //then
    expect(sut.line(1), startsWith("░≡ name ≡≡≡ [_][O][X]"));
  });

  test("draws window with bottom right relative position", () {
    //given
    sut.addWindow(minimalWindow(p: fromBottomRight(-19, -3)));
    //when
    sut.drawFrame();
    //then
    expect(sut.line(1), startsWith("░≡ name ≡≡≡ [_][O][X]"));
  });
}

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
