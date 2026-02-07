import 'package:bifrosted/bifrosted.dart';
import 'package:test/test.dart';

void main() {
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

  group('DeserializationException', () {
    test('has descriptive message', () {
      final exception = DeserializationException('test error');
      expect(exception.toString(), contains('test error'));
    });
  });

  group('bifrostLogger', () {
    test('default logger is available', () {
      expect(bifrostLogger, isA<Logger>());
    });

    test('logger can be replaced', () {
      final customLogger = Logger(level: Level.warning);
      bifrostLogger = customLogger;
      expect(bifrostLogger, equals(customLogger));
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
