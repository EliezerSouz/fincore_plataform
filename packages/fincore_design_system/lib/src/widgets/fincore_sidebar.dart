import 'package:flutter/material.dart';
import '../theme/fincore_colors.dart';

class FincoreSidebarItem {
  final String label;
  final IconData icon;
  final String id;

  const FincoreSidebarItem({
    required this.label,
    required this.icon,
    required this.id,
  });
}

class FincoreSidebar extends StatelessWidget {
  final List<FincoreSidebarItem> items;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final bool isCollapsed;

  const FincoreSidebar({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelected,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCollapsed ? 72 : 240,
      height: double.infinity,
      color: FincoreColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo do FINCORE
          _buildLogo(),
          const Divider(color: FincoreColors.border, height: 1),
          const SizedBox(height: 16),
          
          // Lista de Items de Navegação
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item.id == selectedId;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: InkWell(
                    onTap: () => onSelected(item.id),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: EdgeInsets.symmetric(
                        horizontal: isCollapsed ? 0 : 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? FincoreColors.background : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: FincoreColors.primary, width: 1.5) // Foco Laranja Forno
                            : Border.all(color: Colors.transparent, width: 1.5),
                      ),
                      child: isCollapsed
                          ? Center(
                              child: Icon(
                                item.icon,
                                color: isSelected ? FincoreColors.primary : FincoreColors.textSecondary,
                              ),
                            )
                          : Row(
                              children: [
                                Icon(
                                  item.icon,
                                  color: isSelected ? FincoreColors.primary : FincoreColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      color: isSelected ? FincoreColors.textPrimary : FincoreColors.textSecondary,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Rodapé Neutro
          const Divider(color: FincoreColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: isCollapsed
                ? const Center(child: Icon(Icons.info_outline, color: FincoreColors.textMuted, size: 18))
                : const Row(
                    children: [
                      Icon(Icons.info_outline, color: FincoreColors.textMuted, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'v1.0.0 (v106)',
                        style: TextStyle(color: FincoreColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: isCollapsed
          ? Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: FincoreColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text(
                    'F',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            )
          : Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: FincoreColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text(
                      'F',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'FINCORE',
                  style: TextStyle(
                    color: FincoreColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
    );
  }
}
