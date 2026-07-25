import 'package:drift/drift.dart';
import 'connection/connection.dart';

part 'app_database.g.dart';

class GruposPreco extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nome => text().unique()();
  TextColumn get descricao => text().withDefault(const Constant(''))();
  BoolColumn get ativo => boolean().withDefault(const Constant(true))();
}

class Produtos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nome => text()();
  TextColumn get categoria => text().withDefault(const Constant('Salgados'))();
  IntColumn get grupoPrecoId =>
      integer().nullable().references(GruposPreco, #id)();
  IntColumn get tempoMedioMinutos =>
      integer().withDefault(const Constant(10))();
  BoolColumn get controlaEstoque =>
      boolean().withDefault(const Constant(true))();
  IntColumn get ordemProducao => integer().withDefault(const Constant(0))();
  BoolColumn get ativo => boolean().withDefault(const Constant(true))();
}

class FaixasPreco extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get produtoId => integer()
      .nullable()
      .references(Produtos, #id, onDelete: KeyAction.cascade)();
  IntColumn get grupoPrecoId => integer()
      .nullable()
      .references(GruposPreco, #id, onDelete: KeyAction.cascade)();
  IntColumn get quantidadeMinima => integer()();
  IntColumn get quantidadeMaxima => integer().nullable()();
  IntColumn get valorUnitarioCentavos => integer()();
}

class Clientes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nome => text()();
  TextColumn get telefone => text().withDefault(const Constant(''))();
  TextColumn get logradouro => text().withDefault(const Constant(''))();
  TextColumn get numero => text().withDefault(const Constant(''))();
  TextColumn get bairro => text().withDefault(const Constant(''))();
  TextColumn get cidade => text().withDefault(const Constant(''))();
  TextColumn get cep => text().withDefault(const Constant(''))();
  TextColumn get referencia => text().withDefault(const Constant(''))();
  TextColumn get observacoes => text().withDefault(const Constant(''))();
  BoolColumn get ativo => boolean().withDefault(const Constant(true))();
}

class LocaisEntrega extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get clienteId => integer().references(Clientes, #id, onDelete: KeyAction.cascade)();
  TextColumn get nomeIdentificador => text().withDefault(const Constant('Principal'))(); // Ex: Casa, Trabalho, Sítio
  TextColumn get logradouro => text()();
  TextColumn get numero => text()();
  TextColumn get bairro => text()();
  TextColumn get cidade => text().withDefault(const Constant(''))();
  TextColumn get cep => text().withDefault(const Constant(''))();
  TextColumn get referencia => text().withDefault(const Constant(''))();
  BoolColumn get ativo => boolean().withDefault(const Constant(true))();
}

class Pedidos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get numero => integer().unique()();
  IntColumn get clienteId => integer().references(Clientes, #id)();
  TextColumn get clienteNome => text()();
  TextColumn get clienteTelefone => text().withDefault(const Constant(''))();
  DateTimeColumn get dataEntrega => dateTime()();
  TextColumn get tipoEntrega => text()();
  TextColumn get formaPagamento => text()();
  IntColumn get trocoParaCentavos => integer().nullable()();
  TextColumn get observacoes => text().withDefault(const Constant(''))();
  IntColumn get subtotalCentavos => integer()();
  IntColumn get taxaEntregaCentavos =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalCentavos => integer()();
  TextColumn get status => text().withDefault(const Constant('Pendente'))();
  IntColumn get versao => integer().withDefault(const Constant(1))();
  TextColumn get prioridade => text().withDefault(const Constant('Normal'))();
  BoolColumn get pixConfirmado => boolean().withDefault(const Constant(false))();
  DateTimeColumn get pixConfirmadoEm => dateTime().nullable()();
  DateTimeColumn get criadoEm => dateTime().withDefault(currentDateAndTime)();
  TextColumn get comprovantePix => text().nullable()();
  IntColumn get origemId => integer().nullable().references(OrigensPedido, #id)();
  IntColumn get prioridadeId => integer().nullable().references(PrioridadesPedido, #id)();
  DateTimeColumn get dataProducao => dateTime().nullable()();
  TextColumn get statusFinanceiro => text().withDefault(const Constant('Pendente'))();
}

class ItensPedido extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get pedidoId =>
      integer().references(Pedidos, #id, onDelete: KeyAction.cascade)();
  IntColumn get produtoId => integer().references(Produtos, #id)();
  TextColumn get produtoNome => text()();
  IntColumn get quantidade => integer()();
  IntColumn get valorUnitarioCentavos => integer()();
  IntColumn get valorTotalCentavos => integer()();
}

/// Módulo de Estoque de Produtos Prontos (Sprint 6)
class EstoqueAtual extends Table {
  IntColumn get produtoId =>
      integer().references(Produtos, #id, onDelete: KeyAction.cascade)();
  IntColumn get saldoAtual => integer().withDefault(const Constant(0))();
  IntColumn get reservado => integer().withDefault(const Constant(0))();
  IntColumn get reservadoComercial => integer().withDefault(const Constant(0))();
  IntColumn get reservadoOperacional => integer().withDefault(const Constant(0))();
  IntColumn get estoqueMinimo => integer().withDefault(const Constant(0))();
  IntColumn get estoqueIdeal => integer().withDefault(const Constant(0))();
  IntColumn get loteMinimo => integer().withDefault(const Constant(1))();
  DateTimeColumn get atualizadoEm =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {produtoId};
}

class OrigensPedido extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nome => text().unique()();
  TextColumn get icone => text().nullable()();
  BoolColumn get ativo => boolean().withDefault(const Constant(true))();
}

class PrioridadesPedido extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nome => text().unique()();
  TextColumn get cor => text()();
  TextColumn get icone => text().nullable()();
  IntColumn get ordem => integer().withDefault(const Constant(0))();
}

class MovimentacoesEstoque extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get produtoId => integer().references(Produtos, #id)();
  TextColumn get tipoMovimentacao => text()();
  IntColumn get quantidade => integer()();
  IntColumn get saldoAnterior => integer()();
  IntColumn get saldoNovo => integer()();
  TextColumn get motivo => text().withDefault(const Constant(''))();
  IntColumn get pedidoId => integer().nullable().references(Pedidos, #id)();
  DateTimeColumn get criadoEm => dateTime().withDefault(currentDateAndTime)();
}

class ConfiguracoesEmpresa extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get empresa => text().withDefault(const Constant('Minha Salgaderia'))();
  TextColumn get telefone => text().withDefault(const Constant(''))();
  TextColumn get endereco => text().withDefault(const Constant(''))();
  TextColumn get rodape => text().withDefault(const Constant('Obrigado pela preferência!'))();
  TextColumn get impressora => text().withDefault(const Constant(''))();
  IntColumn get taxaPadrao => integer().withDefault(const Constant(0))();
  IntColumn get largura => integer().withDefault(const Constant(80))();
  TextColumn get horizonteOperacional => text().withDefault(const Constant('Hoje + Amanhã'))();
  TextColumn get razaoSocial => text().withDefault(const Constant(''))();
  TextColumn get whatsapp => text().withDefault(const Constant(''))();
  TextColumn get instagram => text().withDefault(const Constant(''))();
  TextColumn get logoPath => text().withDefault(const Constant(''))();
  BoolColumn get habilitarPix => boolean().withDefault(const Constant(false))();
  TextColumn get pixTipoChave => text().withDefault(const Constant('CPF'))();
  TextColumn get pixChave => text().withDefault(const Constant(''))();
  TextColumn get pixFavorecido => text().withDefault(const Constant(''))();
  TextColumn get pixBanco => text().withDefault(const Constant(''))();
  TextColumn get pixCidade => text().withDefault(const Constant('Sorocaba'))();
  TextColumn get pixMensagem => text().withDefault(const Constant('Envie o comprovante após o pagamento'))();
  BoolColumn get pixImprimirQrCode => boolean().withDefault(const Constant(true))();
  BoolColumn get pixImprimirCopiaCola => boolean().withDefault(const Constant(true))();
  BoolColumn get pixGerarQrCodeAuto => boolean().withDefault(const Constant(true))();
}

class EventosPedido extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get pedidoId => integer().references(Pedidos, #id, onDelete: KeyAction.cascade)();
  TextColumn get tipoEvento => text()(); // CRIADO, EDITADO, STATUS, PAGAMENTO, PIX_GERADO, PIX_CONFIRMADO, IMPRESSAO, REIMPRESSAO, CANCELAMENTO, REABERTURA, PRODUCAO, ESTOQUE
  TextColumn get titulo => text()();
  TextColumn get descricao => text().withDefault(const Constant(''))();
  IntColumn get usuarioId => integer().nullable()();
  TextColumn get usuarioNome => text().withDefault(const Constant('Operador'))();
  IntColumn get versao => integer().withDefault(const Constant(1))();
  DateTimeColumn get criadoEm => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [
  GruposPreco,
  Produtos,
  FaixasPreco,
  Clientes,
  LocaisEntrega,
  Pedidos,
  ItensPedido,
  EstoqueAtual,
  MovimentacoesEstoque,
  ConfiguracoesEmpresa,
  EventosPedido,
  OrigensPedido,
  PrioridadesPedido
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());
  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _criarIndices();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(gruposPreco);
            await _addColumnSafe('produtos', 'grupo_preco_id', 'INTEGER REFERENCES grupos_preco(id)');
            await _addColumnSafe('faixas_preco', 'grupo_preco_id', 'INTEGER REFERENCES grupos_preco(id)');
            final antigos = await select(produtos).get();
            for (final produto in antigos) {
              final grupoId = await into(gruposPreco).insert(
                  GruposPrecoCompanion.insert(
                      nome: 'Preços - ${produto.nome}'));
              await (update(produtos)..where((p) => p.id.equals(produto.id)))
                  .write(ProdutosCompanion(grupoPrecoId: Value(grupoId)));
              await (update(faixasPreco)
                    ..where((f) => f.produtoId.equals(produto.id)))
                  .write(FaixasPrecoCompanion(grupoPrecoId: Value(grupoId)));
            }
          }
          if (from < 3) {
            await _criarIndices();
          }
          if (from < 4) {
            await customStatement('CREATE TABLE IF NOT EXISTS estoque_atual '
                '(id INTEGER PRIMARY KEY AUTOINCREMENT, produto_id INTEGER NOT NULL UNIQUE REFERENCES produtos(id), '
                'quantidade INTEGER NOT NULL DEFAULT 0, atualizado_em INTEGER NOT NULL)');
            await customStatement('CREATE TABLE IF NOT EXISTS movimentacoes_estoque '
                '(id INTEGER PRIMARY KEY AUTOINCREMENT, produto_id INTEGER NOT NULL REFERENCES produtos(id), '
                'tipo TEXT NOT NULL, quantidade INTEGER NOT NULL, pedido_id INTEGER REFERENCES pedidos(id), '
                'observacao TEXT NOT NULL DEFAULT \'\', criado_em INTEGER NOT NULL, responsavel TEXT NOT NULL DEFAULT \'\')');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_mov_estoque_prod ON movimentacoes_estoque(produto_id, criado_em DESC)');
          }
          if (from < 5) {
            await customStatement('CREATE TABLE IF NOT EXISTS locais_entrega '
                '(id INTEGER PRIMARY KEY AUTOINCREMENT, cliente_id INTEGER NOT NULL REFERENCES clientes(id), '
                'apelido TEXT NOT NULL, logradouro TEXT NOT NULL DEFAULT \'\', numero TEXT NOT NULL DEFAULT \'\', '
                'complemento TEXT NOT NULL DEFAULT \'\', bairro TEXT NOT NULL DEFAULT \'\', '
                'cidade TEXT NOT NULL DEFAULT \'\', estado TEXT NOT NULL DEFAULT \'\', '
                'cep TEXT NOT NULL DEFAULT \'\', referencia TEXT NOT NULL DEFAULT \'\', '
                'ativo INTEGER NOT NULL DEFAULT 1, criado_em INTEGER NOT NULL)');
          }
          if (from < 6) {
            await _addColumnSafe('estoque_atual', 'reservado', 'INTEGER NOT NULL DEFAULT 0');
            await _addColumnSafe('produtos', 'tempo_medio_minutos', 'INTEGER NOT NULL DEFAULT 60');
            await _addColumnSafe('produtos', 'controla_estoque', 'INTEGER NOT NULL DEFAULT 1');
            await _addColumnSafe('produtos', 'ordem_producao', 'INTEGER NOT NULL DEFAULT 0');
          }
          if (from < 7) {
            await _addColumnSafe('estoque_atual', 'estoque_ideal', 'INTEGER NOT NULL DEFAULT 0');
            await _addColumnSafe('estoque_atual', 'lote_minimo', 'INTEGER NOT NULL DEFAULT 0');
          }
          if (from < 8) {
            await customStatement('CREATE TABLE IF NOT EXISTS configuracoes_empresa '
                '(id INTEGER PRIMARY KEY AUTOINCREMENT, empresa TEXT NOT NULL DEFAULT \'\', '
                'telefone TEXT NOT NULL DEFAULT \'\', endereco TEXT NOT NULL DEFAULT \'\', '
                'chave_pix TEXT NOT NULL DEFAULT \'\', tipo_chave_pix TEXT NOT NULL DEFAULT \'\', '
                'imprimir_qr_code INTEGER NOT NULL DEFAULT 0, imprimir_copia_cola INTEGER NOT NULL DEFAULT 0, '
                'nome_recebedor TEXT NOT NULL DEFAULT \'\', pix_cidade TEXT NOT NULL DEFAULT \'\', '
                'pix_mensagem TEXT NOT NULL DEFAULT \'\')');
            await customStatement('CREATE TABLE IF NOT EXISTS eventos_pedido '
                '(id INTEGER PRIMARY KEY AUTOINCREMENT, pedido_id INTEGER NOT NULL REFERENCES pedidos(id), '
                'tipo TEXT NOT NULL, descricao TEXT NOT NULL DEFAULT \'\', responsavel TEXT NOT NULL DEFAULT \'\', '
                'criado_em INTEGER NOT NULL)');
            await _addColumnSafe('pedidos', 'versao', 'INTEGER NOT NULL DEFAULT 1');
            await _addColumnSafe('pedidos', 'prioridade', 'TEXT NOT NULL DEFAULT \'Normal\'');
            await _addColumnSafe('pedidos', 'pix_confirmado', 'INTEGER NOT NULL DEFAULT 0');
            await _addColumnSafe('pedidos', 'pix_confirmado_em', 'INTEGER');
            await _addColumnSafe('pedidos', 'comprovante_pix', 'TEXT');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_eventos_pedido_id ON eventos_pedido(pedido_id)');
          }
          if (from < 9) {
            await _addColumnSafe('configuracoes_empresa', 'pix_gerar_qr_code_auto', 'INTEGER NOT NULL DEFAULT 0');
            await _criarIndices();
          }
          if (from < 10) {
            // 1. Recria faixas_preco removendo o NOT NULL de produto_id
            // (SQLite não suporta ALTER COLUMN, então recriar é necessário)
            await customStatement('PRAGMA foreign_keys = OFF');
            await customStatement(
              'CREATE TABLE IF NOT EXISTS faixas_preco_new ('
              '  id INTEGER PRIMARY KEY AUTOINCREMENT,'
              '  produto_id INTEGER REFERENCES produtos(id) ON DELETE CASCADE,'
              '  grupo_preco_id INTEGER REFERENCES grupos_preco(id) ON DELETE CASCADE,'
              '  quantidade_minima INTEGER NOT NULL,'
              '  quantidade_maxima INTEGER,'
              '  valor_unitario_centavos INTEGER NOT NULL'
              ')'
            );
            await customStatement(
              'INSERT INTO faixas_preco_new '
              '(id, produto_id, grupo_preco_id, quantidade_minima, quantidade_maxima, valor_unitario_centavos) '
              'SELECT id, produto_id, grupo_preco_id, quantidade_minima, quantidade_maxima, valor_unitario_centavos '
              'FROM faixas_preco'
            );
            await customStatement('DROP TABLE faixas_preco');
            await customStatement('ALTER TABLE faixas_preco_new RENAME TO faixas_preco');
            await customStatement('PRAGMA foreign_keys = ON');

            // 2. Colunas faltantes em configuracoes_empresa
            await _addColumnSafe('configuracoes_empresa', 'rodape', "TEXT NOT NULL DEFAULT 'Obrigado pela preferência!'");
            await _addColumnSafe('configuracoes_empresa', 'impressora', "TEXT NOT NULL DEFAULT ''");
            await _addColumnSafe('configuracoes_empresa', 'taxa_padrao', 'INTEGER NOT NULL DEFAULT 0');
            await _addColumnSafe('configuracoes_empresa', 'largura', 'INTEGER NOT NULL DEFAULT 80');
            await _addColumnSafe('configuracoes_empresa', 'horizonte_operacional', "TEXT NOT NULL DEFAULT 'Hoje + Amanhã'");
            await _addColumnSafe('configuracoes_empresa', 'razao_social', "TEXT NOT NULL DEFAULT ''");
            await _addColumnSafe('configuracoes_empresa', 'whatsapp', "TEXT NOT NULL DEFAULT ''");
            await _addColumnSafe('configuracoes_empresa', 'instagram', "TEXT NOT NULL DEFAULT ''");
            await _addColumnSafe('configuracoes_empresa', 'logo_path', "TEXT NOT NULL DEFAULT ''");
            await _addColumnSafe('configuracoes_empresa', 'habilitar_pix', 'INTEGER NOT NULL DEFAULT 0');
            await _addColumnSafe('configuracoes_empresa', 'pix_tipo_chave', "TEXT NOT NULL DEFAULT 'CPF'");
            await _addColumnSafe('configuracoes_empresa', 'pix_chave', "TEXT NOT NULL DEFAULT ''");
            await _addColumnSafe('configuracoes_empresa', 'pix_favorecido', "TEXT NOT NULL DEFAULT ''");
            await _addColumnSafe('configuracoes_empresa', 'pix_banco', "TEXT NOT NULL DEFAULT ''");
            await _addColumnSafe('configuracoes_empresa', 'pix_cidade', "TEXT NOT NULL DEFAULT 'Sorocaba'");
            await _addColumnSafe('configuracoes_empresa', 'pix_mensagem', "TEXT NOT NULL DEFAULT 'Envie o comprovante após o pagamento'");
            await _addColumnSafe('configuracoes_empresa', 'pix_imprimir_qr_code', 'INTEGER NOT NULL DEFAULT 1');
            await _addColumnSafe('configuracoes_empresa', 'pix_imprimir_copia_cola', 'INTEGER NOT NULL DEFAULT 1');

            // 3. Colunas faltantes em eventos_pedido
            await _addColumnSafe('eventos_pedido', 'tipo_evento', "TEXT NOT NULL DEFAULT ''");
            await _addColumnSafe('eventos_pedido', 'titulo', "TEXT NOT NULL DEFAULT ''");
            await _addColumnSafe('eventos_pedido', 'usuario_id', 'INTEGER');
            await _addColumnSafe('eventos_pedido', 'usuario_nome', "TEXT NOT NULL DEFAULT 'Operador'");
            await _addColumnSafe('eventos_pedido', 'versao', 'INTEGER NOT NULL DEFAULT 1');

            // 4. Estoque minimo em estoque_atual
            await _addColumnSafe('estoque_atual', 'estoque_minimo', 'INTEGER NOT NULL DEFAULT 0');

            await _criarIndices();
          }
          if (from < 11) {
            // Recria eventos_pedido removendo as colunas obsoletas ("tipo", "responsavel")
            // que eram NOT NULL e causavam erro ao inserir dados com o novo schema
            await customStatement('PRAGMA foreign_keys = OFF');
            await customStatement(
              'CREATE TABLE IF NOT EXISTS eventos_pedido_new ('
              '  id INTEGER PRIMARY KEY AUTOINCREMENT,'
              '  pedido_id INTEGER NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,'
              '  tipo_evento TEXT NOT NULL,'
              '  titulo TEXT NOT NULL,'
              '  descricao TEXT NOT NULL DEFAULT \'\','
              '  usuario_id INTEGER,'
              '  usuario_nome TEXT NOT NULL DEFAULT \'Operador\','
              '  versao INTEGER NOT NULL DEFAULT 1,'
              '  criado_em INTEGER NOT NULL'
              ')'
            );

            try {
              final colunas = await customSelect("PRAGMA table_info(eventos_pedido)").get();
              final temTipo = colunas.any((c) => c.data['name'] == 'tipo');
              final temResponsavel = colunas.any((c) => c.data['name'] == 'responsavel');
              
              final selectTipo = temTipo ? 'tipo' : 'tipo_evento';
              final selectResponsavel = temResponsavel ? 'responsavel' : 'usuario_nome';

              await customStatement(
                'INSERT INTO eventos_pedido_new '
                '(id, pedido_id, tipo_evento, titulo, descricao, usuario_nome, versao, criado_em) '
                'SELECT id, pedido_id, $selectTipo, \'Evento\', descricao, $selectResponsavel, 1, criado_em '
                'FROM eventos_pedido'
              );
            } catch (_) {}

            await customStatement('DROP TABLE IF EXISTS eventos_pedido');
            await customStatement('ALTER TABLE eventos_pedido_new RENAME TO eventos_pedido');
            await customStatement('PRAGMA foreign_keys = ON');
            await _criarIndicesEventos();
          }
          if (from < 12) {
            await m.createTable(origensPedido);
            await m.createTable(prioridadesPedido);

            await _addColumnSafe('pedidos', 'origem_id', 'INTEGER REFERENCES origens_pedido(id)');
            await _addColumnSafe('pedidos', 'prioridade_id', 'INTEGER REFERENCES prioridades_pedido(id)');
            await _addColumnSafe('pedidos', 'data_producao', 'INTEGER');
            await _addColumnSafe('pedidos', 'status_financeiro', "TEXT NOT NULL DEFAULT 'Pendente'");

            await _addColumnSafe('estoque_atual', 'reservado_comercial', 'INTEGER NOT NULL DEFAULT 0');
            await _addColumnSafe('estoque_atual', 'reservado_operacional', 'INTEGER NOT NULL DEFAULT 0');

            await customStatement("INSERT OR IGNORE INTO origens_pedido (id, nome, icone, ativo) VALUES (1, 'Balcão', 'storefront', 1)");
            await customStatement("INSERT OR IGNORE INTO origens_pedido (id, nome, icone, ativo) VALUES (2, 'WhatsApp', 'chat', 1)");
            await customStatement("INSERT OR IGNORE INTO origens_pedido (id, nome, icone, ativo) VALUES (3, 'iFood', 'delivery_dining', 1)");

            await customStatement("INSERT OR IGNORE INTO prioridades_pedido (id, nome, cor, icone, ordem) VALUES (1, 'Normal', 'green', 'info', 0)");
            await customStatement("INSERT OR IGNORE INTO prioridades_pedido (id, nome, cor, icone, ordem) VALUES (2, 'Urgente', 'orange', 'warning', 1)");
            await customStatement("INSERT OR IGNORE INTO prioridades_pedido (id, nome, cor, icone, ordem) VALUES (3, 'VIP', 'purple', 'star', 2)");
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Adiciona uma coluna somente se ela ainda não existir (usa PRAGMA table_info).
  Future<void> _addColumnSafe(String table, String column, String definition) async {
    final rows = await customSelect(
      'PRAGMA table_info("$table")',
      readsFrom: {},
    ).get();
    final exists = rows.any((r) => (r.data['name'] as String?) == column);
    if (!exists) {
      await customStatement('ALTER TABLE "$table" ADD COLUMN "$column" $definition');
    }
  }


  Future<void> _criarIndices() async {
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_clientes_telefone ON clientes(telefone)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_pedidos_criado_status ON pedidos(criado_em DESC, status)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_faixas_grupo ON faixas_preco(grupo_preco_id)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_pedidos_status_entrega ON pedidos(status, data_entrega)');
  }

  Future<void> _criarIndicesEventos() async {
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_eventos_pedido_id ON eventos_pedido(pedido_id)');
  }

  static QueryExecutor _openConnection() => connectDatabase();

  Future<int> proximoNumero() => transaction(() async {
        final maior = pedidos.numero.max();
        final row =
            await (selectOnly(pedidos)..addColumns([maior])).getSingle();
        return (row.read(maior) ?? 0) + 1;
      });
}
