class DependencyInjection {
  static final DependencyInjection _instance = DependencyInjection._internal();
  factory DependencyInjection() => _instance;
  DependencyInjection._internal();

  final Map<Type, Object> _registry = {};

  /// Registra uma instância concreta para um tipo genérico T.
  void register<T extends Object>(T instance) {
    _registry[T] = instance;
  }

  /// Retorna a instância registrada correspondente ao tipo T.
  /// Lança StateError caso o tipo não esteja registrado.
  T get<T extends Object>() {
    final instance = _registry[T];
    if (instance == null) {
      throw StateError('Nenhum serviço registrado para o tipo $T.');
    }
    return instance as T;
  }

  /// Retorna a instância registrada correspondente ao tipo T, ou null se não estiver registrada.
  T? tryGet<T extends Object>() {
    return _registry[T] as T?;
  }

  /// Limpa todos os registros do contêiner.
  void clear() {
    _registry.clear();
  }
}
