import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/repository/cliente_repository.dart';
import 'package:fincore_core/repository/local_entrega_repository.dart';
import 'package:fincore_core/repository/taxa_entrega_repository.dart';
import 'package:fincore_core/repository/audit_log_repository.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/di/dependency_injection.dart';

/// Controller de Clientes — gerencia estado e lógica de negócio.
///
/// ## Fase 3 — Refatoração Estratégica
/// Separa toda a lógica de negócio da [ClientesPage], que passa a ser
/// responsável apenas por renderizar o estado exposto aqui.
///
/// ## Padrão: ChangeNotifier (nativo Flutter, sem dependências extras)
class ClientesController extends ChangeNotifier {
  final ClienteRepository _clienteRepo;
  final LocalEntregaRepository _localRepo;
  final TaxaEntregaRepository _taxaRepo;

  // ─── Estado interno ────────────────────────────────────────────────────────
  List<Cliente> _clientes = [];
  List<Cliente> _filteredClientes = [];
  List<LocalEntrega> _enderecos = [];
  List<TaxaEntrega> _taxas = [];
  List<PedidoData> _todosPedidos = [];
  Cliente? _selectedCliente;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _filtroStatus = 'Todos';

  ClientesController({
    required ClienteRepository clienteRepo,
    required LocalEntregaRepository localRepo,
    required TaxaEntregaRepository taxaRepo,
  })  : _clienteRepo = clienteRepo,
        _localRepo = localRepo,
        _taxaRepo = taxaRepo;

  // ─── Getters públicos (somente leitura para a UI) ─────────────────────────
  List<Cliente> get clientes => _clientes;
  List<Cliente> get filteredClientes => _filteredClientes;
  List<LocalEntrega> get enderecos => _enderecos;
  List<TaxaEntrega> get taxas => _taxas;
  List<PedidoData> get todosPedidos => _todosPedidos;
  Cliente? get selectedCliente => _selectedCliente;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get filtroStatus => _filtroStatus;

  // ─── Métodos Auxiliares de Métricas dos Clientes ───────────────────────────
  List<PedidoData> getPedidosDoCliente(String clienteId) {
    return _todosPedidos.where((p) => p.clienteId == clienteId).toList();
  }

  int getCountPedidos(String clienteId) {
    return _todosPedidos.where((p) => p.clienteId == clienteId && p.status != 'cancelado').length;
  }

  int getTotalGastoCentavos(String clienteId) {
    return _todosPedidos
        .where((p) => p.clienteId == clienteId && p.status != 'cancelado')
        .fold<int>(0, (sum, p) => sum + p.valorTotalCentavos);
  }

  int getTicketMedioCentavos(String clienteId) {
    final count = getCountPedidos(clienteId);
    if (count == 0) return 0;
    return (getTotalGastoCentavos(clienteId) / count).round();
  }

  PedidoData? getUltimoPedido(String clienteId) {
    final clientPedidos = getPedidosDoCliente(clienteId);
    if (clientPedidos.isEmpty) return null;
    return clientPedidos.first; // Já ordenado do mais novo ao mais antigo
  }

  Future<List<ItemPedidoData>> getItensDoPedido(String pedidoId) async {
    final db = DependencyInjection().get<FincoreDatabase>();
    return (db.select(db.itensPedidoTable)
          ..where((t) => t.pedidoId.equals(pedidoId) & t.deletedAt.isNull()))
        .get();
  }

  // ─── Ações públicas ────────────────────────────────────────────────────────

  /// Carrega todos os clientes e taxas de entrega do banco local.
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _clienteRepo.findAll();
      var taxas = await _taxaRepo.findAll();

      // Se não houver taxas cadastradas, inicializa com padrão
      if (taxas.isEmpty) {
        final tenantCtx = DependencyInjection().get<TenantContext>();
        final defaults = [
          TaxaEntrega(
            id: const Uuid().v4(), // P2-06: UUID dinâmico — não mais fixo para evitar colisão entre tenants
            tenantId: tenantCtx.tenantId,
            nome: 'Centro / Adjacências',
            tipoRegra: TipoRegraTaxaEntrega.bairro,
            bairro: 'Centro',
            valorCentavos: 500,
            ativo: true,
            metadata: SyncMetadata(
              version: 1,
              createdAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
              createdBy: tenantCtx.usuario.id,
              updatedBy: tenantCtx.usuario.id,
            ),
          ),
        ];
        for (final t in defaults) {
          await _taxaRepo.save(t);
        }
        taxas = await _taxaRepo.findAll();
      }

      final db = DependencyInjection().get<FincoreDatabase>();
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final listPedidos = await (db.select(db.pedidosTable)
            ..where((t) => t.tenantId.equals(tenantCtx.tenantId)))
          .get();
      listPedidos.sort((a, b) => b.dataHoraCriacao.compareTo(a.dataHoraCriacao));
      _todosPedidos = listPedidos;

      _clientes = list;
      _taxas = taxas;
      _applyFilters();
      _isLoading = false;
    } catch (e) {
      _errorMessage = 'Erro ao carregar clientes: $e';
      _isLoading = false;
    }

    notifyListeners();
  }

  /// Atualiza o texto de busca e reaplica os filtros.
  void updateSearch(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Atualiza o status de filtro e reaplica os filtros.
  void updateFiltroStatus(String status) {
    _filtroStatus = status;
    _applyFilters();
    notifyListeners();
  }

  String _normalizeString(String str) {
    var s = str.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[áàãâä]'), 'a');
    s = s.replaceAll(RegExp(r'[éèêë]'), 'e');
    s = s.replaceAll(RegExp(r'[íìîï]'), 'i');
    s = s.replaceAll(RegExp(r'[óòõôö]'), 'o');
    s = s.replaceAll(RegExp(r'[úùûü]'), 'u');
    s = s.replaceAll(RegExp(r'[ç]'), 'c');
    return s;
  }

  List<LocalEntrega> _deduplicarEnderecos(List<LocalEntrega> lista) {
    if (lista.isEmpty) return [];

    final sorted = List<LocalEntrega>.from(lista)
      ..sort((a, b) => b.logradouro.length.compareTo(a.logradouro.length));

    final List<LocalEntrega> unicos = [];

    for (final loc in sorted) {
      final logrClean = _normalizeString(loc.logradouro);
      final numClean = _normalizeString(loc.numero);

      final bool eIncompleto = unicos.any((rep) {
        final repNum = _normalizeString(rep.numero);
        final repLogr = _normalizeString(rep.logradouro);

        final mesmoNumeroPrefix = repNum == numClean || (repNum.isNotEmpty && repNum.startsWith(numClean));
        final mesmaRuaPrefix = repLogr == logrClean || repLogr.startsWith(logrClean);

        return mesmaRuaPrefix && mesmoNumeroPrefix;
      });

      if (!eIncompleto) {
        unicos.add(loc);
      }
    }

    return unicos;
  }

  /// Seleciona um cliente e carrega seus endereços.
  Future<void> selectCliente(Cliente? cliente) async {
    if (cliente == null) {
      _selectedCliente = null;
      _enderecos = [];
      notifyListeners();
      return;
    }

    _selectedCliente = cliente;
    _enderecos = [];
    notifyListeners();

    try {
      final ends = await _localRepo.findByClienteId(cliente.id);
      if (_selectedCliente?.id == cliente.id) {
        _enderecos = _deduplicarEnderecos(ends);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao carregar endereços do cliente: $e');
    }
  }

  /// Salva um cliente novo ou edita um existente.
  /// Retorna `true` em caso de sucesso, `false` em caso de erro.
  Future<bool> salvarCliente({
    required Cliente? original,
    required String nome,
    required String telefone,
    String? email,
    String? documento,
    required String observacoes,
    required bool ativo,
    String? apelido,
    DateTime? dataNascimento,
    required bool aceitaWhatsapp,
    required bool aceitaMarketing,
    String? preferenciaEntrega,
    int? limiteCredito,
  }) async {
    if (nome.trim().isEmpty || telefone.trim().isEmpty) return false;

    if (original != null && _isConsumidorFinal(original)) {
      _errorMessage = 'O cliente Consumidor Final é protegido pelo sistema e não pode ser editado.';
      return false;
    }

    _isSaving = true;
    notifyListeners();

    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final isNew = original == null;
      final id = isNew ? const Uuid().v4() : original.id;

      final emailFinal = email?.trim().isEmpty == true ? null : email?.trim();
      final docFinal = documento?.trim().isEmpty == true ? null : documento?.trim();

      final cliente = Cliente(
        id: id,
        tenantId: tenantCtx.tenantId,
        nome: nome.trim(),
        telefone: telefone.trim(),
        email: emailFinal,
        documento: docFinal,
        observacoes: observacoes.trim(),
        ativo: ativo,
        apelido: apelido?.trim().isEmpty == true ? null : apelido?.trim(),
        dataNascimento: dataNascimento,
        aceitaWhatsapp: aceitaWhatsapp,
        aceitaMarketing: aceitaMarketing,
        preferenciaEntrega: preferenciaEntrega?.trim().isEmpty == true ? null : preferenciaEntrega?.trim(),
        limiteCredito: limiteCredito,
        metadata: original?.metadata.copyWith(
              updatedAt: DateTime.now().toUtc(),
              syncStatus: SyncStatus.pending,
            ) ??
            SyncMetadata(
              version: 1,
              createdAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
              createdBy: tenantCtx.usuario.id,
              updatedBy: tenantCtx.usuario.id,
              syncStatus: SyncStatus.pending,
            ),
      );

      await _clienteRepo.save(cliente);

      // Registrar auditoria
      try {
        final auditLogRepo = DependencyInjection().get<AuditLogRepository>();
        final currentUserId = tenantCtx.hasContext ? tenantCtx.usuario.id : 'system';
        await auditLogRepo.log(
          entityName: 'clientes',
          entityId: cliente.id,
          userId: currentUserId,
          action: isNew ? 'CREATE' : 'UPDATE',
          entityDisplayName: cliente.nome,
          entityModule: 'Cadastros',
          diff: {
            'nome': cliente.nome,
            'telefone': cliente.telefone,
            'email': cliente.email,
            'documento': cliente.documento,
            'observacoes': cliente.observacoes,
            'ativo': cliente.ativo,
            'apelido': cliente.apelido,
            'dataNascimento': cliente.dataNascimento?.toIso8601String(),
            'aceitaWhatsapp': cliente.aceitaWhatsapp,
            'aceitaMarketing': cliente.aceitaMarketing,
            'preferenciaEntrega': cliente.preferenciaEntrega,
            'limiteCredito': cliente.limiteCredito,
          },
        );
      } catch (logErr) {
        debugPrint('Erro ao salvar log de auditoria de cliente: $logErr');
      }

      await loadData();
      final fresh = _clientes.firstWhere((c) => c.id == id, orElse: () => cliente);
      await selectCliente(fresh);
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar cliente: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Exclui um cliente (soft delete) e desativa seleção.
  Future<bool> deletarCliente(Cliente cliente) async {
    if (_isConsumidorFinal(cliente)) {
      _errorMessage = 'O cliente Consumidor Final é protegido pelo sistema e não pode ser excluído.';
      return false;
    }

    _isSaving = true;
    notifyListeners();

    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      await _clienteRepo.delete(cliente.id);

      // Registrar auditoria
      try {
        final auditLogRepo = DependencyInjection().get<AuditLogRepository>();
        final currentUserId = tenantCtx.hasContext ? tenantCtx.usuario.id : 'system';
        await auditLogRepo.log(
          entityName: 'clientes',
          entityId: cliente.id,
          userId: currentUserId,
          action: 'DELETE',
          entityDisplayName: cliente.nome,
          entityModule: 'Cadastros',
          diff: {'deleted': true},
        );
      } catch (logErr) {
        debugPrint('Erro ao salvar log de auditoria de exclusão de cliente: $logErr');
      }

      _selectedCliente = null;
      await loadData();
      return true;
    } catch (e) {
      debugPrint('Erro ao excluir cliente: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Salva ou edita um local de entrega de um cliente.
  Future<bool> salvarEndereco({
    required LocalEntrega? original,
    required String clienteId,
    required String nomeIdentificador,
    required String logradouro,
    required String numero,
    required String bairro,
    required String cidade,
    required String cep,
    required String referencia,
    required bool ativo,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final isNew = original == null;
      final id = isNew ? const Uuid().v4() : original.id;

      final local = LocalEntrega(
        id: id,
        tenantId: tenantCtx.tenantId,
        clienteId: clienteId,
        nomeIdentificador: nomeIdentificador,
        logradouro: logradouro,
        numero: numero,
        bairro: bairro,
        cidade: cidade,
        cep: cep,
        referencia: referencia,
        ativo: ativo,
        metadata: original?.metadata.copyWith(
              updatedAt: DateTime.now().toUtc(),
              syncStatus: SyncStatus.pending,
            ) ??
            SyncMetadata(
              version: 1,
              createdAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
              createdBy: tenantCtx.usuario.id,
              updatedBy: tenantCtx.usuario.id,
              syncStatus: SyncStatus.pending,
            ),
      );

      await _localRepo.save(local);

      // Registrar auditoria
      try {
        final auditLogRepo = DependencyInjection().get<AuditLogRepository>();
        final currentUserId = tenantCtx.hasContext ? tenantCtx.usuario.id : 'system';
        await auditLogRepo.log(
          entityName: 'locais_entrega',
          entityId: local.id,
          userId: currentUserId,
          action: isNew ? 'CREATE' : 'UPDATE',
          entityDisplayName: local.nomeIdentificador,
          entityModule: 'Cadastros',
          diff: {
            'clienteId': local.clienteId,
            'nomeIdentificador': local.nomeIdentificador,
            'logradouro': local.logradouro,
            'numero': local.numero,
            'bairro': local.bairro,
            'cidade': local.cidade,
            'cep': local.cep,
            'referencia': local.referencia,
            'ativo': local.ativo,
          },
        );
      } catch (logErr) {
        debugPrint('Erro ao salvar log de auditoria de endereço: $logErr');
      }

      if (_selectedCliente != null) {
        await selectCliente(_selectedCliente);
      }
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar endereço de entrega: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Remove logicamente um endereço de entrega.
  Future<bool> excluirEndereco(LocalEntrega local) async {
    _isSaving = true;
    notifyListeners();

    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      await _localRepo.delete(local.id);

      // Registrar auditoria
      try {
        final auditLogRepo = DependencyInjection().get<AuditLogRepository>();
        final currentUserId = tenantCtx.hasContext ? tenantCtx.usuario.id : 'system';
        await auditLogRepo.log(
          entityName: 'locais_entrega',
          entityId: local.id,
          userId: currentUserId,
          action: 'DELETE',
          entityDisplayName: local.nomeIdentificador,
          entityModule: 'Cadastros',
          diff: {'deleted': true},
        );
      } catch (logErr) {
        debugPrint('Erro ao salvar log de auditoria de exclusão de endereço: $logErr');
      }

      if (_selectedCliente != null) {
        await selectCliente(_selectedCliente);
      }
      return true;
    } catch (e) {
      debugPrint('Erro ao excluir endereço de entrega: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Resolve a taxa de entrega aplicável com base nas regras do tenant
  TaxaEntrega? resolverTaxaParaEndereco(LocalEntrega endereco) {
    if (_taxas.isEmpty) return null;

    final cleanedCep = endereco.cep.replaceAll(RegExp(r'\D'), '');
    final activeTaxas = _taxas.where((t) => t.ativo).toList();

    // 1. Regra por CEP (exato ou faixa)
    if (cleanedCep.isNotEmpty) {
      for (final rule in activeTaxas.where((t) => t.tipoRegra == TipoRegraTaxaEntrega.cep)) {
        final init = rule.cepInicial?.replaceAll(RegExp(r'\D'), '') ?? '';
        final end = rule.cepFinal?.replaceAll(RegExp(r'\D'), '') ?? '';

        if (init.isNotEmpty) {
          if (end.isEmpty && cleanedCep == init) {
            return rule;
          } else if (end.isNotEmpty && cleanedCep.compareTo(init) >= 0 && cleanedCep.compareTo(end) <= 0) {
            return rule;
          }
        }
      }
    }

    // 2. Regra por Bairro (case-insensitive)
    final cleanedBairro = endereco.bairro.trim().toLowerCase();
    if (cleanedBairro.isNotEmpty) {
      for (final rule in activeTaxas.where((t) => t.tipoRegra == TipoRegraTaxaEntrega.bairro)) {
        final ruleBairro = rule.bairro?.trim().toLowerCase() ?? '';
        if (ruleBairro.isNotEmpty && cleanedBairro == ruleBairro) {
          return rule;
        }
      }
    }

    // 3. Regra Taxa Fixa (geral)
    final fixedRule = activeTaxas.cast<TaxaEntrega?>().firstWhere(
          (t) => t?.tipoRegra == TipoRegraTaxaEntrega.fixo,
          orElse: () => null,
        );
    if (fixedRule != null) {
      return fixedRule;
    }

    return null;
  }

  /// Cadastra uma nova regra de taxa de entrega dinamicamente
  Future<bool> cadastrarTaxaContextual({
    required String nome,
    required TipoRegraTaxaEntrega tipoRegra,
    String? bairro,
    String? cepInicial,
    String? cepFinal,
    required int valorCentavos,
  }) async {
    return salvarTaxaEntrega(
      original: null,
      nome: nome,
      tipoRegra: tipoRegra,
      bairro: bairro,
      cepInicial: cepInicial,
      cepFinal: cepFinal,
      valorCentavos: valorCentavos,
      ativo: true,
      pedidoMinimoCentavos: 0,
    );
  }

  /// Salva (cria ou atualiza) uma regra de taxa de entrega (Região de Entrega)
  Future<bool> salvarTaxaEntrega({
    required TaxaEntrega? original,
    required String nome,
    required TipoRegraTaxaEntrega tipoRegra,
    String? bairro,
    String? cepInicial,
    String? cepFinal,
    required int valorCentavos,
    required bool ativo,
    required int pedidoMinimoCentavos,
    String? prazoEstimado,
    String? observacoes,
  }) async {
    if (nome.trim().isEmpty) return false;

    _isSaving = true;
    notifyListeners();

    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final isNew = original == null;
      final id = isNew ? const Uuid().v4() : original.id;

      final rule = TaxaEntrega(
        id: id,
        tenantId: tenantCtx.tenantId,
        nome: nome.trim(),
        tipoRegra: tipoRegra,
        bairro: bairro?.trim().isEmpty == true ? null : bairro?.trim(),
        cepInicial: cepInicial?.trim().isEmpty == true ? null : cepInicial?.trim(),
        cepFinal: cepFinal?.trim().isEmpty == true ? null : cepFinal?.trim(),
        valorCentavos: valorCentavos,
        ativo: ativo,
        pedidoMinimoCentavos: pedidoMinimoCentavos,
        prazoEstimado: prazoEstimado?.trim().isEmpty == true ? null : prazoEstimado?.trim(),
        observacoes: observacoes?.trim().isEmpty == true ? null : observacoes?.trim(),
        metadata: SyncMetadata(
          version: isNew ? 1 : original.metadata.version + 1,
          createdAt: isNew ? DateTime.now().toUtc() : original.metadata.createdAt,
          updatedAt: DateTime.now().toUtc(),
          createdBy: isNew ? tenantCtx.usuario.id : original.metadata.createdBy,
          updatedBy: tenantCtx.usuario.id,
          syncStatus: SyncStatus.pending,
        ),
      );

      await _taxaRepo.save(rule);

      // Registrar auditoria
      try {
        final auditLogRepo = DependencyInjection().get<AuditLogRepository>();
        final currentUserId = tenantCtx.hasContext ? tenantCtx.usuario.id : 'system';
        await auditLogRepo.log(
          entityName: 'taxas_entrega',
          entityId: rule.id,
          userId: currentUserId,
          action: isNew ? 'CREATE' : 'UPDATE',
          entityDisplayName: rule.nome,
          entityModule: 'Cadastros',
          diff: {
            'nome': rule.nome,
            'tipoRegra': rule.tipoRegra.name,
            'bairro': rule.bairro,
            'cepInicial': rule.cepInicial,
            'cepFinal': rule.cepFinal,
            'valorCentavos': rule.valorCentavos,
            'ativo': rule.ativo,
            'pedidoMinimoCentavos': rule.pedidoMinimoCentavos,
            'prazoEstimado': rule.prazoEstimado,
            'observacoes': rule.observacoes,
          },
        );
      } catch (logErr) {
        debugPrint('Erro ao salvar log de auditoria de taxa: $logErr');
      }

      _taxas = await _taxaRepo.findAll();
      _applyFilters();
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar taxa de entrega: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Exclui (logicamente) uma regra de taxa de entrega (Região de Entrega)
  Future<bool> excluirTaxaEntrega(String id) async {
    final rule = _taxas.cast<TaxaEntrega?>().firstWhere((t) => t?.id == id, orElse: () => null);
    if (rule == null) return false;

    _isSaving = true;
    notifyListeners();

    try {
      await _taxaRepo.delete(id);

      // Registrar auditoria
      try {
        final tenantCtx = DependencyInjection().get<TenantContext>();
        final auditLogRepo = DependencyInjection().get<AuditLogRepository>();
        final currentUserId = tenantCtx.hasContext ? tenantCtx.usuario.id : 'system';
        await auditLogRepo.log(
          entityName: 'taxas_entrega',
          entityId: id,
          userId: currentUserId,
          action: 'DELETE',
          entityDisplayName: rule.nome,
          entityModule: 'Cadastros',
          diff: {'deleted': true},
        );
      } catch (logErr) {
        debugPrint('Erro ao salvar log de auditoria de exclusão de taxa: $logErr');
      }

      _taxas = await _taxaRepo.findAll();
      _applyFilters();
      return true;
    } catch (e) {
      debugPrint('Erro ao excluir taxa de entrega: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ─── Helpers privados ──────────────────────────────────────────────────────

  bool _isConsumidorFinal(Cliente? client) {
    if (client == null) return false;
    final nome = client.nome.toLowerCase();
    return nome.contains('consumidor final') ||
        nome.contains('cliente consumidor') ||
        client.telefone == '00000000000' ||
        client.observacoes.toLowerCase().contains('imutável');
  }

  void _applyFilters() {
    var filtered = _clientes;

    // Busca por termo de pesquisa
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        return c.nome.toLowerCase().contains(q) ||
            (c.apelido?.toLowerCase().contains(q) ?? false) ||
            c.telefone.contains(q) ||
            (c.email?.toLowerCase().contains(q) ?? false) ||
            (c.documento?.contains(q) ?? false);
      }).toList();
    }

    // Filtro por status ativo/inativo
    if (_filtroStatus == 'Ativos') {
      filtered = filtered.where((c) => c.ativo).toList();
    } else if (_filtroStatus == 'Inativos') {
      filtered = filtered.where((c) => !c.ativo).toList();
    }

    _filteredClientes = filtered;
  }
}
