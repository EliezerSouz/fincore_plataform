import 'package:drift/drift.dart';
import '../../database/fincore_database.dart';
import '../../common/domain_primitives.dart';

class AtivarEmpresaUseCase {
  final FincoreDatabase db;

  AtivarEmpresaUseCase({required this.db});

  /// Ativa uma empresa pendente (transição PENDENTE_ATIVACAO -> ACTIVE/TRIAL)
  /// e gera o respectivo EventoEmpresa 'ATIVADA'.
  Future<void> execute({
    required String tenantId,
    required String ativadoPor, // ID do SuperAdmin ou 'SYSTEM'
  }) async {
    final now = DateTime.now();

    await db.transaction(() async {
      // 1. Buscar a empresa
      final query = db.select(db.empresasTable)..where((t) => t.id.equals(tenantId));
      final empresa = await query.getSingleOrNull();
      if (empresa == null) {
        throw StateError('Empresa com ID $tenantId não encontrada.');
      }

      // 2. Atualizar o status para ativo
      await (db.update(db.empresasTable)..where((t) => t.id.equals(tenantId))).write(
        EmpresasTableCompanion(
          status: const Value('ativo'),
          updatedAt: Value(now),
          updatedBy: Value(ativadoPor),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );

      // 3. Logar Evento de Ativação
      await db.into(db.eventosEmpresaTable).insert(
        EventosEmpresaTableCompanion.insert(
          id: 'evt-$tenantId-ativacao-${now.millisecondsSinceEpoch}',
          tenantId: tenantId,
          tipo: 'ATIVADA',
          payload: Value('{"ativadoPor": "$ativadoPor"}'),
          geradoPor: ativadoPor,
          ocorridoEm: now,
        ),
      );
    });
  }
}
