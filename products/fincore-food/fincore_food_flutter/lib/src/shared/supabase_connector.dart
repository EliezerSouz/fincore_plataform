import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fincore_core/sync/serverpod_connector.dart';
import 'package:fincore_core/database/fincore_database.dart';

/// Conector que sincroniza as entradas da OutboxSync com o Supabase PostgreSQL.
///
/// Implementa [CoreServerConnector] (definido em fincore_core) usando o SDK
/// do Supabase Flutter para enviar as mutações locais (Drift SQLite) ao banco
/// central remoto (Supabase PostgreSQL), com suporte a Row Level Security.
///
/// Fluxo de sync:
/// ```
/// Drift SQLite (local) → OutboxService → SyncEngine → SupabaseConnector → Supabase
/// ```
class SupabaseConnector extends CoreServerConnector {
  SupabaseConnector({
    required super.context,
    required super.hostUrl,
  });

  SupabaseClient get _client => Supabase.instance.client;

  /// Envia uma entrada da outbox local para o Supabase via operação REST.
  ///
  /// Retorna `true` se sincronizado com sucesso.
  /// Retorna `false` em falha transitória (rede) para que o SyncEngine faça retry.
  @override
  Future<bool> sendOutboxEntry(OutboxEntry entry) async {
    if (!context.hasContext) return false;

    try {
      final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
      final tableName = _tableNameFor(entry.entity);

      switch (entry.action) {
        case 'create':
          await _client.from(tableName).upsert(payload);
          break;
        case 'update':
          await _client.from(tableName).upsert(payload);
          break;
        case 'delete':
          await _client.from(tableName).delete().eq('id', entry.entityId);
          break;
        default:
          return false;
      }
      return true;
    } on PostgrestException {
      // Erro de validação/constraint no Supabase — não retentar
      return false;
    } catch (_) {
      // Erro de rede — SyncEngine aplicará backoff exponencial (5s, 30s, 2m, 10m)
      return false;
    }
  }

  /// Mapeia a entidade de domínio para o nome da tabela pública no Supabase.
  ///
  /// Convenção de nomenclatura: snake_case plural, conforme o schema público do Supabase.
  String _tableNameFor(String entity) {
    const mapping = <String, String>{
      'Pedido': 'pedidos',
      'Produto': 'produtos',
      'Categoria': 'categorias',
      'Cliente': 'clientes',
      'Empresa': 'empresas',
      'Usuario': 'usuarios',
      'TabelaPrecificacao': 'tabelas_precificacao',
      'ItemTabelaPrecificacao': 'itens_tabela_precificacao',
      'ProdutoTabelaPrecificacao': 'produtos_tabelas_precificacao',
      'FormaPagamento': 'formas_pagamento',
      'LocalEntrega': 'locais_entrega',
      'TaxaEntrega': 'taxas_entrega',
    };
    return mapping[entity] ?? entity.toLowerCase();
  }

  @override
  Map<String, String> get defaultHeaders => {
        ...super.defaultHeaders,
        'apikey': (dotenv.isInitialized ? dotenv.env['SUPABASE_ANON_KEY'] : null) ?? 'sb_publishable_PR7Yj7hXLnn5kuiNhbcAjg_x3sN7Xsy',
      };
}
