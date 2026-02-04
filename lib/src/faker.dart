import 'dart:math';

/// Utility class for generating fake/mock data for testing.
///
/// Example:
/// ```dart
/// final user = {
///   'id': Faker.uuid(),
///   'name': Faker.name(),
///   'email': Faker.email(),
///   'age': Faker.integer(min: 18, max: 65),
/// };
/// ```
class Faker {
  static final _random = Random();

  // ============================================================================
  // Strings
  // ============================================================================

  /// Generates a random UUID v4.
  static String uuid() {
    return '${_hex(8)}-${_hex(4)}-4${_hex(3)}-${_hex(4)}-${_hex(12)}';
  }

  /// Generates a random name.
  static String name() {
    const firstNames = [
      'Odin', 'Thor', 'Loki', 'Freya', 'Baldur', 'Tyr', 'Heimdall', 'Frigg',
      'Sif', 'Bragi', 'Idun', 'Njord', 'Skadi', 'Vidar', 'Vali', 'Forseti',
    ];
    const lastNames = [
      'Allfather', 'Odinson', 'Laufeyson', 'Vanir', 'Aesir', 'Jotunn',
      'Thunderer', 'Silvertongue', 'Gatekeeper', 'Wise', 'Golden', 'Swift',
    ];
    return '${firstNames[_random.nextInt(firstNames.length)]} '
        '${lastNames[_random.nextInt(lastNames.length)]}';
  }

  /// Generates a random first name.
  static String firstName() {
    const names = [
      'Odin', 'Thor', 'Loki', 'Freya', 'Baldur', 'Tyr', 'Heimdall', 'Frigg',
      'Sif', 'Bragi', 'Idun', 'Njord', 'Skadi', 'Vidar', 'Vali', 'Forseti',
    ];
    return names[_random.nextInt(names.length)];
  }

  /// Generates a random last name.
  static String lastName() {
    const names = [
      'Allfather', 'Odinson', 'Laufeyson', 'Vanir', 'Aesir', 'Jotunn',
      'Thunderer', 'Silvertongue', 'Gatekeeper', 'Wise', 'Golden', 'Swift',
    ];
    return names[_random.nextInt(names.length)];
  }

  /// Generates a random email address.
  static String email() {
    final name = firstName().toLowerCase();
    final domains = ['asgard.com', 'valhalla.io', 'bifrost.dev', 'yggdrasil.net'];
    return '$name${_random.nextInt(999)}@${domains[_random.nextInt(domains.length)]}';
  }

  /// Generates a random username.
  static String username() {
    return '${firstName().toLowerCase()}${_random.nextInt(9999)}';
  }

  /// Generates a random string of specified length.
  static String string({int length = 10}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  /// Generates a random sentence.
  static String sentence({int words = 6}) {
    const wordList = [
      'the', 'quick', 'brown', 'fox', 'jumps', 'over', 'lazy', 'dog',
      'lorem', 'ipsum', 'dolor', 'sit', 'amet', 'consectetur', 'adipiscing',
      'rainbow', 'bridge', 'connects', 'realms', 'asgard', 'midgard',
    ];
    final result = List.generate(
      words,
      (_) => wordList[_random.nextInt(wordList.length)],
    ).join(' ');
    return '${result[0].toUpperCase()}${result.substring(1)}.';
  }

  /// Generates a random paragraph.
  static String paragraph({int sentences = 4}) {
    return List.generate(sentences, (_) => sentence(words: 5 + _random.nextInt(8)))
        .join(' ');
  }

  // ============================================================================
  // Numbers
  // ============================================================================

  /// Generates a random integer within a range.
  static int integer({int min = 0, int max = 100}) {
    return min + _random.nextInt(max - min + 1);
  }

  /// Generates a random double within a range.
  static double decimal({double min = 0.0, double max = 100.0, int decimals = 2}) {
    final value = min + _random.nextDouble() * (max - min);
    final factor = _pow10(decimals);
    return (value * factor).round() / factor;
  }

  /// Generates a random boolean.
  static bool boolean() => _random.nextBool();

  // ============================================================================
  // Dates
  // ============================================================================

  /// Generates a random date within a range.
  static DateTime dateTime({
    DateTime? min,
    DateTime? max,
  }) {
    final minDate = min ?? DateTime(2020);
    final maxDate = max ?? DateTime.now();
    final diff = maxDate.difference(minDate).inSeconds;
    return minDate.add(Duration(seconds: _random.nextInt(diff)));
  }

  /// Generates a random date in ISO8601 format.
  static String dateTimeIso({DateTime? min, DateTime? max}) {
    return dateTime(min: min, max: max).toIso8601String();
  }

  /// Generates a random past date.
  static DateTime pastDate({int years = 5}) {
    return dateTime(
      min: DateTime.now().subtract(Duration(days: years * 365)),
      max: DateTime.now(),
    );
  }

  /// Generates a random future date.
  static DateTime futureDate({int years = 5}) {
    return dateTime(
      min: DateTime.now(),
      max: DateTime.now().add(Duration(days: years * 365)),
    );
  }

  // ============================================================================
  // Collections
  // ============================================================================

  /// Returns a random element from a list.
  static T element<T>(List<T> list) {
    return list[_random.nextInt(list.length)];
  }

  /// Generates a list of items using a generator function.
  static List<T> list<T>(T Function() generator, {int count = 5}) {
    return List.generate(count, (_) => generator());
  }

  // ============================================================================
  // JSON
  // ============================================================================

  /// Generates a fake JSON object with common fields.
  static Map<String, dynamic> fakeJson() {
    return {
      'id': uuid(),
      'name': name(),
      'email': email(),
      'username': username(),
      'age': integer(min: 18, max: 80),
      'active': boolean(),
      'createdAt': dateTimeIso(),
    };
  }

  /// Generates a list of fake JSON objects.
  static List<Map<String, dynamic>> fakeJsonList({int count = 5}) {
    return list(fakeJson, count: count);
  }

  // ============================================================================
  // Private Helpers
  // ============================================================================

  static String _hex(int length) {
    const chars = '0123456789abcdef';
    return List.generate(length, (_) => chars[_random.nextInt(16)]).join();
  }

  static double _pow10(int exp) {
    var result = 1.0;
    for (var i = 0; i < exp; i++) {
      result *= 10;
    }
    return result;
  }
}
