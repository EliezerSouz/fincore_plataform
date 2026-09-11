import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import '../controllers/dashboard_controller.dart';

class DashboardPersonalizarModal extends StatefulWidget {
  final DashboardController controller;

  const DashboardPersonalizarModal({super.key, required this.controller});

  @override
  State<DashboardPersonalizarModal> createState() => _DashboardPersonalizarModalState();
}

class _DashboardPersonalizarModalState extends State<DashboardPersonalizarModal> {
  // Todos os módulos disponíveis
  final List<String> _todosModulos = [
    'Operação Agora',
    'Atividades Recentes',
    'Estoque',
    'Produção',
    'Entregas Futuras',
    'Vendas',
    'Produtos Mais Vendidos',
    'Próximos Dias',
    'Recomendações',
  ];

  late List<String> _modulosAtivos;
  late List<String> _modulosDesativados;

  @override
  void initState() {
    super.initState();
    // Clona o estado atual do controller
    _modulosAtivos = List.from(widget.controller.enabledModules);
    _modulosDesativados = _todosModulos.where((m) => !_modulosAtivos.contains(m)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FincoreColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.tune_rounded, color: FincoreColors.primary, size: 22),
          const SizedBox(width: 8),
          const Text(
            'Personalizar Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Arraste para reordenar a ordem de exibição dos blocos ativos ou desative os que não deseja visualizar.',
                style: TextStyle(color: FincoreColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text(
                'MÓDULOS ATIVOS (ARRASte para reordenar)',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: FincoreColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                height: 250,
                child: _modulosAtivos.isEmpty
                    ? const Center(child: Text('Nenhum módulo ativo.', style: TextStyle(color: FincoreColors.textMuted, fontSize: 12)))
                    : ReorderableListView(
                        shrinkWrap: true,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final item = _modulosAtivos.removeAt(oldIndex);
                            _modulosAtivos.insert(newIndex, item);
                          });
                        },
                        children: [
                          for (int idx = 0; idx < _modulosAtivos.length; idx++)
                            ListTile(
                              key: ValueKey(_modulosAtivos[idx]),
                              title: Text(
                                _modulosAtivos[idx],
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                              ),
                              leading: const Icon(Icons.drag_indicator_rounded, color: FincoreColors.textMuted, size: 20),
                              trailing: _isEssencial(_modulosAtivos[idx])
                                  ? const Tooltip(
                                      message: 'Módulo essencial para a operação',
                                      decoration: BoxDecoration(
                                        color: FincoreColors.surfaceOverlay,
                                      ),
                                      textStyle: TextStyle(color: FincoreColors.textPrimary, fontSize: 11),
                                      child: Icon(Icons.lock_outline_rounded, color: FincoreColors.textMuted, size: 20),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFE05C5C), size: 20),
                                      onPressed: () {
                                        setState(() {
                                          final item = _modulosAtivos.removeAt(idx);
                                          _modulosDesativados.add(item);
                                        });
                                      },
                                    ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 18),
              const Text(
                'MÓDULOS DISPONÍVEIS (CLIQUE PARA ATIVAR)',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              _modulosDesativados.isEmpty
                  ? const Text('Todos os módulos estão ativos.', style: TextStyle(color: FincoreColors.textMuted, fontSize: 11))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _modulosDesativados.map((m) {
                        return ActionChip(
                          avatar: const Icon(Icons.add_rounded, size: 14, color: FincoreColors.textSecondary),
                          label: Text(m, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          backgroundColor: FincoreColors.surfaceOverlay,
                          side: const BorderSide(color: FincoreColors.border),
                          onPressed: () {
                            setState(() {
                              _modulosDesativados.remove(m);
                              _modulosAtivos.add(m);
                            });
                          },
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () async {
            await widget.controller.saveModulePreferences(_modulosAtivos);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: FincoreColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Salvar Alterações'),
        ),
      ],
    );
  }

  bool _isEssencial(String modulo) {
    return modulo == 'Operação Agora' ||
        modulo == 'Produção' ||
        modulo == 'Entregas Futuras';
  }
}
