import 'package:faker/faker.dart' as f;

final _faker = f.Faker();

/// Utility class for generating fake data based on field names.
///
/// Uses intelligent field name matching to generate appropriate fake values.
///
/// Example:
/// ```dart
/// FakeUtils.fakeForKey('email');     // -> "john@example.com"
/// FakeUtils.fakeForKey('firstName'); // -> "John"
/// FakeUtils.fakeForKey('age');       // -> 42
/// ```
class FakeUtils {
  /// Generate fake value based on field name.
  ///
  /// Matches common patterns like 'email', 'name', 'id', 'age', etc.
  /// and returns appropriate fake data.
  static dynamic fakeForKey(String key) {
    final k = key.toLowerCase();

    // Email patterns
    if (k.contains('email')) return _faker.internet.email();

    // Name patterns
    if (k == 'name' || k.contains('firstname') || k.contains('first_name')) {
      return _faker.person.firstName();
    }
    if (k.contains('lastname') || k.contains('last_name')) {
      return _faker.person.lastName();
    }
    if (k.contains('name')) return _faker.person.name();

    // ID patterns
    if (k == 'id' || k.endsWith('id') || k.endsWith('_id')) {
      return _faker.randomGenerator.integer(10000);
    }

    // Contact/Address patterns (check BEFORE 'count' patterns to avoid 'country' matching 'count')
    if (k.contains('phone')) return _faker.phoneNumber.us();
    if (k.contains('address')) return _faker.address.streetAddress();
    if (k.contains('city')) return _faker.address.city();
    if (k.contains('state')) return _faker.address.state();
    if (k.contains('country')) return _faker.address.country();
    if (k.contains('zip') || k.contains('postal')) return _faker.address.zipCode();

    // Number patterns
    if (k.contains('age')) {
      return _faker.randomGenerator.integer(80, min: 18);
    }
    if (k.contains('count') || k.contains('quantity')) {
      return _faker.randomGenerator.integer(100);
    }
    if (k.contains('price') || k.contains('amount') || k.contains('cost')) {
      return _faker.randomGenerator.decimal(scale: 100);
    }

    // Date/time patterns
    if (k.contains('date') ||
        k.contains('time') ||
        k.contains('created') ||
        k.contains('updated')) {
      return _faker.date.dateTime().toIso8601String();
    }

    // URL/image patterns
    if (k.contains('url') || k.contains('link')) {
      return _faker.internet.httpUrl();
    }
    if (k.contains('image') || k.contains('avatar') || k.contains('photo')) {
      return _faker.image.image();
    }

    // Boolean patterns
    if (k.contains('active') ||
        k.contains('enabled') ||
        k.contains('suspended') ||
        k.startsWith('is') ||
        k.startsWith('has')) {
      return _faker.randomGenerator.boolean();
    }

    // Text patterns
    if (k.contains('description') || k.contains('bio') || k.contains('summary')) {
      return _faker.lorem.sentence();
    }
    if (k.contains('title')) return _faker.lorem.words(3).join(' ');

    // Default: return a random word
    return _faker.lorem.word();
  }

  /// Generate fake model from template instance + fromJson factory.
  ///
  /// Example:
  /// ```dart
  /// final user = FakeUtils.create(
  ///   () => User(),
  ///   User.fromJson,
  /// );
  /// ```
  static T create<T>(
    T Function() emptyFactory,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final json = (emptyFactory() as dynamic).toJson() as Map<String, dynamic>;
    return fromJson(json.map((k, _) => MapEntry(k, fakeForKey(k))));
  }

  /// Generate fake JSON for API responses (generic fallback).
  static Map<String, dynamic> fakeJson() {
    return {
      'id': _faker.randomGenerator.integer(10000),
      'name': _faker.person.name(),
      'email': _faker.internet.email(),
      'created_at': _faker.date.dateTime().toIso8601String(),
    };
  }

  /// Generate a list of fake JSON objects.
  static List<Map<String, dynamic>> fakeJsonList({int count = 5}) {
    return List.generate(count, (_) => fakeJson());
  }
}
