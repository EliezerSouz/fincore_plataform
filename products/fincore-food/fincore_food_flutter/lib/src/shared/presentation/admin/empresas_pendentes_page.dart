import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_food_flutter/main.dart';

class EmpresasPendentesPage extends StatefulWidget {
  final VoidCallback onLogout;
  const EmpresasPendentesPage({super.key, required this.onLogout});

  @override
  State<EmpresasPendentesPage> createState() => _EmpresasPendentesPageState();
}

class _EmpresasPendentesPageState extends State<EmpresasPendentesPage> {
  List<String> _pendingList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendientes();
  }

  Future<void> _loadPendientes() async {
    try {
      final list = await client.admin.empresasPendentes();
      setState(() {
        _pendingList = list;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao buscar pendentes: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _ativarEmpresa(String item) async {
    final parts = item.split(' - ');
    if (parts.isEmpty) return;
    final tenantId = parts[0];

    setState(() => _isLoading = true);
    try {
      final success = await client.admin.ativarEmpresa(tenantId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Empresa $tenantId ativada com sucesso!'),
            backgroundColor: FincoreColors.success,
          ),
        );
        _loadPendientes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao ativar empresa.'),
            backgroundColor: FincoreColors.danger,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao ativar: $e'),
          backgroundColor: FincoreColors.danger,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FincoreColors.background,
      appBar: AppBar(
        title: const Text('PAINEL SUPERADMIN - ATIVAÇÃO DE EMPRESAS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
        backgroundColor: FincoreColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: FincoreColors.textPrimary),
            onPressed: _loadPendientes,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: FincoreColors.danger),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 64, color: FincoreColors.success),
                      const SizedBox(height: 16),
                      const Text(
                        'Nenhuma empresa pendente de ativação!',
                        style: TextStyle(color: FincoreColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _pendingList.length,
                  itemBuilder: (context, index) {
                    final item = _pendingList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: FincoreColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FincoreColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item,
                                  style: const TextStyle(
                                    color: FincoreColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Status: PENDENTE DE ATIVAÇÃO',
                                  style: TextStyle(color: FincoreColors.warning, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _ativarEmpresa(item),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FincoreColors.success,
                            ),
                            child: const Text('ATIVAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
