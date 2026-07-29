import 'package:flutter/material.dart';
import '../theme/fincore_colors.dart';

class FincoreTopbar extends StatelessWidget {
  final String title;
  final String subtitle;
  final String activeTenantName;
  final List<String> availableTenants;
  final ValueChanged<String> onTenantChanged;
  final String userName;
  final String userRole;
  final bool isOnline;
  final VoidCallback? onLogout;

  const FincoreTopbar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.activeTenantName,
    required this.availableTenants,
    required this.onTenantChanged,
    required this.userName,
    required this.userRole,
    this.isOnline = true,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        // Ocultar info se a largura disponível for pequena (evita estouro no Layout)
        final showFullUser = maxWidth >= 620;
        final showFullConnection = maxWidth >= 480;

        return Container(
          height: 64,
          color: FincoreColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Título do Vertical / Módulo
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: FincoreColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: FincoreColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              // Ações e Identificação (Tenant, Conexão, Operador)
              Row(
                children: [
                  // Seletor de Tenant
                  _buildTenantSelector(context),
                  const SizedBox(width: 12),
                  
                  // Status de Conexão
                  _buildConnectionBadge(showFullConnection),
                  const SizedBox(width: 12),
                  
                  // Divisor vertical
                  if (showFullUser) ...[
                    Container(width: 1.5, height: 28, color: FincoreColors.border),
                    const SizedBox(width: 12),
                    
                    // Identificação do Operador
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: FincoreColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userRole.toUpperCase(),
                          style: const TextStyle(
                            color: FincoreColors.primary, // Laranja Forno
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                  ],
                  
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'logout' && onLogout != null) {
                        onLogout!();
                      }
                    },
                    itemBuilder: (context) => [
                      if (onLogout != null)
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: FincoreColors.danger, size: 18),
                              SizedBox(width: 8),
                              Text('Sair da Conta', style: TextStyle(color: FincoreColors.danger)),
                            ],
                          ),
                        ),
                    ],
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: FincoreColors.border,
                      child: Icon(Icons.person, color: FincoreColors.textSecondary, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTenantSelector(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onTenantChanged,
      itemBuilder: (context) {
        return availableTenants.map((tenant) {
          return PopupMenuItem<String>(
            value: tenant,
            child: Text(
              tenant,
              style: const TextStyle(fontSize: 13, color: FincoreColors.textPrimary),
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: FincoreColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: FincoreColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront, color: FincoreColors.primary, size: 16),
            const SizedBox(width: 8),
            Text(
              activeTenantName,
              style: const TextStyle(
                color: FincoreColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down, color: FincoreColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionBadge(bool showText) {
    final color = isOnline ? FincoreColors.success : FincoreColors.danger;
    final text = isOnline ? 'ONLINE' : 'OFFLINE';
    final icon = isOnline ? Icons.wifi : Icons.wifi_off;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: FincoreColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          if (showText) ...[
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
