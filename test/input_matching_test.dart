import 'package:dart_consul/dart_consul.dart';
import 'package:dart_consul/src/consul/con_io/extensions.dart';
import 'package:dart_consul/src/consul/con_io/input_matching.dart';
import 'package:test/test.dart';

// 1B 5B 3C 33 32 3B 36 39 3B 32 30 4D 1B 5B 3C 30 3B 36 39 3B 32 30 6D
// <ESC>[<32;69;20M<ESC>[<0;69;20m

extension on String {
  List<int> fromHexString() =>
      split(' ').map((e) => int.parse(e, radix: 16)).toList();
}

void main() {
  late TestMatching sut;

  setUp(() {
    sut = TestMatching();
  });

  test('parses hex data', () {
    //given
    final input = '1B 5B 3C 33 32 3B 36 39 3B 32 30 4D';
    //when
    final actual = input.fromHexString();
    //then
    expect(actual, containsAllInOrder([27]));
    expect(actual.length, equals(12));
  });

  test('provides expected printable representation', () {
    //given
    final input = '1B 5B 3C 33 32 3B 36 39 3B 32 30 4D';
    //when
    final bytes = input.fromHexString();
    final actual = bytes.printable;
    //then
    expect(actual, equals('<ESC>[<32;69;20M'));
  });

  test('skips exact mouse event length', () {
    //given
    final bytes = '1B 5B 3C 33 32 3B 36 39 3B 32 30 4D'.fromHexString();
    final printable = '<ESC>[<32;69;20M';
    //when
    final actual = sut.matchEvent(bytes, printable);
    //then
    expect(actual.$1, isA<MouseEvent>());
    expect(actual.$2, equals(12));
  });

  test('handles two events properly', () {
    //given
    final bytes = ''
            '1B 5B 3C 33 32 3B 36 39 3B 32 30 4D '
            '1B 5B 3C 30 3B 36 39 3B 32 30 6D'
        .fromHexString();
    final printable = '<ESC>[<32;69;20M<ESC>[<0;69;20m';
    //when
    final actual = sut.matchEvent(bytes, printable);
    //then
    expect(actual.$1, isA<MouseEvent>());
    expect(actual.$2, equals(12));
  });
}
