import 'package:dart_consul/common.dart';
import 'package:test/test.dart';

void main() {
  test("drops no characters", () {
    //given
    final it = "test";
    //when
    final actual = it.drop(0);
    //then
    expect(actual, equals(it));
  });

  test("drops first characters", () {
    //given
    final it = "test";
    //when
    final actual = it.drop(2);
    //then
    expect(actual, equals("st"));
  });

  test("drops all characters", () {
    //given
    final it = "test";
    //when
    final actual = it.drop(4);
    //then
    expect(actual, equals(""));
  });

  test("drops all, but not more, characters", () {
    //given
    final it = "test";
    //when
    final actual = it.drop(5);
    //then
    expect(actual, equals(""));
  });
}
