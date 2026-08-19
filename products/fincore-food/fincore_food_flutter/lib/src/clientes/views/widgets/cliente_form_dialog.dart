import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/repository/cliente_repository.dart';
import 'package:fincore_core/repository/local_entrega_repository.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_text_field.dart';
import 'package:uuid/uuid.dart';

/// Modal Oficial de Cadastro / Edição de Cliente da FINCORE Platform.
/// Utilizado tanto na gestão de clientes quanto no PDV.
class ClienteFormDialog extends StatefulWidget {
  final Cliente? cliente;

  const ClienteFormDialog({
    super.key,
    this.cliente,
  });

  static Future<Cliente?> show(BuildContext context, {Cliente? cliente}) {
    return showDialog<Cliente>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ClienteFormDialog(cliente: cliente),
    );
  }

  @override
  State<ClienteFormDialog> createState() => _ClienteFormDialogState();
}

class _ClienteFormDialogState extends State<ClienteFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nomeCtrl = TextEditingController();
  final _apelidoCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _documentoCtrl = TextEditingController();
  final _preferenciaCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  // Endereço de Entrega Inicial
  final _logrCtrl = TextEditingController();
  final _numCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController(text: 'São Paulo');
  final _cepCtrl = TextEditingController();
  final _refCtrl = TextEditingController();

  bool _ativo = true;
  bool _aceitaWhatsapp = true;
  bool _aceitaMarketing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    if (c != null) {
      _nomeCtrl.text = c.nome;
      _apelidoCtrl.text = c.apelido ?? '';
      _telefoneCtrl.text = c.telefone;
      _emailCtrl.text = c.email ?? '';
      _documentoCtrl.text = c.documento ?? '';
      _preferenciaCtrl.text = c.preferenciaEntrega ?? '';
      _obsCtrl.text = c.observacoes;
      _ativo = c.ativo;
      _aceitaWhatsapp = c.aceitaWhatsapp;
      _aceitaMarketing = c.aceitaMarketing;
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _apelidoCtrl.dispose();
    _telefoneCtrl.dispose();
    _emailCtrl.dispose();
    _documentoCtrl.dispose();
    _preferenciaCtrl.dispose();
    _obsCtrl.dispose();
    _logrCtrl.dispose();
    _numCtrl.dispose();
    _bairroCtrl.dispose();
    _cidadeCtrl.dispose();
    _cepCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final clienteRepo = DependencyInjection().get<ClienteRepository>();
      final localRepo = DependencyInjection().get<LocalEntregaRepository>();

      final isNew = widget.cliente == null;
      final id = isNew ? const Uuid().v4() : widget.cliente!.id;

      final novoCliente = Cliente(
        id: id,
        tenantId: tenantCtx.tenantId,
        nome: _nomeCtrl.text.trim(),
        telefone: _telefoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        documento: _documentoCtrl.text.trim().isEmpty ? null : _documentoCtrl.text.trim(),
        observacoes: _obsCtrl.text.trim(),
        ativo: _ativo,
        apelido: _apelidoCtrl.text.trim().isEmpty ? null : _apelidoCtrl.text.trim(),
        aceitaWhatsapp: _aceitaWhatsapp,
        aceitaMarketing: _aceitaMarketing,
        preferenciaEntrega: _preferenciaCtrl.text.trim().isEmpty ? null : _preferenciaCtrl.text.trim(),
        metadata: widget.cliente?.metadata.copyWith(
              updatedAt: DateTime.now().toUtc(),
              syncStatus: SyncStatus.pending,
            ) ??
            SyncMetadata(
              version: 1,
              createdAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
              createdBy: tenantCtx.usuario.id,
              updatedBy: tenantCtx.usuario.id,
            ),
      );

      await clienteRepo.save(novoCliente);

      // Se informou endereço inicial no cadastro
      if (_logrCtrl.text.trim().isNotEmpty) {
        final novoLocal = LocalEntrega(
          id: const Uuid().v4(),
          tenantId: tenantCtx.tenantId,
          clienteId: id,
          nomeIdentificador: 'Principal',
          logradouro: _logrCtrl.text.trim(),
          numero: _numCtrl.text.trim(),
          bairro: _bairroCtrl.text.trim(),
          cidade: _cidadeCtrl.text.trim().isEmpty ? 'São Paulo' : _cidadeCtrl.text.trim(),
          cep: _cepCtrl.text.trim(),
          referencia: _refCtrl.text.trim(),
          ativo: true,
          metadata: SyncMetadata(
            version: 1,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
            createdBy: tenantCtx.usuario.id,
            updatedBy: tenantCtx.usuario.id,
          ),
        );
        await localRepo.save(novoLocal);
      }

      if (mounted) {
        Navigator.of(context).pop(novoCliente);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar cliente: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.cliente == null;

    return Dialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 650,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isNew ? Icons.person_add_outlined : Icons.edit_outlined,
                        color: FincoreColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isNew ? 'Cadastrar Novo Cliente' : 'Editar Cliente',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: FincoreColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: FincoreColors.textMuted),
                  ),
                ],
              ),
              const Divider(color: FincoreColors.border, height: 24),

              // Formulário com Scroll
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seção Dados Pessoais
                      Text(
                        'DADOS PESSOAIS',
                        style: TextStyle(
                          color: FincoreColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: FincoreTextField(
                              controller: _nomeCtrl,
                              hintText: 'Nome Completo *',
                              validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FincoreTextField(
                              controller: _apelidoCtrl,
                              hintText: 'Apelido / Nome Curto',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FincoreTextField(
                              controller: _telefoneCtrl,
                              hintText: 'Telefone *',
                              keyboardType: TextInputType.phone,
                              inputFormatters: FincoreFormatters.telefone,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Informe o telefone' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FincoreTextField(
                              controller: _emailCtrl,
                              hintText: 'E-mail (opcional)',
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FincoreTextField(
                              controller: _documentoCtrl,
                              hintText: 'CPF ou CNPJ (opcional)',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FincoreTextField(
                              controller: _preferenciaCtrl,
                              hintText: 'Preferência de Entrega',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Seção Endereço de Entrega Inicial
                      Text(
                        'ENDEREÇO DE ENTREGA (OPCIONAL)',
                        style: TextStyle(
                          color: FincoreColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: FincoreTextField(
                              controller: _logrCtrl,
                              hintText: 'Rua / Logradouro',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FincoreTextField(
                              controller: _numCtrl,
                              hintText: 'Número',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FincoreTextField(
                              controller: _bairroCtrl,
                              hintText: 'Bairro',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FincoreTextField(
                              controller: _cidadeCtrl,
                              hintText: 'Cidade',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FincoreTextField(
                              controller: _cepCtrl,
                              hintText: 'CEP',
                              inputFormatters: FincoreFormatters.cep,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FincoreTextField(
                        controller: _refCtrl,
                        hintText: 'Ponto de Referência (opcional)',
                      ),
                      const SizedBox(height: 20),

                      // Observações & Opções
                      Text(
                        'OBSERVAÇÕES & OPÇÕES',
                        style: TextStyle(
                          color: FincoreColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FincoreTextField(
                        controller: _obsCtrl,
                        hintText: 'Observações internas sobre o cliente...',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: _aceitaWhatsapp,
                            activeColor: FincoreColors.primary,
                            onChanged: (v) => setState(() => _aceitaWhatsapp = v ?? true),
                          ),
                          const Text('Aceita contato via WhatsApp', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 13)),
                          const SizedBox(width: 20),
                          Checkbox(
                            value: _ativo,
                            activeColor: FincoreColors.primary,
                            onChanged: (v) => setState(() => _ativo = v ?? true),
                          ),
                          const Text('Cliente Ativo', style: TextStyle(color: FincoreColors.textPrimary, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(color: FincoreColors.border, height: 24),

              // Rodapé com botões de ação
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FincoreColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(isNew ? 'Salvar Cliente' : 'Atualizar Cliente'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
