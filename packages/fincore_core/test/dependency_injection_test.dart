import 'package:test/test.dart';
import 'package:fincore_core/di/dependency_injection.dart';

abstract class TestService {}
class TestServiceImpl implements TestService {}

void main() {
  group('DependencyInjection Tests', () {
    final di = DependencyInjection();

    setUp(() {
      di.clear();
    });

    test('should successfully register and retrieve service instance', () {
      final serviceImpl = TestServiceImpl();
      di.register<TestService>(serviceImpl);

      final retrieved = di.get<TestService>();
      expect(retrieved, isNotNull);
      expect(retrieved, same(serviceImpl));
    });

    test('should throw StateError when retrieving unregistered service', () {
      expect(() => di.get<TestService>(), throwsA(isA<StateError>()));
    });

    test('should successfully clear registered dependencies', () {
      final serviceImpl = TestServiceImpl();
      di.register<TestService>(serviceImpl);

      expect(di.get<TestService>(), same(serviceImpl));

      di.clear();

      expect(() => di.get<TestService>(), throwsA(isA<StateError>()));
    });
  });
}
