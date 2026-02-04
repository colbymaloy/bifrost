/// Annotations for bifrosted data models.
///
/// Use these with `json_serializable` or `freezed` for code generation.

/// Marks a class as a bifrosted data model.
///
/// This is a marker annotation for documentation purposes.
/// Use with `@JsonSerializable()` for actual code generation.
///
/// Example:
/// ```dart
/// @bifrostModel
/// @JsonSerializable()
/// class User {
///   final String id;
///   final String name;
///   final String email;
///
///   User({required this.id, required this.name, required this.email});
///
///   factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
///   Map<String, dynamic> toJson() => _$UserToJson(this);
/// }
/// ```
const bifrostModel = BifrostModel();

/// Annotation class for [bifrostModel].
class BifrostModel {
  const BifrostModel();
}

/// Marks a field as the primary identifier.
///
/// Example:
/// ```dart
/// @bifrostModel
/// class User {
///   @primaryKey
///   final String id;
///   final String name;
/// }
/// ```
const primaryKey = PrimaryKey();

/// Annotation class for [primaryKey].
class PrimaryKey {
  const PrimaryKey();
}

/// Marks a field to be ignored during serialization.
///
/// Example:
/// ```dart
/// @bifrostModel
/// class User {
///   final String id;
///   @ignore
///   final String cachedValue;
/// }
/// ```
const ignore = Ignore();

/// Annotation class for [ignore].
class Ignore {
  const Ignore();
}
