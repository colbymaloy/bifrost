import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'generate_fake.dart';

/// Builder entry point for build_runner.
///
/// Add this to your `build.yaml`:
/// ```yaml
/// builders:
///   fake_generator:
///     import: 'package:bifrosted/builder.dart'
///     builder_factories: ['fakeGeneratorBuilder']
///     auto_apply: dependents
///     build_extensions: {".dart": [".fake.g.dart"]}
///     build_to: source
///     applies_builders: ["source_gen|combining_builder"]
/// ```
Builder fakeGeneratorBuilder(BuilderOptions options) => SharedPartBuilder(
      [FakeGenerator()],
      'fake',
    );

/// Generator that creates .fake() extension methods for annotated models.
///
/// Works with freezed models to generate test data factories.
class FakeGenerator extends GeneratorForAnnotation<GenerateFake> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@GenerateFake can only be applied to classes.',
        element: element,
      );
    }

    final className = element.name;

    // Find the main factory constructor (freezed pattern)
    ConstructorElement? constructor;

    // First try to find a factory constructor that's not fromJson or private
    for (final c in element.constructors) {
      final name = c.name;
      if (c.isFactory &&
          (name == null || !name.contains('fromJson')) &&
          (name == null || !name.startsWith('_'))) {
        constructor = c;
        break;
      }
    }

    // If not found, try any factory constructor
    if (constructor == null) {
      for (final c in element.constructors) {
        if (c.isFactory) {
          constructor = c;
          break;
        }
      }
    }

    // If still not found, use the first constructor
    if (constructor == null && element.constructors.isNotEmpty) {
      constructor = element.constructors.first;
    }

    if (constructor == null) {
      throw InvalidGenerationSourceError(
        'No constructor found for $className',
        element: element,
      );
    }

    // Generate fake values for each parameter using FakeUtils.fakeForKey
    final params = constructor.formalParameters.map((p) {
      return "${p.name}: FakeUtils.fakeForKey('${p.name}')";
    }).join(',\n      ');

    return '''
extension ${className}Fake on $className {
  static $className fake() => $className(
      $params,
    );
}
''';
  }
}
