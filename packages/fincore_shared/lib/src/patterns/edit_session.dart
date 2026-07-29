import 'package:flutter/foundation.dart';

/// Uma sessão de edição (Unit of Work) que gerencia o estado de um rascunho.
/// Mantém uma cópia do [original] intacta enquanto permite alterações no [workingCopy].
/// Fornece controle de [isDirty] baseado em uma função customizada de igualdade [isEqual].
class EditSession<T> extends ChangeNotifier {
  T _original;
  T _workingCopy;

  /// Função usada para comparar o modelo original com o working copy
  final bool Function(T original, T copy) isEqual;

  EditSession({
    required T initial,
    required this.isEqual,
  })  : _original = initial,
        _workingCopy = initial;

  /// Retorna o valor original intacto (pré-modificações)
  T get original => _original;

  /// Retorna a cópia de rascunho atual (com alterações não salvas)
  T get workingCopy => _workingCopy;

  /// Indica se a cópia de trabalho atual diverge do original
  bool get isDirty => !isEqual(_original, _workingCopy);

  /// Atualiza o rascunho com novos dados.
  /// Se os dados novos forem diferentes do rascunho atual, notifica os ouvintes (UI).
  void update(T newCopy) {
    if (!isEqual(_workingCopy, newCopy)) {
      _workingCopy = newCopy;
      notifyListeners();
    }
  }

  /// Descarta as edições atuais, retornando o rascunho ao estado [original].
  void discard() {
    if (isDirty) {
      _workingCopy = _original;
      notifyListeners();
    }
  }

  /// Consolida as edições atuais, tornando o [workingCopy] atual o novo [original].
  /// Isso "limpa" a sujeira (isDirty passa a ser false).
  void commit() {
    if (isDirty) {
      _original = _workingCopy;
      notifyListeners();
    }
  }

  /// Substitui completamente o [original] e o [workingCopy] por um novo valor.
  /// Útil ao carregar dados do banco de dados (refresh remoto).
  void reset(T newInitial) {
    _original = newInitial;
    _workingCopy = newInitial;
    notifyListeners();
  }
}
