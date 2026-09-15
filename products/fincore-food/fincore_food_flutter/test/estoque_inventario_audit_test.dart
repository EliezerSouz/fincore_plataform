import 'package:flutter_test/flutter_test.dart';

/// Modelo simples representativo para teste do motor de cálculo de auditoria de estoque.
class MovimentacaoTestItem {
  final String tipo; // 'inventario', 'reserva', 'expedicao', 'producao', 'perda'
  final int quantidade;
  final int quantidadeAntes;
  final int quantidadeDepois;
  final int? quantidadeReservadaAntes;
  final int? quantidadeReservadaDepois;

  const MovimentacaoTestItem({
    required this.tipo,
    required this.quantidade,
    required this.quantidadeAntes,
    required this.quantidadeDepois,
    this.quantidadeReservadaAntes,
    this.quantidadeReservadaDepois,
  });
}

class InventarioAuditResult {
  final int saldoAnterior;
  final int contagemFisica;
  final int ajusteRealizado;
  final int fisicoFinal;
  final int reservadoFinal;
  final int disponivelFinal;

  const InventarioAuditResult({
    required this.saldoAnterior,
    required this.contagemFisica,
    required this.ajusteRealizado,
    required this.fisicoFinal,
    required this.reservadoFinal,
    required this.disponivelFinal,
  });
}

/// Motor de cálculo auditável testável
InventarioAuditResult calcularAuditLedger(List<MovimentacaoTestItem> movimentacoes) {
  int runningFisico = 0;
  int runningReserva = 0;
  int saldoAnteriorInventario = 0;
  int contagemFisicaInventario = 0;
  int ajusteInventario = 0;

  for (final m in movimentacoes) {
    final tipo = m.tipo.toLowerCase();
    final isInventario = tipo.contains('inventario');
    final isReserva = tipo.contains('reserva');
    final isEntrada = !isReserva && !isInventario && (tipo.contains('entrada') || tipo.contains('producao'));
    final isSaida = !isReserva && !isInventario && (tipo.contains('saida') || tipo.contains('expedicao') || tipo.contains('perda'));

    if (isInventario) {
      saldoAnteriorInventario = runningFisico;
      contagemFisicaInventario = m.quantidadeDepois;
      ajusteInventario = contagemFisicaInventario - saldoAnteriorInventario;
      runningFisico = contagemFisicaInventario;
    } else if (isEntrada) {
      runningFisico += m.quantidade;
    } else if (isSaida) {
      runningFisico -= m.quantidade;
      if (tipo.contains('expedicao') && runningReserva > 0) {
        runningReserva = (runningReserva - m.quantidade).clamp(0, 999999);
      }
    } else if (isReserva) {
      runningReserva += m.quantidade;
    }
  }

  final disponivelFinal = (runningFisico - runningReserva).clamp(0, 999999);

  return InventarioAuditResult(
    saldoAnterior: saldoAnteriorInventario,
    contagemFisica: contagemFisicaInventario,
    ajusteRealizado: ajusteInventario,
    fisicoFinal: runningFisico,
    reservadoFinal: runningReserva,
    disponivelFinal: disponivelFinal,
  );
}

void main() {
  group('FINCORE FOOD — Testes de Auditoria de Inventário e Reconstrução de Saldo', () {
    test('CENÁRIO 1: Sistema = 0, Contagem = 500 → Ajuste +500, Físico 500', () {
      final movs = [
        const MovimentacaoTestItem(
          tipo: 'inventario',
          quantidade: 500,
          quantidadeAntes: 0,
          quantidadeDepois: 500,
        ),
      ];

      final res = calcularAuditLedger(movs);

      expect(res.saldoAnterior, equals(0));
      expect(res.contagemFisica, equals(500));
      expect(res.ajusteRealizado, equals(500));
      expect(res.fisicoFinal, equals(500));
      expect(res.disponivelFinal, equals(500));
    });

    test('CENÁRIO 2: Sistema = 500, Contagem = 450 → Ajuste -50, Físico 450', () {
      final movs = [
        const MovimentacaoTestItem(
          tipo: 'inventario',
          quantidade: 500,
          quantidadeAntes: 0,
          quantidadeDepois: 500,
        ),
        const MovimentacaoTestItem(
          tipo: 'inventario',
          quantidade: 50,
          quantidadeAntes: 500,
          quantidadeDepois: 450,
        ),
      ];

      final res = calcularAuditLedger(movs);

      expect(res.saldoAnterior, equals(500));
      expect(res.contagemFisica, equals(450));
      expect(res.ajusteRealizado, equals(-50));
      expect(res.fisicoFinal, equals(450));
      expect(res.disponivelFinal, equals(450));
    });

    test('CENÁRIO 3: Sistema = 500, Contagem = 500 → Ajuste 0, Físico 500', () {
      final movs = [
        const MovimentacaoTestItem(
          tipo: 'inventario',
          quantidade: 500,
          quantidadeAntes: 0,
          quantidadeDepois: 500,
        ),
        const MovimentacaoTestItem(
          tipo: 'inventario',
          quantidade: 0,
          quantidadeAntes: 500,
          quantidadeDepois: 500,
        ),
      ];

      final res = calcularAuditLedger(movs);

      expect(res.saldoAnterior, equals(500));
      expect(res.contagemFisica, equals(500));
      expect(res.ajusteRealizado, equals(0));
      expect(res.fisicoFinal, equals(500));
      expect(res.disponivelFinal, equals(500));
    });

    test('CENÁRIO 4: Inventário = 500, Reserva = 50 → Físico 500, Reservado 50, Disponível 450', () {
      final movs = [
        const MovimentacaoTestItem(
          tipo: 'inventario',
          quantidade: 500,
          quantidadeAntes: 0,
          quantidadeDepois: 500,
        ),
        const MovimentacaoTestItem(
          tipo: 'reserva',
          quantidade: 50,
          quantidadeAntes: 500,
          quantidadeDepois: 500,
        ),
      ];

      final res = calcularAuditLedger(movs);

      expect(res.fisicoFinal, equals(500));
      expect(res.reservadoFinal, equals(50));
      expect(res.disponivelFinal, equals(450));
    });

    test('CENÁRIO 5: Inventário = 500, Reserva = 50, Expedição = 25 → Físico 475, Reservado 25, Disponível 450', () {
      final movs = [
        const MovimentacaoTestItem(
          tipo: 'inventario',
          quantidade: 500,
          quantidadeAntes: 0,
          quantidadeDepois: 500,
        ),
        const MovimentacaoTestItem(
          tipo: 'reserva',
          quantidade: 50,
          quantidadeAntes: 500,
          quantidadeDepois: 500,
        ),
        const MovimentacaoTestItem(
          tipo: 'expedicao',
          quantidade: 25,
          quantidadeAntes: 500,
          quantidadeDepois: 475,
        ),
      ];

      final res = calcularAuditLedger(movs);

      expect(res.fisicoFinal, equals(475));
      expect(res.reservadoFinal, equals(25));
      expect(res.disponivelFinal, equals(450));
    });
  });
}
