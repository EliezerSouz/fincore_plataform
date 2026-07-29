import 'package:drift/drift.dart';
import '../../database/fincore_database.dart';
import '../../common/domain_primitives.dart';

class CriarEmpresaUseCase {
  final FincoreDatabase db;

  CriarEmpresaUseCase({required this.db});

  /// Executa o caso de uso para criar uma empresa, associar o usuário como ADMIN
  /// e registrar o evento de criação de forma atômica no banco local.
  Future<void> execute({
    required String tenantId,
    required String razaoSocial,
    required String nomeFantasia,
    required String documentoFiscal,
    required String emailEmpresa,
    required String telefoneEmpresa,
    required String usuarioId,
    required String usuarioNome,
    required String usuarioEmail,
  }) async {
    final now = DateTime.now();

    await db.transaction(() async {
      // 1. Criar Empresa
      await db.into(db.empresasTable).insertOnConflictUpdate(
        EmpresasTableCompanion.insert(
          id: tenantId,
          razaoSocial: razaoSocial,
          nomeFantasia: nomeFantasia,
          documentoFiscal: documentoFiscal,
          email: emailEmpresa,
          telefone: telefoneEmpresa,
          status: 'PENDENTE_ATIVACAO',
          plano: 'bronze',
          timezone: 'America/Sao_Paulo',
          locale: 'pt_BR',
          currency: 'BRL',
          country: 'BR',
          createdFrom: 'Web',
          syncVersion: const Value(1),
          createdAt: now,
          updatedAt: now,
          createdBy: usuarioId,
          updatedBy: usuarioId,
          syncStatus: SyncStatus.pending,
        ),
      );

      // 2. Garantir que Usuário existe globalmente
      await db.into(db.usuariosTable).insertOnConflictUpdate(
        UsuariosTableCompanion.insert(
          id: usuarioId,
          nome: usuarioNome,
          email: usuarioEmail,
          criadoEm: now,
          atualizadoEm: now,
        ),
      );

      // 3. Associar Usuário como Membro ADMIN
      await db.into(db.membrosEmpresaTable).insertOnConflictUpdate(
        MembrosEmpresaTableCompanion.insert(
          id: 'membro-$tenantId-$usuarioId',
          tenantId: tenantId,
          usuarioId: usuarioId,
          role: 'ADMIN',
          ativo: const Value(true),
          convidadoEm: now,
          aceitoEm: Value(now),
          createdAt: now,
          updatedAt: now,
          createdBy: usuarioId,
          updatedBy: usuarioId,
          syncStatus: SyncStatus.pending,
        ),
      );

      // 4. Logar Evento de Criação
      await db.into(db.eventosEmpresaTable).insert(
        EventosEmpresaTableCompanion.insert(
          id: 'evt-$tenantId-criacao-${now.millisecondsSinceEpoch}',
          tenantId: tenantId,
          tipo: 'CRIADA',
          payload: Value('{"razaoSocial": "$razaoSocial", "criadoPor": "$usuarioId"}'),
          geradoPor: usuarioId,
          ocorridoEm: now,
        ),
      );
    });
  }
}
