import 'package:dart_consul/dart_consul.dart';
import 'package:test/test.dart';

import 'helper.dart';

void main() {
  late MockWindowHandling wm;

  setUp(() => wm = MockWindowHandling());

  test('draws scrolled content with few lines only', () {
    //given
    final lines = List.generate(5, (index) => 'Line ${index + 1}').join('\n');
    final window = minimalWindow(s: Size(20, 7));
    scrolled(window, () => lines);
    wm.addWindow(window);
    //when
    wm.drawFrame();
    //then
    expect(wm.line(1), startsWith('Line 1'));
  });

  test('draws scrolled content with more lines', () {
    //given
    final lines = List.generate(10, (index) => 'Line ${index + 1}').join('\n');
    final window = minimalWindow(s: Size(20, 7));
    scrolled(window, () => lines);
    wm.addWindow(window);
    //when
    wm.drawFrame();
    //then
    expect(wm.line(7), startsWith(' ▼ ▼ ▼ '));
  });

  test('draws header', () {
    //given
    final lines = List.generate(10, (index) => 'Line ${index + 1}').join('\n');
    final window = minimalWindow(s: Size(20, 7));
    scrolled(window, () => lines, header: 'Header');
    wm.addWindow(window);
    //when
    wm.drawFrame();
    //then
    expect(wm.line(1), startsWith('Header'));
  });

  test('draws first line below header', () {
    //given
    final lines = List.generate(10, (index) => 'Line ${index + 1}').join('\n');
    final window = minimalWindow(s: Size(20, 7));
    scrolled(window, () => lines, header: 'Header');
    wm.addWindow(window);
    //when
    wm.drawFrame();
    //then
    expect(wm.line(2), startsWith('Line 1'));
  });
}
