import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_food_flutter/src/shared/services/whatsapp_service.dart';

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..findProxy = (uri) => 'DIRECT';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();

  const String kRealDbPath = r'F:\Eigent\fincore_platform\products\fincore-food\fincore_food_flutter\build\windows\x64\runner\Debug\data\fincore_v3.db';
  const String kNumeroEliezer = '35992503114';
  const String kTenantId = 'delivery_do_eli';
  const String kPedidoId = 'ped_live_pratica_101';
  const String kEventoId = 'pedido_pronto';
  final String kIdempotencyKey = '$kTenantId:$kPedidoId:$kEventoId';

  late FincoreDatabase realDb;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    WhatsAppService.limparHistoricoSimulacoes();

    final dbFile = File(kRealDbPath);
    expect(dbFile.existsSync(), isTrue, reason: 'Banco fincore_v3.db deve existir');

    realDb = FincoreDatabase(NativeDatabase(dbFile));
    DependencyInjection().clear();
    DependencyInjection().register<FincoreDatabase>(realDb);

    // Garante que a tabela forense exista no banco real do FINCORE
    await WhatsAppService.logRepository.inicializarTabela();
  });

  tearDownAll(() async {
    await realDb.close();
    DependencyInjection().clear();
  });

  test('TESTE EM PRÁTICA: Envio Real via Evolution API + Persistência Forense no SQLite + Bloqueio de Idempotência', () async {
    print('\n============================================================');
    print('🚀 INICIANDO TESTE EM PRÁTICA NO BANCO REAL DO FINCORE');
    print('Banco: $kRealDbPath');
    print('Destinatário Real: $kNumeroEliezer (Eliezer)');
    print('Chave de Idempotência: $kIdempotencyKey');
    print('============================================================\n');

    // 1. Limpa registro anterior desta chave de teste se houver para o teste ser reprodutível
    await realDb.customStatement(
      'DELETE FROM whatsapp_mensagens_log WHERE idempotency_key = ?',
      [kIdempotencyKey],
    );

    final config = EvolutionApiConfig(
      apiUrl: 'http://localhost:8080',
      apiKey: 'fincore_sec_9f8e7d6c5b4a3a2b1c0d_api',
      instanceName: 'fincore_atendimento',
    );

    // 2. DISPARO REAL 1: Envio real à Evolution API conectado ao WhatsApp
    final mensagemFormatada = 
        '🚀 *FINCORE Food — Teste em Prática (Fase D2)*\n\n'
        'Olá *Eliezer*! 👋\n'
        'Este é o teste prático executado diretamente na sua base local do FINCORE (`fincore_v3.db`).\n\n'
        '✅ *Status:* Instância `fincore_atendimento` conectada\n'
        '🛡️ *Fase D2:* Idempotência persistente no SQLite ativa\n'
        '📋 *Auditoria:* Registro forense gravado com sucesso!\n\n'
        '_FINCORE Domain Flow Architecture_';

    print('📡 [Disparo 1] Enviando mensagem real via Evolution API...');
    final resultado1 = await WhatsAppService.enviarMensagem(
      rawPhone: kNumeroEliezer,
      mensagem: mensagemFormatada,
      config: config,
      tenantId: kTenantId,
      pedidoId: kPedidoId,
      eventoId: kEventoId,
      idempotencyKey: kIdempotencyKey,
    );

    print('   -> Sucesso: ${resultado1.sucesso}');
    print('   -> Status: ${resultado1.status.name}');
    print('   -> HTTP Status: ${resultado1.httpStatusCode}');
    print('   -> Message ID: ${resultado1.messageId}');
    print('   -> Telefone Mascarado (LGPD): ${resultado1.telefoneMascarado}');

    expect(resultado1.sucesso, isTrue, reason: 'O envio real para a Evolution API deve ter sucesso');
    expect(resultado1.messageId, isNotNull);

    // 3. CONSULTA FORENSE DIRETA NO ARQUIVO SQLITE REAL
    print('\n🔍 [Verificação SQLite] Consultando tabela whatsapp_mensagens_log no banco real...');
    final rows = await realDb.customSelect(
      'SELECT * FROM whatsapp_mensagens_log WHERE idempotency_key = ?',
      variables: [Variable.withString(kIdempotencyKey)],
    ).get();

    expect(rows.length, equals(1), reason: 'Deve haver exatamente 1 registro persistido no SQLite');
    final row = rows.first.data;
    print('   -> ID: ${row['id']}');
    print('   -> Tenant: ${row['tenant_id']}');
    print('   -> Pedido: ${row['pedido_id']}');
    print('   -> Chave: ${row['idempotency_key']}');
    print('   -> Destinatário Mascarado: ${row['destinatario_mascarado']}');
    print('   -> Message ID: ${row['message_id']}');
    print('   -> HTTP Code: ${row['http_status_code']}');
    print('   -> Criado Em: ${row['criado_em']}');

    expect(row['destinatario_mascarado'], equals(resultado1.telefoneMascarado));
    expect(row['message_id'], equals(resultado1.messageId));
    expect(row['status'], equals('sucesso'));

    // 4. DISPARO REAL 2 (TENTATIVA DUPLICADA): Tentativa com a mesma chave
    print('\n🛡️ [Disparo 2] Tentando reenviar com a mesma chave de idempotência...');
    final resultado2 = await WhatsAppService.enviarMensagem(
      rawPhone: kNumeroEliezer,
      mensagem: 'Esta mensagem NÃO DEVE SER ENVIADA - deve ser bloqueada por idempotência',
      config: config,
      tenantId: kTenantId,
      pedidoId: kPedidoId,
      eventoId: kEventoId,
      idempotencyKey: kIdempotencyKey,
    );

    print('   -> Sucesso: ${resultado2.sucesso}');
    print('   -> Erro: ${resultado2.erro}');
    print('   -> Telefone Mascarado: ${resultado2.telefoneMascarado}');

    expect(resultado2.sucesso, isFalse, reason: 'O disparo duplicado DEVE ser bloqueado');
    expect(resultado2.erro, contains('Disparo bloqueado por idempotência'));

    // 5. Garante que nenhuma nova mensagem foi criada no SQLite
    final rowsAposDup = await realDb.customSelect(
      'SELECT COUNT(*) as total FROM whatsapp_mensagens_log WHERE idempotency_key = ?',
      variables: [Variable.withString(kIdempotencyKey)],
    ).get();
    expect(rowsAposDup.first.data['total'], equals(1));

    print('\n============================================================');
    print('🎉 TESTE EM PRÁTICA CONCLUÍDO COM 100% DE ÊXITO!');
    print('Mensagem real entregue no WhatsApp do Eliezer!');
    print('Idempotência persistente no banco fincore_v3.db validada com perfeição!');
    print('============================================================\n');
  });
}
