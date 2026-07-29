/// FINCORE Shared — Camada de Foundation Business
///
/// Contém Value Objects, Formatters, Validators e Extensions
/// reutilizáveis em toda a plataforma FINCORE.
///
/// Importe apenas este arquivo:
/// ```dart
/// import 'package:fincore_shared/fincore_shared.dart';
/// ```
library fincore_shared;

// ─── Value Objects ────────────────────────────────────────────────────────────
export 'src/value_objects/phone.dart';
export 'src/value_objects/cpf_cnpj.dart';
export 'src/value_objects/money.dart';
export 'src/value_objects/pix_key.dart';
export 'src/value_objects/address.dart';
export 'src/value_objects/misc_value_objects.dart'
    show FincorePercentage, FincorePostalCode, FinCoreDateRange;

// ─── Formatters ───────────────────────────────────────────────────────────────
export 'src/formatters/formatters.dart';

// ─── Validators ───────────────────────────────────────────────────────────────
export 'src/validators/validators.dart';

// Patterns (Unit of Work)
export 'src/patterns/edit_session.dart';

// ─── Extensions ───────────────────────────────────────────────────────────────
export 'src/extensions/extensions.dart';
