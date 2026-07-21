import 'dart:typed_data';

import 'package:skir_client/skir_client.dart';
import 'package:test/test.dart';

const _prefix = [0x73, 0x6b, 0x69, 0x72];
final _isJavaScript = identical(1, 1.0);

Uint8List _payload(int wire, List<int> words) {
  return Uint8List.fromList([..._prefix, wire, ...words]);
}

void main() {
  test('decodes current and pre-epoch timestamps', () {
    final current = Serializers.timestamp.fromBytes(
      _payload(239, [8, 196, 199, 224, 152, 1, 0, 0]),
    );
    final preEpoch = Serializers.timestamp.fromBytes(
      _payload(239, [24, 252, 255, 255, 255, 255, 255, 255]),
    );

    expect(current.millisecondsSinceEpoch, 1756117845000);
    expect(preEpoch.millisecondsSinceEpoch, -1000);
  });

  test('decodes exact JavaScript integer boundaries', () {
    expect(
      Serializers.hash64.fromBytes(
        _payload(234, [255, 255, 255, 255, 255, 255, 31, 0]),
      ),
      BigInt.parse('9007199254740991'),
    );
    expect(
      Serializers.int64.fromBytes(_payload(238, [1, 0, 0, 0, 0, 0, 224, 255])),
      BigInt.parse('-9007199254740991').toInt(),
    );
  });

  test('handles values outside the JavaScript exact integer range', () {
    final positive = _payload(238, [0, 0, 0, 0, 0, 0, 32, 0]);
    final negative = _payload(238, [0, 0, 0, 0, 0, 0, 224, 255]);

    if (_isJavaScript) {
      expect(
        () => Serializers.int64.fromBytes(positive),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => Serializers.int64.fromBytes(negative),
        throwsA(isA<UnsupportedError>()),
      );
      return;
    }

    expect(
      Serializers.int64.fromBytes(positive),
      BigInt.parse('9007199254740992').toInt(),
    );
    expect(
      Serializers.int64.fromBytes(negative),
      BigInt.parse('-9007199254740992').toInt(),
    );
  });

  test('preserves native signed int64 boundaries', () {
    if (_isJavaScript) {
      return;
    }

    expect(
      Serializers.int64.fromBytes(
        _payload(238, [255, 255, 255, 255, 255, 255, 255, 127]),
      ),
      BigInt.parse('9223372036854775807').toInt(),
    );
    expect(
      Serializers.int64.fromBytes(_payload(238, [0, 0, 0, 0, 0, 0, 0, 128])),
      BigInt.parse('-9223372036854775808').toInt(),
    );
  });
}
