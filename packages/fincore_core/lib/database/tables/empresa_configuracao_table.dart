import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';

@DataClassName('EmpresaConfiguracaoData')
class EmpresaConfiguracaoTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
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
  // ─── PARAMETRIZAÇÃO DE VENDAS & PDV ──────────────────────────────
  BoolColumn get modoDeliveryAtivo => boolean().withDefault(const Constant(true))();
  BoolColumn get modoComandasAtivo => boolean().withDefault(const Constant(false))();
  BoolColumn get clienteObrigatorioVenda => boolean().withDefault(const Constant(false))();
  TextColumn get atendimentoPadrao => text().withDefault(const Constant('Delivery'))();
  BoolColumn get mercadoPagoAtivo => boolean().withDefault(const Constant(false))();
  BoolColumn get openPixAtivo => boolean().withDefault(const Constant(false))();
  BoolColumn get asaasAtivo => boolean().withDefault(const Constant(false))();
  BoolColumn get ifoodAtivo => boolean().withDefault(const Constant(false))();
  IntColumn get margemSegurancaMinutos => integer().nullable().withDefault(const Constant(10))();
  BoolColumn get taxaEntregaPorKm => boolean().nullable().withDefault(const Constant(false))();
  IntColumn get valorPorKmCentavos => integer().nullable().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
