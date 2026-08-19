import 'package:drift/drift.dart';
import '../../database/fincore_database.dart';
import '../../common/domain_primitives.dart';
import '../../src/logging/log_service.dart';

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

    LogService.instance.info(
      LogModule.startup,
      'Criando nova empresa [$nomeFantasia] id=$tenantId no banco local...',
      tenantId: tenantId,
      userId: usuarioId,
    );

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
          tipoPessoa: const Value('JURIDICA'),
        ),
      );

      // 2. Inicializar Configuração Padrão da Empresa (Atômica)
      await db.into(db.empresaConfiguracaoTable).insertOnConflictUpdate(
        EmpresaConfiguracaoTableCompanion.insert(
          id: 'conf-$tenantId',
          tenantId: tenantId,
          taxaServico: const Value(0.10),
          usarWhatsApp: const Value(true),
          tema: const Value('escuro'),
          syncVersion: const Value(1),
          createdAt: now,
          updatedAt: now,
          createdBy: usuarioId,
          updatedBy: usuarioId,
          syncStatus: SyncStatus.pending,
        ),
      );

      // 3. Garantir que Usuário existe no tenant
      await db.into(db.usuariosTable).insertOnConflictUpdate(
        UsuariosTableCompanion.insert(
          id: usuarioId,
          tenantId: Value(tenantId),
          username: usuarioEmail.contains('@') ? usuarioEmail.split('@').first : usuarioEmail,
          nome: usuarioNome,
          email: Value(usuarioEmail),
          ativo: const Value(true),
          criadoEm: now,
          atualizadoEm: now,
        ),
      );

      // 4. Associar Usuário como Membro ADMIN
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

      // 5. Logar Evento de Criação via AuditLog
      await db.into(db.auditLogsTable).insertOnConflictUpdate(
        AuditLogsTableCompanion.insert(
          id: 'evt-$tenantId-criacao-${now.millisecondsSinceEpoch}',
          tenantId: tenantId,
          targetEntity: 'empresa',
          entityId: tenantId,
          userId: usuarioId,
          action: 'CRIADA',
          timestamp: now,
          diff: Value('{"razaoSocial": "$razaoSocial", "criadoPor": "$usuarioId"}'),
        ),
      );
    });
  }
}
