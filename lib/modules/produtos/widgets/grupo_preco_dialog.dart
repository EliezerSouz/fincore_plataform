import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/grupo_preco_repository.dart';
import '../../../design_system/colors.dart';
import '../../../design_system/components/app_button.dart';
import '../../../design_system/components/app_card.dart';
import '../../../design_system/components/app_dialog.dart';
import '../../../design_system/components/app_text_field.dart';
import '../../../design_system/icons.dart';
import '../../../design_system/spacing.dart';
import '../../../design_system/typography.dart';
import '../../../database/app_database.dart';
import '../../../models/domain_models.dart';
import '../../../providers/app_view_model.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/widgets/app_snackbar.dart';

Future<void> exibirGrupoPrecoDialog(
  BuildContext context,
  AppViewModel vm, [
  GruposPrecoData? grupo,
]) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (d) => _GrupoPrecoDialog(vm: vm, grupo: grupo),
  );
}

class _GrupoPrecoDialog extends StatefulWidget {
  final AppViewModel vm;
  final GruposPrecoData? grupo;

  const _GrupoPrecoDialog({required this.vm, this.grupo});

  @override
  State<_GrupoPrecoDialog> createState() => _GrupoPrecoDialogState();
}

class _GrupoPrecoDialogState extends State<_GrupoPrecoDialog> {
  late final TextEditingController _nome;
  late final TextEditingController _descricao;
  List<FaixaInput> _faixas = [];
  String? _erro;
  String? _sucesso;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.grupo?.nome);
    _descricao = TextEditingController(text: widget.grupo?.descricao);
    _carregarFaixas();
  }

  Future<void> _carregarFaixas() async {
    if (widget.grupo == null) return;
    final f = await widget.vm.gruposPreco.faixas(widget.grupo!.id);
    if (!mounted) return;
    setState(() {
      _faixas = f
          .map((x) => FaixaInput(x.quantidadeMinima, x.quantidadeMaxima,
              x.valorUnitarioCentavos))
          .toList();
      _validarFaixasEmTempoReal();
    });
  }

  void _validarFaixasEmTempoReal() {
    _faixas.sort((a, b) => a.minima.compareTo(b.minima));
    try {
      if (_faixas.isNotEmpty) {
        GrupoPrecoRepository.validarFaixas(_faixas);
        _erro = null;
        _sucesso = 'Faixas validadas com sucesso!';
      } else {
        _erro = null;
        _sucesso = null;
      }
    } catch (e) {
      _sucesso = null;
      _erro = e.toString().replaceFirst('ValidationException: ', '');
    }
  }

  void _adicionarFaixa(FaixaInput faixa) {
    setState(() {
      _faixas.add(faixa);
      _validarFaixasEmTempoReal();
    });
  }

  void _editarFaixa(FaixaInput antiga, FaixaInput nova) {
    setState(() {
      final index = _faixas.indexOf(antiga);
      if (index >= 0) {
        _faixas[index] = nova;
        _validarFaixasEmTempoReal();
      }
    });
  }

  void _removerFaixa(FaixaInput faixa) {
    setState(() {
      _faixas.remove(faixa);
      _validarFaixasEmTempoReal();
    });
  }

  void _duplicarGrupo() {
    // Altera o nome levemente para não dar UNIQUE constraint direto
    setState(() {
      _nome.text = '${_nome.text} (Cópia)';
      // Ao salvar, passaremos ID = null na lógica, que insere um novo grupo
    });
  }

  Future<void> _salvar() async {
    final nomeTexto = _nome.text.trim();
    if (nomeTexto.isEmpty) {
      setState(() => _erro = 'Informe o nome do grupo.');
      return;
    }
    if (_faixas.isEmpty) {
      setState(() => _erro = 'Adicione ao menos uma faixa de preço.');
      return;
    }

    try {
      GrupoPrecoRepository.validarFaixas(_faixas);

      await widget.vm.gruposPreco.salvar(
        // Se duplicamos, não passamos o ID antigo (isso será feito fora se fosse botão dedicado, mas aqui vamos focar no form)
        // O Duplicar Grupo é melhor gerido se a UI disser que é uma inserção.
        id: _nome.text.endsWith('(Cópia)') ? null : widget.grupo?.id,
        nome: nomeTexto,
        descricao: _descricao.text.trim(),
        faixas: _faixas,
      );

      if (mounted) Navigator.pop(context);
      if (mounted) {
        AppSnackbar.sucesso(context, 'Grupo de preço salvo com sucesso!');
      }
    } catch (e) {
      var str = e.toString();
      if (str.contains('UNIQUE constraint failed')) {
        str = 'Já existe um grupo de preço com este nome ("$nomeTexto").';
      } else {
        str = str
            .replaceFirst('ValidationException: ', '')
            .replaceFirst('Invalid argument(s): ', '')
            .replaceFirst('Exception: ', '');
      }
      setState(() => _erro = str);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.grupo != null && !_nome.text.endsWith('(Cópia)');

    return AppDialog(
      icon: AppIcons.group,
      title: isEdit ? 'Editar grupo de preço' : 'Novo grupo de preço',
      description: 'Defina as faixas de quantidade e os preços unitários para este grupo.',
      onCancel: () => Navigator.pop(context),
      onSave: _erro == null ? _salvar : null,
      saveLabel: 'Salvar alterações',
      content: SizedBox(
        width: 800,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Campos Principais (Nome e Descrição) em um Card (ou Container com borda)
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Nome do grupo',
                        isRequired: true,
                        controller: _nome,
                        hint: 'Ex: Salgados',
                        prefixIcon: const Icon(AppIcons.category),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s16),
                    Expanded(
                      child: AppTextField(
                        label: 'Descrição (opcional)',
                        controller: _descricao,
                        hint: 'Ex: Preços especiais para salgados tradicionais',
                        prefixIcon: const Icon(Icons.description),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s24),

              // Seção de Faixas de Preço
              Container(
                padding: const EdgeInsets.all(AppSpacing.s24),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('Faixas de preço por quantidade total',
                                style: AppTypography.h3),
                            const SizedBox(width: AppSpacing.s8),
                            const Icon(Icons.info_outline,
                                size: 18, color: AppColors.textMuted),
                          ],
                        ),
                        AppButton(
                          label: 'Adicionar faixa',
                          icon: AppIcons.add,
                          onPressed: () async {
                            final f = await exibirFaixaDialog(context);
                            if (f != null) _adicionarFaixa(f);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s16),

                    // Alerta Laranja (Info)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: AppSpacing.s16),
                          Text(
                            'O preço será aplicado conforme a quantidade total do pedido.',
                            style: AppTypography.text
                                .copyWith(color: const Color(0xFF994400)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),

                    // Cabeçalho da Tabela
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                const Icon(Icons.bar_chart,
                                    size: 16, color: AppColors.textMuted),
                                const SizedBox(width: AppSpacing.s8),
                                Text('FAIXA DE QUANTIDADE',
                                    style: AppTypography.caption.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              children: [
                                const Icon(Icons.monetization_on_outlined,
                                    size: 16, color: AppColors.textMuted),
                                const SizedBox(width: AppSpacing.s8),
                                Text('PREÇO UNITÁRIO',
                                    style: AppTypography.caption.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Center(
                              child: Text('AÇÕES',
                                  style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textMuted)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Linhas
                    if (_faixas.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Nenhuma faixa adicionada.',
                            style: AppTypography.text
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      )
                    else
                      ..._faixas.map((f) {
                        final String subtitulo;
                        final String titulo;
                        if (f.minima == f.maxima) {
                          titulo = '${f.minima} até ${f.minima}';
                          subtitulo = 'Quantidade exata';
                        } else if (f.maxima == null) {
                          titulo = '${f.minima} ou mais';
                          subtitulo = '${f.minima} unidades ou mais';
                        } else {
                          titulo = '${f.minima} até ${f.maxima}';
                          subtitulo = 'De ${f.minima} até ${f.maxima} unidades';
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.s8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s16,
                              vertical: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      titulo,
                                      style: AppTypography.text.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitulo,
                                      style: AppTypography.caption.copyWith(
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text('R\$',
                                          style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 8),
                                      Text(
                                        dinheiro(f.valorCentavos)
                                            .replaceAll('R\$ ', ''),
                                        style: AppTypography.text.copyWith(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton.outlined(
                                      icon: const Icon(AppIcons.edit, size: 18),
                                      onPressed: () async {
                                        final nova = await exibirFaixaDialog(
                                            context, f);
                                        if (nova != null) {
                                          _editarFaixa(f, nova);
                                        }
                                      },
                                    ),
                                    const SizedBox(width: AppSpacing.s8),
                                    IconButton.outlined(
                                      style: IconButton.styleFrom(
                                        foregroundColor: AppColors.danger,
                                        side: const BorderSide(
                                            color: AppColors.danger),
                                      ),
                                      icon:
                                          const Icon(AppIcons.delete, size: 18),
                                      onPressed: () => _removerFaixa(f),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: AppSpacing.s16),

                    // Alertas da Validação (abaixo da tabela, como na imagem)
                    if (_erro != null)
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(AppIcons.error, color: AppColors.danger),
                            const SizedBox(width: AppSpacing.s8),
                            Expanded(
                              child: Text(
                                _erro!,
                                style: AppTypography.text.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_sucesso != null && _faixas.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: AppColors.success.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(AppIcons.check,
                                color: AppColors.success, size: 20),
                            const SizedBox(width: AppSpacing.s8),
                            Expanded(
                              child: Text(
                                'Faixas válidas e organizadas. O sistema aplicará automaticamente o menor preço válido para a quantidade informada.',
                                style: AppTypography.text.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<FaixaInput?> exibirFaixaDialog(BuildContext context,
    [FaixaInput? faixa]) {
  final min = TextEditingController(text: faixa?.minima.toString() ?? '');
  final max = TextEditingController(text: faixa?.maxima?.toString() ?? '');
  final valor = TextEditingController(
      text: faixa != null ? (faixa.valorCentavos / 100).toStringAsFixed(2) : '');

  return showDialog<FaixaInput>(
    context: context,
    builder: (d) => StatefulBuilder(
      builder: (_, set) {
        final minimaOk = (int.tryParse(min.text) ?? 0) >= 1;
        final valorParsed = double.tryParse(valor.text.replaceAll(',', '.'));
        final valorOk = valorParsed != null && valorParsed > 0;
        final maximaOk = max.text.isEmpty ||
            (int.tryParse(max.text) ?? 0) >= (int.tryParse(min.text) ?? 0);

        return AppDialog(
          title: faixa == null ? 'Adicionar Faixa' : 'Editar Faixa',
          content: SizedBox(
            width: 480,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Mínima',
                    isRequired: true,
                    controller: min,
                    onChanged: (_) => set(() {}),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: AppTextField(
                    label: 'Máxima',
                    controller: max,
                    onChanged: (_) => set(() {}),
                    helpText: 'Vazio = infinito',
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: AppTextField(
                    label: 'Preço Unt.',
                    isRequired: true,
                    controller: valor,
                    onChanged: (_) => set(() {}),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('R\$', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ),
          onCancel: () => Navigator.pop(d),
          onSave: minimaOk && valorOk && maximaOk
              ? () => Navigator.pop(
                    d,
                    FaixaInput(
                      int.parse(min.text),
                      max.text.isEmpty ? null : int.tryParse(max.text),
                      (valorParsed! * 100).round(),
                    ),
                  )
              : null,
          saveLabel: faixa == null ? 'Adicionar' : 'Salvar',
        );
      },
    ),
  );
}
