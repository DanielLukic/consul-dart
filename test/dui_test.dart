import 'package:dart_consul/dart_consul.dart';
import 'package:dart_consul/src/util/common.dart';
import 'package:test/test.dart';

import 'helper.dart';

strip(String? it) => ansiStripped(it!);

void main() {
  late MockWindowHandling out;

  setUp(() {
    out = MockWindowHandling();
  });

  DuiLayout sut(DuiElement it) {
    final sut = DuiLayout(it);
    final window = minimalWindow(f: {WindowFlag.undecorated});
    window.redrawBuffer = sut.redraw;
    out.addWindow(window);
    return sut;
  }

  test("draws simple button", () {
    //given
    sut(DuiButton("TEXT"));
    //when
    out.drawFrame();
    //then
    expect(out.line(0), startsWith("TEXT "));
  });

  test("draws simple text", () {
    //given
    sut(DuiText("TEXT"));
    //when
    out.drawFrame();
    //then
    expect(out.line(0), startsWith("TEXT "));
  });

  test("draws simple title", () {
    //given
    sut(DuiTitle("TITLE"));
    //when
    out.drawFrame();
    //then
    expect(out.line(0), startsWith("TITLE "));
  });

  test("draws title with padding", () {
    //given
    sut(DuiPadding(DuiTitle("TITLE"), left: 2));
    //when
    out.drawFrame();
    //then
    expect(out.line(0), startsWith("  TITLE "));
  });

  test("draws title with border", () {
    //given
    sut(DuiBorder(DuiTitle("TITLE"), style: simpleBorderStyle('*')));
    //when
    out.drawFrame();
    //then
    expect(out.line(0), startsWith("*******"));
    expect(out.line(1), startsWith("*TITLE*"));
    expect(out.line(2), startsWith("*******"));
  });

  test("draws column", () {
    //given
    sut(DuiColumn([DuiTitle("TITLE"), DuiText("TEXT")]));
    //when
    out.drawFrame();
    //then
    expect(out.line(0), startsWith("TITLE "));
    expect(out.line(1), startsWith("TEXT  "));
  });

  test("draws column with border and padding", () {
    //given
    sut(DuiBorder(
      DuiPadding.hv(
        h: 1,
        v: 0,
        wrapped: DuiColumn(
          [
            DuiPadding(DuiTitle("TITLE"), bottom: 1),
            DuiText("TEXT"),
          ],
        ),
      ),
      style: simpleBorderStyle('*'),
    ));
    //when
    out.drawFrame();
    //then
    expect(out.line(1), startsWith("* TITLE *"));
  });

  test("calculates stripped size", () {
    //given
    final sut = DuiBorder(
      DuiPadding.hv(
        h: 1,
        v: 0,
        wrapped: DuiColumn(
          [
            DuiPadding(DuiTitle("TITLE"), bottom: 1),
            DuiText("TEXT"),
          ],
        ),
      ),
      style: simpleBorderStyle('*'),
    );
    //then
    expect(sut.width(), equals(9));
  });

  test("actual dialog", () {
    final layout = DuiLayout(
      DuiBorder(
        DuiPadding.hv(
          h: 2,
          v: 1,
          wrapped: DuiColumn(
            [
              DuiPadding(DuiTitle('Set alert'), bottom: 1),
              DuiText.fromLines([
                'Specify price as absolute value or +/-.',
                'Optionally use % with either absolute or +/-.'
              ]),
              DuiText(''),
              DuiRow(
                [
                  DuiTextInput(limitLength: 20, preset: "10.00"),
                  DuiSpace(2),
                  DuiButton("Create [<Return>]"),
                ],
              )
            ],
          ),
        ),
      ),
    );
    final actual = layout.redraw();
    print(actual);
  });

  test('border provides focusable element', () {
    //given
    final container = DuiBorder(DuiTextInput());
    //when
    final actual = container.focusables();
    //then
    expect(actual.single, isA<DuiTextInput>());
  });

  test('column provides focusable elements', () {
    //given
    final container = DuiColumn([DuiTextInput(), DuiTextInput()]);
    //when
    final actual = container.focusables();
    //then
    expect(actual.length, equals(2));
  });
}
