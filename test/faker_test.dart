import 'package:bifrosted/bifrosted.dart';
import 'package:test/test.dart';

void main() {
  group('Faker', () {
    group('strings', () {
      test('uuid generates valid format', () {
        final uuid = Faker.uuid();
        expect(uuid.length, 36);
        expect(uuid.contains('-'), isTrue);
        expect(uuid.split('-').length, 5);
      });

      test('name returns non-empty string', () {
        final name = Faker.name();
        expect(name.isNotEmpty, isTrue);
        expect(name.contains(' '), isTrue);
      });

      test('firstName returns non-empty string', () {
        expect(Faker.firstName().isNotEmpty, isTrue);
      });

      test('lastName returns non-empty string', () {
        expect(Faker.lastName().isNotEmpty, isTrue);
      });

      test('email contains @ symbol', () {
        final email = Faker.email();
        expect(email.contains('@'), isTrue);
        expect(email.contains('.'), isTrue);
      });

      test('username is non-empty', () {
        expect(Faker.username().isNotEmpty, isTrue);
      });

      test('string generates correct length', () {
        expect(Faker.string(length: 5).length, 5);
        expect(Faker.string(length: 20).length, 20);
      });

      test('sentence ends with period', () {
        expect(Faker.sentence().endsWith('.'), isTrue);
      });

      test('paragraph contains multiple sentences', () {
        final paragraph = Faker.paragraph(sentences: 3);
        // Count periods (each sentence ends with one)
        final periodCount = '.'.allMatches(paragraph).length;
        expect(periodCount, greaterThanOrEqualTo(3));
      });
    });

    group('numbers', () {
      test('integer respects bounds', () {
        for (var i = 0; i < 100; i++) {
          final value = Faker.integer(min: 10, max: 20);
          expect(value, greaterThanOrEqualTo(10));
          expect(value, lessThanOrEqualTo(20));
        }
      });

      test('decimal respects bounds and precision', () {
        for (var i = 0; i < 100; i++) {
          final value = Faker.decimal(min: 1.0, max: 2.0, decimals: 2);
          expect(value, greaterThanOrEqualTo(1.0));
          expect(value, lessThanOrEqualTo(2.0));
        }
      });

      test('boolean returns true or false', () {
        final values = List.generate(100, (_) => Faker.boolean());
        expect(values.contains(true), isTrue);
        expect(values.contains(false), isTrue);
      });
    });

    group('dates', () {
      test('dateTime returns valid DateTime', () {
        final date = Faker.dateTime();
        expect(date, isA<DateTime>());
      });

      test('dateTime respects bounds', () {
        final min = DateTime(2020);
        final max = DateTime(2021);
        for (var i = 0; i < 100; i++) {
          final date = Faker.dateTime(min: min, max: max);
          expect(date.isAfter(min) || date.isAtSameMomentAs(min), isTrue);
          expect(date.isBefore(max) || date.isAtSameMomentAs(max), isTrue);
        }
      });

      test('dateTimeIso returns ISO8601 format', () {
        final iso = Faker.dateTimeIso();
        expect(DateTime.tryParse(iso), isNotNull);
      });

      test('pastDate is in the past', () {
        final date = Faker.pastDate();
        expect(date.isBefore(DateTime.now()), isTrue);
      });

      test('futureDate is in the future', () {
        final date = Faker.futureDate();
        expect(date.isAfter(DateTime.now()), isTrue);
      });
    });

    group('collections', () {
      test('element returns item from list', () {
        final options = ['a', 'b', 'c'];
        final value = Faker.element(options);
        expect(options.contains(value), isTrue);
      });

      test('list generates correct count', () {
        final items = Faker.list(() => Faker.integer(), count: 10);
        expect(items.length, 10);
      });
    });

    group('json', () {
      test('fakeJson contains expected fields', () {
        final json = Faker.fakeJson();
        expect(json.containsKey('id'), isTrue);
        expect(json.containsKey('name'), isTrue);
        expect(json.containsKey('email'), isTrue);
        expect(json.containsKey('username'), isTrue);
        expect(json.containsKey('age'), isTrue);
        expect(json.containsKey('active'), isTrue);
        expect(json.containsKey('createdAt'), isTrue);
      });

      test('fakeJsonList generates correct count', () {
        final list = Faker.fakeJsonList(count: 5);
        expect(list.length, 5);
        for (final item in list) {
          expect(item.containsKey('id'), isTrue);
        }
      });
    });
  });

  group('Annotations', () {
    test('bifrostModel annotation exists', () {
      expect(bifrostModel, isA<BifrostModel>());
    });

    test('primaryKey annotation exists', () {
      expect(primaryKey, isA<PrimaryKey>());
    });

    test('ignore annotation exists', () {
      expect(ignore, isA<Ignore>());
    });
  });
}
