import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';

@DataClassName('EmpresaConfiguracaoData')
class EmpresaConfiguracaoTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
  TextColumn get timezone => text().withDefault(const Constant('America/Sao_Paulo'))();
  TextColumn get locale => text().withDefault(const Constant('pt_BR'))();
  TextColumn get currency => text().withDefault(const Constant('BRL'))();
  TextColumn get printerConfig => text().nullable()(); // Legado — mantido para compatibilidade
  TextColumn get pixKey => text().nullable()();
  RealColumn get taxaServico => real().withDefault(const Constant(0.10))();
  BoolColumn get usarWhatsApp => boolean().withDefault(const Constant(true))();
  TextColumn get logoUrl => text().nullable()();
  TextColumn get tema => text().withDefault(const Constant('escuro'))();

  // ─── CAP.PRINTING: Impressoras por Via ────────────────────────────
  TextColumn get printerCaixa => text().nullable()();
  TextColumn get printerCozinha => text().nullable()();
  TextColumn get printerBalcao => text().nullable()();
  TextColumn get printerExpedicao => text().nullable()();

  // ─── CAP.PRINTING: Auto-print por Via ────────────────────────────
  BoolColumn get autoPrintCaixa => boolean().withDefault(const Constant(true))();
  BoolColumn get autoPrintCozinha => boolean().withDefault(const Constant(true))();
  BoolColumn get autoPrintBalcao => boolean().withDefault(const Constant(false))();
  BoolColumn get autoPrintExpedicao => boolean().withDefault(const Constant(false))();

  // ─── CAP.PRINTING: Número de Vias (Cópias) ──────────────────────
  IntColumn get viasCliente => integer().withDefault(const Constant(1))();
  IntColumn get viasCozinha => integer().withDefault(const Constant(1))();
  IntColumn get viasBalcao => integer().withDefault(const Constant(0))();
  IntColumn get viasExpedicao => integer().withDefault(const Constant(0))();

  // ─── CAP.PRINTING: Papel e Hardware ──────────────────────────────
  IntColumn get larguraPapel => integer().withDefault(const Constant(80))();
  BoolColumn get cortarPapel => boolean().withDefault(const Constant(true))();
  BoolColumn get abrirGaveta => boolean().withDefault(const Constant(false))();

  // ─── CAP.PRINTING: QR Code e Layout ──────────────────────────────
  BoolColumn get imprimirQRCode => boolean().withDefault(const Constant(true))();
  BoolColumn get imprimirCopiaCola => boolean().withDefault(const Constant(true))();
  BoolColumn get imprimirLogo => boolean().withDefault(const Constant(false))();
  BoolColumn get imprimirRodape => boolean().withDefault(const Constant(true))();
  TextColumn get mensagemRodape => text().withDefault(const Constant('Obrigado pela preferência!'))();

  // ─── CAP.PRINTING: PIX Expandido ─────────────────────────────────
  TextColumn get pixFavorecido => text().nullable()();
  TextColumn get pixBanco => text().nullable()();
  TextColumn get pixTipo => text().withDefault(const Constant('CPF'))();
  TextColumn get pixCidade => text().withDefault(const Constant('Sorocaba'))();

  // ─── CAP.PRINTING: Dados do Cupom ────────────────────────────────
  TextColumn get nomeEmpresaCupom => text().nullable()();
  TextColumn get telefoneEmpresa => text().nullable()();
  TextColumn get cnpjEmpresa => text().nullable()();
  TextColumn get enderecoEmpresa => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
