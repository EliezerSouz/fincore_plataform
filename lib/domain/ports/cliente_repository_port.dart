import '../../database/app_database.dart';

abstract class IClienteRepository {
  Stream<List<Cliente>> observar();
  Future<int> salvar(ClientesCompanion cliente, {int? id});
  Future<Cliente?> porTelefone(String telefone);
  Stream<List<LocaisEntregaData>> observarLocais(int clienteId);
  Future<List<LocaisEntregaData>> obterLocais(int clienteId);
  Future<int> salvarLocal(LocaisEntregaCompanion local, {int? id});
  Future<void> excluirLocal(int id);
}
