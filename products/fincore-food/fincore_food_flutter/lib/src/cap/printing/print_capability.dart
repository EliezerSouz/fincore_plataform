/// CAP.PRINTING — Capability de Impressão Autônoma do FINCORE.
///
/// Arquitetura:
/// ```
/// PrintUseCase (ponto de entrada)
///     ↓
/// PrintManager (orquestra vias)
///     ↓
/// PrintTemplateEngine (gera conteúdo por via)
///     ↓
/// PrinterDriver (envia para hardware)
///     ↓
/// PrintJobRepository (registra histórico)
/// ```
///
/// Regra de ouro:
/// - A UI **nunca** chama PrintManager ou PrinterDriver diretamente.
/// - A UI **sempre** usa PrintUseCase como único ponto de acesso.
/// - A impressão **nunca** abre diálogo de seleção de impressora.
library;

export 'models/print_config.dart';
export 'models/print_data.dart';
export 'templates/print_template_engine.dart';
export 'drivers/printer_driver.dart';
export 'services/print_manager.dart';
export 'usecases/print_use_case.dart';
