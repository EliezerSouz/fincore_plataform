import 'package:flutter/material.dart';

/// Enumeração de estados de interação fundamentais na interface de usuário.
enum InteractionState {
  normal,
  hover,
  focused,
  active,
  disabled,
  error,
  success,
  warning,
}

/// Helper para resolver propriedades visuais baseadas no estado de interação.
class FincoreInteractionResolver<T> {
  final T normal;
  final T? hover;
  final T? focused;
  final T? active;
  final T? disabled;
  final T? error;
  final T? success;
  final T? warning;

  const FincoreInteractionResolver({
    required this.normal,
    this.hover,
    this.focused,
    this.active,
    this.disabled,
    this.error,
    this.success,
    this.warning,
  });

  /// Resolve o valor correspondente ao estado ativo, usando `normal` como fallback.
  T resolve(InteractionState state) {
    switch (state) {
      case InteractionState.hover:
        return hover ?? normal;
      case InteractionState.focused:
        return focused ?? normal;
      case InteractionState.active:
        return active ?? normal;
      case InteractionState.disabled:
        return disabled ?? normal;
      case InteractionState.error:
        return error ?? normal;
      case InteractionState.success:
        return success ?? normal;
      case InteractionState.warning:
        return warning ?? normal;
      case InteractionState.normal:
      default:
        return normal;
    }
  }
}
