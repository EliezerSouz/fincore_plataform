import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';

@DataClassName('ClienteData')
@TableIndex(name: 'cliente_tenant_tel_idx', columns: {#tenantId, #telefone})
@TableIndex(name: 'cliente_tenant_doc_idx', columns: {#tenantId, #documento})
@TableIndex(name: 'cliente_tenant_ativo_idx', columns: {#tenantId, #ativo})
class ClientesTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
  TextColumn get nome => text()();
  TextColumn get telefone => text()();
  TextColumn get email => text().nullable()();
  TextColumn get documento => text().nullable()();
  TextColumn get observacoes => text()();
  BoolColumn get ativo => boolean()();

  // Novos campos de negócio
  TextColumn get apelido => text().nullable()();
  DateTimeColumn get dataNascimento => dateTime().nullable()();
  BoolColumn get aceitaWhatsapp => boolean().withDefault(const Constant(true))();
  BoolColumn get aceitaMarketing => boolean().withDefault(const Constant(false))();
  TextColumn get preferenciaEntrega => text().nullable()();
  IntColumn get limiteCredito => integer().nullable()(); // Armazenado em centavos

  @override
  Set<Column> get primaryKey => {id};
}
