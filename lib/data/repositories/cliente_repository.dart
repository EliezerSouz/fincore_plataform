import 'package:drift/drift.dart';
import '../../database/app_database.dart';
import '../../domain/ports/cliente_repository_port.dart';

class ClienteRepository implements IClienteRepository {
  final AppDatabase db;
  ClienteRepository(this.db);

  @override
  Stream<List<Cliente>> observar() => (db.select(db.clientes)
        ..where((c) => c.ativo.equals(true))
        ..orderBy([(c) => OrderingTerm.asc(c.nome)]))
      .watch();

  @override
  Future<int> salvar(ClientesCompanion cliente, {int? id}) => id == null
      ? db.into(db.clientes).insert(cliente)
      : (db.update(db.clientes)..where((c) => c.id.equals(id)))
          .write(cliente)
          .then((_) => id);

  @override
  Future<Cliente?> porTelefone(String telefone) => (db.select(db.clientes)
        ..where((c) => c.telefone.equals(telefone))
        ..limit(1))
      .getSingleOrNull();

  @override
  Stream<List<LocaisEntregaData>> observarLocais(int clienteId) =>
      (db.select(db.locaisEntrega)
            ..where(
                (l) => l.clienteId.equals(clienteId) & l.ativo.equals(true)))
          .watch();

  @override
  Future<List<LocaisEntregaData>> obterLocais(int clienteId) =>
      (db.select(db.locaisEntrega)
            ..where(
                (l) => l.clienteId.equals(clienteId) & l.ativo.equals(true)))
          .get();

  @override
  Future<int> salvarLocal(LocaisEntregaCompanion local, {int? id}) => id ==
          null
      ? db.into(db.locaisEntrega).insert(local)
      : (db.update(db.locaisEntrega)..where((l) => l.id.equals(id)))
          .write(local)
          .then((_) => id);

  @override
  Future<void> excluirLocal(int id) =>
      (db.update(db.locaisEntrega)..where((l) => l.id.equals(id)))
          .write(const LocaisEntregaCompanion(ativo: Value(false)));
}
