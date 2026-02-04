/// Annotation to trigger fake factory generation via build_runner.
///
/// Add this annotation to any freezed model to automatically generate
/// a `.fake()` extension method.
///
/// Example:
/// ```dart
/// @freezed
/// @generateFake
/// class User with _$User {
///   factory User({int? id, String? name}) = _User;
///   factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
/// }
///
/// // After running build_runner, you can use:
/// final user = UserFake.fake();
/// ```
class GenerateFake {
  const GenerateFake();
}

/// Convenient constant for the annotation
const generateFake = GenerateFake();
