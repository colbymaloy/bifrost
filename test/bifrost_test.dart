import 'package:bifrost/bifrost.dart';
import 'package:test/test.dart';

void main() {
  group('BifrostLogger', () {
    test('NoOpLogger does nothing', () {
      const logger = NoOpLogger();
      // Should not throw
      logger.info('test');
      logger.warning('test');
      logger.error('test');
      logger.trace('test');
    });

    test('PrintLogger prints messages', () {
      const logger = PrintLogger();
      // Should not throw
      logger.info('info message');
      logger.warning('warning message');
      logger.error('error message', error: Exception('test'));
      logger.trace('trace message');
    });
  });

  group('SystemNotifier', () {
    test('NoOpNotifier does nothing', () {
      const notifier = NoOpNotifier();
      // Should not throw
      notifier.onNetworkError();
      notifier.onUnauthorized();
      notifier.onForbidden();
      notifier.onServerError(500, 'error');
      notifier.onApiError(400, 'bad request');
    });
  });

  group('Deserializer', () {
    test('deserialize converts JSON to model', () {
      final json = {'name': 'Odin', 'age': 1000};
      final result = Deserializer.deserialize(json, _TestModel.fromJson);

      expect(result.name, 'Odin');
      expect(result.age, 1000);
    });

    test('deserializeList converts JSON array to list', () {
      final jsonArray = [
        {'name': 'Odin', 'age': 1000},
        {'name': 'Thor', 'age': 500},
      ];
      final result =
          Deserializer.deserializeList(jsonArray, _TestModel.fromJson);

      expect(result.length, 2);
      expect(result[0].name, 'Odin');
      expect(result[1].name, 'Thor');
    });

    test('deserialize throws on invalid JSON', () {
      final json = {'invalid': 'data'};
      expect(
        () => Deserializer.deserialize(json, _TestModel.fromJson),
        throwsA(isA<DeserializationException>()),
      );
    });
  });
}

class _TestModel {
  _TestModel({required this.name, required this.age});

  factory _TestModel.fromJson(Map<String, dynamic> json) {
    return _TestModel(
      name: json['name'] as String,
      age: json['age'] as int,
    );
  }

  final String name;
  final int age;
}
