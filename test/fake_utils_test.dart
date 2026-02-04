import 'package:bifrosted/bifrosted.dart';
import 'package:test/test.dart';

void main() {
  group('FakeUtils', () {
    group('fakeForKey', () {
      test('generates email for email fields', () {
        final email = FakeUtils.fakeForKey('email');
        expect(email, isA<String>());
        expect((email as String).contains('@'), isTrue);
      });

      test('generates email for userEmail fields', () {
        final email = FakeUtils.fakeForKey('userEmail');
        expect((email as String).contains('@'), isTrue);
      });

      test('generates name for name field', () {
        final name = FakeUtils.fakeForKey('name');
        expect(name, isA<String>());
        expect((name as String).isNotEmpty, isTrue);
      });

      test('generates first name for firstName field', () {
        final name = FakeUtils.fakeForKey('firstName');
        expect(name, isA<String>());
      });

      test('generates last name for lastName field', () {
        final name = FakeUtils.fakeForKey('lastName');
        expect(name, isA<String>());
      });

      test('generates integer for id field', () {
        final id = FakeUtils.fakeForKey('id');
        expect(id, isA<int>());
      });

      test('generates integer for userId field', () {
        final id = FakeUtils.fakeForKey('userId');
        expect(id, isA<int>());
      });

      test('generates integer for user_id field', () {
        final id = FakeUtils.fakeForKey('user_id');
        expect(id, isA<int>());
      });

      test('generates age in valid range', () {
        for (var i = 0; i < 100; i++) {
          final age = FakeUtils.fakeForKey('age') as int;
          expect(age, greaterThanOrEqualTo(18));
          expect(age, lessThanOrEqualTo(80));
        }
      });

      test('generates decimal for price fields', () {
        final price = FakeUtils.fakeForKey('price');
        expect(price, isA<num>());
      });

      test('generates ISO date for date fields', () {
        final date = FakeUtils.fakeForKey('createdAt');
        expect(date, isA<String>());
        expect(DateTime.tryParse(date as String), isNotNull);
      });

      test('generates URL for url fields', () {
        final url = FakeUtils.fakeForKey('profileUrl');
        expect(url, isA<String>());
        expect((url as String).startsWith('http'), isTrue);
      });

      test('generates boolean for boolean-like fields', () {
        expect(FakeUtils.fakeForKey('active'), isA<bool>());
        expect(FakeUtils.fakeForKey('enabled'), isA<bool>());
        expect(FakeUtils.fakeForKey('isAdmin'), isA<bool>());
        expect(FakeUtils.fakeForKey('hasAccess'), isA<bool>());
        expect(FakeUtils.fakeForKey('suspended'), isA<bool>());
      });

      test('generates sentence for description fields', () {
        final desc = FakeUtils.fakeForKey('description');
        expect(desc, isA<String>());
        expect((desc as String).isNotEmpty, isTrue);
      });

      test('generates phone number for phone fields', () {
        final phone = FakeUtils.fakeForKey('phone');
        expect(phone, isA<String>());
      });

      test('generates address for address fields', () {
        expect(FakeUtils.fakeForKey('address'), isA<String>());
        expect(FakeUtils.fakeForKey('city'), isA<String>());
        expect(FakeUtils.fakeForKey('country'), isA<String>());
        expect(FakeUtils.fakeForKey('zipCode'), isA<String>());
      });

      test('defaults to random word for unknown fields', () {
        final value = FakeUtils.fakeForKey('unknownField123');
        expect(value, isA<String>());
      });
    });

    group('fakeJson', () {
      test('generates json with expected fields', () {
        final json = FakeUtils.fakeJson();
        expect(json.containsKey('id'), isTrue);
        expect(json.containsKey('name'), isTrue);
        expect(json.containsKey('email'), isTrue);
        expect(json.containsKey('created_at'), isTrue);
      });
    });

    group('fakeJsonList', () {
      test('generates correct count', () {
        final list = FakeUtils.fakeJsonList(count: 10);
        expect(list.length, 10);
      });

      test('each item has expected fields', () {
        for (final item in FakeUtils.fakeJsonList()) {
          expect(item.containsKey('id'), isTrue);
        }
      });
    });
  });

  group('GenerateFake annotation', () {
    test('annotation exists', () {
      expect(generateFake, isA<GenerateFake>());
    });

    test('GenerateFake class exists', () {
      const annotation = GenerateFake();
      expect(annotation, isA<GenerateFake>());
    });
  });
}
