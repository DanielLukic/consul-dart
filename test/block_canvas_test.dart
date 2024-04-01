import 'package:consul/src/block_canvas.dart';
import 'package:test/test.dart';

void main() {
  test("draws top left block", () {
    final canvas = BlockCanvas(4, 2);
    canvas.set(0, 0);
    final actual = canvas.frame("");
    expect(actual, equals("▘ "));
  });

  test("draws top right block", () {
    final canvas = BlockCanvas(4, 2);
    canvas.set(1, 0);
    final actual = canvas.frame("");
    expect(actual, equals("▝ "));
  });

  test("clears top left block - clear before set", () {
    final canvas = BlockCanvas(4, 2);
    canvas.set(0, 0);
    canvas.unset(0, 0);
    canvas.set(1, 0);
    final actual = canvas.frame("");
    expect(actual, equals("▝ "));
  });

  test("clears top left block - clear after set", () {
    final canvas = BlockCanvas(4, 2);
    canvas.set(0, 0);
    canvas.set(1, 0);
    canvas.unset(0, 0);
    final actual = canvas.frame("");
    expect(actual, equals("▝ "));
  });

  test("draws bottom block", () {
    final canvas = BlockCanvas(4, 2);
    canvas.set(0, 1);
    canvas.set(1, 1);
    final actual = canvas.frame("");
    expect(actual, equals("▄ "));
  });

  test("draws full block", () {
    final canvas = BlockCanvas(4, 2);
    canvas.set(0, 0);
    canvas.set(1, 0);
    canvas.set(0, 1);
    canvas.set(1, 1);
    final actual = canvas.frame("");
    expect(actual, equals("█ "));
  });
}
