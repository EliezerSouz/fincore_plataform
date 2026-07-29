import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';

@DataClassName('TabelaPrecificacaoData')
@TableIndex(name: 'tabela_prec_tenant_idx', columns: {#tenantId})
class TabelasPrecificacaoTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
  TextColumn get nome => text()();
  TextColumn get descricao => text()();
  TextColumn get tipoPolitica => text()(); // Mapeado como String do Enum
  IntColumn get prioridade => integer()();
  BoolColumn get ativo => boolean()();

  // Novos campos de negócio
  DateTimeColumn get vigenciaInicio => dateTime().nullable()();
  DateTimeColumn get vigenciaFim => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
