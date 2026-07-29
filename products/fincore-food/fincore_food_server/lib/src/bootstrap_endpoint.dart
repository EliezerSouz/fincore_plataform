import 'package:serverpod/serverpod.dart';
import 'generated/protocol.dart';
import 'middleware/auth_middleware.dart';

class BootstrapEndpoint extends Endpoint {
  /// Retorna todos os dados necessários para inicializar o aplicativo no dispositivo do cliente.
  Future<BootstrapPayload> bootstrapTenant(Session session) async {
    final authInfo = await session.authenticated;
    if (authInfo == null) {
      throw Exception('Usuário não autenticado');
    }

    final usuarioId = session.context['usuarioId'] as String;
    final tenantId = session.context['tenantId'] as String?;

    if (tenantId == null || tenantId.isEmpty) {
      throw Exception('Usuário não está vinculado a nenhum Tenant');
    }

    // Buscar Usuário
    final usuario = await Usuario.db.findById(session, UuidValue.fromString(usuarioId));
    if (usuario == null) {
      throw Exception('Usuário não encontrado');
    }

    // Buscar Empresa
    final empresa = await Empresa.db.findById(session, UuidValue.fromString(tenantId));
    if (empresa == null) {
      throw Exception('Empresa não encontrada');
    }

    // Buscar Membros da Empresa
    final membros = await MembroEmpresa.db.find(
      session,
      where: (t) => t.tenantId.equals(UuidValue.fromString(tenantId)),
    );

    // Buscar Configuração da Empresa
    var configuracao = await EmpresaConfiguracao.db.findFirstRow(
      session,
      where: (t) => t.tenantId.equals(tenantId),
    );

    if (configuracao == null) {
      // Se a configuração não existir (ex: erro no onboarding), cria uma padrão
      configuracao = EmpresaConfiguracao(
        tenantId: tenantId,
        timezone: 'America/Sao_Paulo',
        locale: 'pt_BR',
        currency: 'BRL',
        taxaServico: 0.10,
        usarWhatsApp: true,
        tema: 'light',
        syncVersion: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: UuidValue.fromString(usuarioId),
        updatedBy: UuidValue.fromString(usuarioId),
        
        // Impressão e Hardware Defaults
        autoPrintCaixa: true,
        autoPrintCozinha: true,
        autoPrintBalcao: false,
        autoPrintExpedicao: false,
        viasCliente: 1,
        viasCozinha: 1,
        viasBalcao: 0,
        viasExpedicao: 0,
        larguraPapel: 80,
        cortarPapel: true,
        abrirGaveta: false,
        
        // QR Code e Layout Defaults
        imprimirQRCode: true,
        imprimirCopiaCola: true,
        imprimirLogo: false,
        imprimirRodape: true,
        mensagemRodape: 'Obrigado pela preferência!',
        
        // PIX Defaults
        pixTipo: 'CPF',
        pixCidade: 'Sorocaba',
      );
      configuracao = await EmpresaConfiguracao.db.insertRow(session, configuracao);
    }

    return BootstrapPayload(
      schemaVersion: 1,
      generatedAt: DateTime.now(),
      empresa: empresa,
      configuracao: configuracao,
      usuario: usuario,
      membros: membros,
    );
  }
}
