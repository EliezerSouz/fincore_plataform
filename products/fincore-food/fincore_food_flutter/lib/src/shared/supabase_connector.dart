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
      final tableName = tableNameFor(entry.entity);

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
  /// Convenção de nomenclatura: snake_case no singular para a grande maioria, conforme o schema público do Supabase.
  String tableNameFor(String entity) {
    const mapping = <String, String>{
      'Pedido': 'pedido',
      'pedidos': 'pedido',
      'ItensPedido': 'item_pedido',
      'itens_pedido': 'item_pedido',
      'Produto': 'produto',
      'produtos': 'produto',
      'Categoria': 'categoria',
      'categorias': 'categoria',
      'Cliente': 'cliente',
      'clientes': 'cliente',
      'Empresa': 'empresa',
      'empresas': 'empresa',
      'Usuario': 'usuarios',
      'usuarios': 'usuarios',
      'usuario': 'usuarios',
      'TabelaPrecificacao': 'tabela_precificacao',
      'tabelas_precificacao': 'tabela_precificacao',
      'ItemTabelaPrecificacao': 'item_tabela_precificacao',
      'itens_tabela_precificacao': 'item_tabela_precificacao',
      'ProdutoTabelaPrecificacao': 'produto_tabela_precificacao',
      'produtos_tabelas_precificacao': 'produto_tabela_precificacao',
      'CategoriaTabelaPrecificacao': 'categoria_tabela_precificacao',
      'categorias_tabelas_precificacao': 'categoria_tabela_precificacao',
      'FormaPagamento': 'forma_pagamento',
      'formas_pagamento': 'forma_pagamento',
      'LocalEntrega': 'local_entrega',
      'locais_entrega': 'local_entrega',
      'TaxaEntrega': 'taxa_entrega',
      'taxas_entrega': 'taxa_entrega',
      'OrdemPreparo': 'ordens_preparo',
      'ordens_preparo': 'ordens_preparo',
      'HistoricoOrdemPreparo': 'historicos_ordem_preparo',
      'historicos_ordem_preparo': 'historicos_ordem_preparo',
      'EstoqueProduto': 'estoque_produto',
      'estoque_produto': 'estoque_produto',
      'MovimentacaoEstoque': 'movimentacao_estoque',
      'movimentacao_estoque': 'movimentacao_estoque',
      'PlanejamentoProducao': 'planejamento_producao',
      'planejamento_producao': 'planejamento_producao',
      'SessaoCaixa': 'sessao_caixa',
      'sessao_caixa': 'sessao_caixa',
      'LancamentoFinanceiro': 'lancamento_financeiro',
      'lancamento_financeiro': 'lancamento_financeiro',
      'empresa_configuracao': 'empresa_configuracao',
      'membro_empresa': 'membro_empresa',
      'membros_empresa': 'membro_empresa',
      'audit_log': 'audit_logs',
      'audit_logs': 'audit_logs',
    };
    return mapping[entity] ?? entity.toLowerCase();
  }

  @override
  Map<String, String> get defaultHeaders => {
        ...super.defaultHeaders,
        'apikey': (dotenv.isInitialized ? dotenv.env['SUPABASE_ANON_KEY'] : null) ?? 'sb_publishable_PR7Yj7hXLnn5kuiNhbcAjg_x3sN7Xsy',
      };
}
