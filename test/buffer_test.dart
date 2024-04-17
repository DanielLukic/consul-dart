import 'package:dart_consul/dart_consul.dart';
import 'package:dart_consul/src/util/common.dart';
import 'package:test/test.dart';

import 'helper.dart';

final reset = ansiReset;
final red = "".red().substring(0, 5);

void main() {
  test("fills entire buffer", () {
    final sut = Buffer(5, 1);
    sut.fill(32);
    final actual = sut.frame();
    expect(actual, equals("     "));
  });

  test("draws data into buffer", () {
    final sut = Buffer(5, 1);
    sut.fill(32);
    sut.drawBuffer(1, 0, "###");
    final actual = ansiStripped(sut.frame());
    expect(actual, equals(" ### "));
  });

  test("puts reset before drawn data", () {
    final sut = Buffer(5, 1);
    sut.fill(32);
    sut.drawBuffer(1, 0, "###");
    final actual = sut.frame();
    expect(actual, startsWith(" $reset###"));
  });

  test("puts reset after drawn data", () {
    final sut = Buffer(5, 1);
    sut.fill(32);
    sut.drawBuffer(1, 0, "###");
    final actual = sut.frame();
    expect(actual, endsWith("###$reset "));
  });

  test("clips data outside above", () {
    final sut = Buffer(5, 1);
    sut.fill(32);
    sut.drawBuffer(1, -1, "###");
    final actual = sut.frame();
    expect(actual, equals("     "));
  });

  test("clips data outside below", () {
    final sut = Buffer(5, 1);
    sut.fill(32);
    sut.drawBuffer(1, 1, "###");
    final actual = sut.frame();
    expect(actual, equals("     "));
  });

  test("clips data outside left", () {
    final sut = Buffer(5, 1);
    sut.fill(32);
    sut.drawBuffer(-3, 0, "###");
    final actual = sut.frame();
    expect(actual, equals("     "));
  });

  test("clips data outside right", () {
    final sut = Buffer(5, 1);
    sut.fill(32);
    sut.drawBuffer(5, 0, "###");
    final actual = sut.frame();
    expect(actual, equals("     "));
  });

  test("clips data above", () {
    final sut = Buffer(5, 2);
    sut.fill(32);
    sut.drawBuffer(1, -1, "###\n###\n");
    final actual = ansiStripped(sut.frame());
    expect(actual, equals(" ### \n     "));
  });

  test("clips data on the left side", () {
    final sut = Buffer(5, 1);
    sut.fill(32);
    sut.drawBuffer(-2, 0, "###");
    final actual = ansiStripped(sut.frame());
    expect(actual, equals("#    "));
  });

  test("omits ansi reset at start of clipped data", () {
    final sut = Buffer(5, 1);
    sut.fill(32);
    sut.drawBuffer(-2, 0, "###");
    final actual = sut.frame();
    expect(actual, equals("#$reset    "));
  });

  test("writes color ansi sequence", () {
    final sut = Buffer(5, 1);
    sut.fill(32);
    sut.drawBuffer(0, 0, "!!!".red());
    final actual = sut.frame();
    expect(actual, equals("$red!!!$reset  "));
  });

  test("moves overwritten ansi after replaced block", () {
    final sut = Buffer(5, 1);
    sut.fill(32);
    sut.drawBuffer(0, 0, "!!!".red());
    sut.drawBuffer(-2, 0, "###");
    final actual = sut.frame();
    expect(actual, equals("#$reset$red!!$reset  "));
  });

  test("moves overwritten ansi after replaced block", () {
    final sut = Buffer(5, 1);
    sut.fill(32);
    sut.drawBuffer(1, 0, "!!!".red());
    sut.drawBuffer(2, 0, "#");
    final actual = sut.frame();
    expect(actual, equals(" $reset$red!$reset#$reset$reset$red!$reset "));
    // we have two resets here: one is from the new data, the other one from the collected ansi
    // sequence. thought about removing the duplication. but after some more thought i decided to
    // keep it. it does reflect what is going on. maybe revisit at some point...
  });

  test("preserves clipped ansi", () {
    final sut = Buffer(5, 1);
    sut.fill(32);
    sut.drawBuffer(-2, 0, "!!!".red());
    final actual = sut.frame();
    expect(actual, equals("$red!$reset    "));
  });

  test("draws border", () {
    final sut = Buffer(5, 3);
    sut.drawBorder(0, 0, 5, 3, simpleBorderStyle('*'));
    sut.dump();
    expect(sut.lines(), containsAllInOrder(["*****", "*   *", "*****"]));
  });
}
