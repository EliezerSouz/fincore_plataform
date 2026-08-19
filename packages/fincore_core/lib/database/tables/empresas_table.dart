import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';

@DataClassName('EmpresaData')
class EmpresasTable extends Table with AuditColumns, SyncColumns {
  TextColumn get id => text()(); // UUID (PK)
  TextColumn get razaoSocial => text()();
  TextColumn get nomeFantasia => text()();
  TextColumn get documentoFiscal => text()();
  TextColumn get email => text()();
  TextColumn get telefone => text()();
  TextColumn get status => text()();
  TextColumn get plano => text()();
  TextColumn get timezone => text()();
  TextColumn get locale => text()();
  TextColumn get currency => text()();
  TextColumn get country => text()();
  TextColumn get createdFrom => text()();
  DateTimeColumn get vencimento => dateTime().nullable()();
  TextColumn get segmento => text().nullable()();
  
  // Novos campos fiscais e cadastrais da reengenharia funcional
  TextColumn get tipoPessoa => text().withDefault(const Constant('JURIDICA'))(); // FISICA | JURIDICA
  TextColumn get inscricaoEstadual => text().nullable()();
  TextColumn get inscricaoMunicipal => text().nullable()();
  TextColumn get regimeTributario => text().nullable()();
  // ─── Endereço Estruturado ────────────────────────────────────────
  // Padrão idêntico ao LocaisEntregaTable
  TextColumn get cep => text().nullable()();
  TextColumn get logradouro => text().nullable()();
  TextColumn get numero => text().nullable()();
  TextColumn get complemento => text().nullable()();
  TextColumn get bairro => text().nullable()();
  TextColumn get cidade => text().nullable()();
  TextColumn get estado => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
