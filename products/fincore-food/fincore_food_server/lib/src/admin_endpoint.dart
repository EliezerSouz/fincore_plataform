import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'generated/protocol.dart';
import 'middleware/auth_middleware.dart';
import 'utils/timezone_helper.dart';

class AdminEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  @override
  Set<Scope> get requiredScopes => {Scope('superadmin')};

  /// Ativa uma empresa pendente de aprovação.
  Future<bool> ativarEmpresa(Session session, String tenantId) async {
    final ativadoPor = session.context['usuarioId'] as String;
    final now = TimezoneHelper.localNow;

    try {
      await session.db.transaction((transaction) async {
        // 1. Buscar a empresa
        final tenantUuid = UuidValue.fromString(tenantId);
        final empresa = await Empresa.db.findById(session, tenantUuid);
        if (empresa == null) {
          throw StateError('Empresa não encontrada.');
        }

        // 2. Atualizar status
        empresa.status = 'ativo';
        empresa.updatedAt = now;
        empresa.updatedBy = UuidValue.fromString(ativadoPor);
        await Empresa.db.updateRow(session, empresa);

        // 2.5. Criar log imutável de auditoria (EventoEmpresa)
        final evento = EventoEmpresa(
          id: UuidValue.fromString(Uuid().v4()),
          tenantId: tenantUuid,
          tipo: 'ATIVADA',
          payload: jsonEncode({
            'aprovadoPor': ativadoPor,
            'statusAnterior': 'PENDENTE_ATIVACAO',
            'statusNovo': 'ativo',
          }),
          geradoPor: ativadoPor,
          ocorridoEm: now,
        );
        await EventoEmpresa.db.insertRow(session, evento);

        // 3. Simular envio de email de ativação (enviado para o e-mail da empresa ou membros)
        session.log('SIMULAÇÃO EMAIL: Enviando email de ativação para a empresa $tenantId (Aprovado por: $ativadoPor)', level: LogLevel.info);
      });
      return true;
    } catch (e) {
      session.log('Erro ao ativar empresa: $e', level: LogLevel.error);
      return false;
    }
  }

  /// Retorna lista de empresas aguardando ativação
  Future<List<String>> empresasPendentes(Session session) async {
    try {
      final results = await Empresa.db.find(
        session,
        where: (t) => t.status.equals('PENDENTE_ATIVACAO'),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
      );
      return results.map((row) => '${row.id} - ${row.nomeFantasia}').toList();
    } catch (e) {
      session.log('Erro ao buscar pendentes: $e', level: LogLevel.error);
      return [];
    }
  }
}
