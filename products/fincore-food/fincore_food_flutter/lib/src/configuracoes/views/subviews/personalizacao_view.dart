import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_text_field.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/fincore_section_card.dart';
import 'package:fincore_food_flutter/src/shared/presentation/widgets/category_badge.dart';

/// Módulo de Personalização & Aparência White-Label (ThemeManager & Live Preview)
/// Módulo de Personalização & Aparência White-Label (ThemeManager & Live Preview)
class PersonalizacaoView extends StatefulWidget {
  final VoidCallback? onChanged;

  const PersonalizacaoView({
    super.key,
    this.onChanged,
  });

  @override
  State<PersonalizacaoView> createState() => PersonalizacaoViewState();
}

class PersonalizacaoViewState extends State<PersonalizacaoView> {
  ThemeMode _selectedThemeMode = ThemeMode.dark;
  String _selectedBrandColorHex = '#F97316';
  String _selectedDensity = 'Normal';
  double _selectedRadius = 8.0;
  bool _enableAnimations = true;

  // White-Label Controllers
  final _empresaNomeCtrl = TextEditingController(text: 'FINCORE FOOD ERP');
  final _logoUrlCtrl = TextEditingController(text: 'https://cdn.fincore.app/brand/logo.png');
  final _sidebarLogoUrlCtrl = TextEditingController(text: 'https://cdn.fincore.app/brand/logo_icon.png');

  bool _isSaving = false;

  final List<Map<String, String>> _coresPrimarias = const [
    {'name': 'Laranja Fincore', 'hex': '#F97316'},
    {'name': 'Azul Elétrico', 'hex': '#2563EB'},
    {'name': 'Verde Sucesso', 'hex': '#10B981'},
    {'name': 'Roxo Nobre', 'hex': '#A855F7'},
    {'name': 'Cinza Grafite', 'hex': '#4B5563'},
    {'name': 'Vermelho Carmim', 'hex': '#EF4444'},
  ];

  @override
  void initState() {
    super.initState();
    final settings = ThemeController.instance.settings;
    _selectedThemeMode = settings.themeMode;
    _selectedBrandColorHex = settings.brandColorHex;
    _selectedRadius = settings.borderRadius;
    _selectedDensity = settings.density;
    _empresaNomeCtrl.text = settings.empresaNome;

    _empresaNomeCtrl.addListener(() => widget.onChanged?.call());
    _logoUrlCtrl.addListener(() => widget.onChanged?.call());
    _sidebarLogoUrlCtrl.addListener(() => widget.onChanged?.call());
  }

  @override
  void dispose() {
    _empresaNomeCtrl.dispose();
    _logoUrlCtrl.dispose();
    _sidebarLogoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    setState(() => _isSaving = true);
    await ThemeController.instance.updateTheme(
      mode: _selectedThemeMode,
      brandColorHex: _selectedBrandColorHex,
      radius: _selectedRadius,
      density: _selectedDensity,
      empresaNome: _empresaNomeCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aparência salva! Toda a aplicação foi atualizada com sucesso.'),
        backgroundColor: FincoreColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = Color(int.parse(_selectedBrandColorHex.replaceFirst('#', '0xFF')));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Painel de Configurações
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 1: Tema da Interface
                    FincoreSectionCard(
                      title: 'Tema da Aplicação',
                      subtitle: 'Selecione a tonalidade visual do sistema',
                      icon: Icons.palette_outlined,
                      child: Row(
                        children: [
                          _buildThemeTile('Sistema', Icons.brightness_auto, ThemeMode.system),
                          const SizedBox(width: 12),
                          _buildThemeTile('Claro', Icons.light_mode_outlined, ThemeMode.light),
                          const SizedBox(width: 12),
                          _buildThemeTile('Escuro', Icons.dark_mode_outlined, ThemeMode.dark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 2: Cor Primária da Marca (Branding)
                    FincoreSectionCard(
                      title: 'Cor Primária da Marca (Branding)',
                      subtitle: 'Cor principal dos botões, destaques e identidades visuais',
                      icon: Icons.color_lens_outlined,
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _coresPrimarias.map((c) {
                          final isSel = _selectedBrandColorHex == c['hex'];
                          final colorVal = Color(int.parse(c['hex']!.replaceFirst('#', '0xFF')));

                          return InkWell(
                            onTap: () {
                              setState(() => _selectedBrandColorHex = c['hex']!);
                              widget.onChanged?.call();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel ? colorVal.withValues(alpha: 0.15) : FincoreColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSel ? colorVal : FincoreColors.border, width: isSel ? 2 : 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(color: colorVal, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    c['name']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                      color: isSel ? colorVal : FincoreColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 3: Densidade & Bordas
                    FincoreSectionCard(
                      title: 'Layout & Acessibilidade',
                      subtitle: 'Densidade da interface, arredondamento de bordas e animações',
                      icon: Icons.aspect_ratio_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FincoreFieldLabel(label: 'DENSIDADE DA INTERFACE'),
                          Row(
                            children: [
                              _buildDensityChip('Compacto (Notebook 13")'),
                              const SizedBox(width: 8),
                              _buildDensityChip('Normal'),
                              const SizedBox(width: 8),
                              _buildDensityChip('Confortável (Touch)'),
                            ],
                          ),
                          const SizedBox(height: 16),

                          const FincoreFieldLabel(label: 'ARREDONDAMENTO DE BORDAS (RADIUS)'),
                          Row(
                            children: [
                              _buildRadiusChip('Quadrado (4px)', 4.0),
                              const SizedBox(width: 8),
                              _buildRadiusChip('Médio (8px)', 8.0),
                              const SizedBox(width: 8),
                              _buildRadiusChip('Arredondado (14px)', 14.0),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 4: White-Label (Logos & Personalização)
                    FincoreSectionCard(
                      title: 'Personalização White-Label',
                      subtitle: 'Personalize o nome, logo e identidade para sua empresa ou franquia',
                      icon: Icons.workspace_premium_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FincoreFieldLabel(label: 'NOME DA PLATAFORMA / MARCA'),
                          FincoreTextField(controller: _empresaNomeCtrl, hintText: 'FINCORE FOOD ERP'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const FincoreFieldLabel(label: 'URL DA LOGO PRINCIPAL'),
                                    FincoreTextField(controller: _logoUrlCtrl, hintText: 'https://cdn.com/logo.png'),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const FincoreFieldLabel(label: 'URL DA LOGO DA SIDEBAR'),
                                    FincoreTextField(controller: _sidebarLogoUrlCtrl, hintText: 'https://cdn.com/icon.png'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Painel de Live Preview Interativo em Tempo Real
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FincoreColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FincoreColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.remove_red_eye_outlined, color: FincoreColors.primary, size: 18),
                          const SizedBox(width: 8),
                          const Text('Preview em Tempo Real', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Visualização da interface adaptada ao tema e cor selecionada', style: TextStyle(fontSize: 11, color: FincoreColors.textMuted)),
                      const SizedBox(height: 16),

                      // Simulação da Interface
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedThemeMode == ThemeMode.light ? const Color(0xFFF3F4F6) : FincoreColors.background,
                          borderRadius: BorderRadius.circular(_selectedRadius),
                          border: Border.all(color: FincoreColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // TopBar Simulada
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: activeColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                  child: Image.asset(
                                  'assets/images/app_launcher_icon.png',
                                  width: 18,
                                  height: 18,
                                  fit: BoxFit.contain,
                                ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _empresaNomeCtrl.text,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedThemeMode == ThemeMode.light ? Colors.black87 : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16, color: FincoreColors.border),

                            // Exemplo de Badges Semânticos com Categoria
                            const Text('CATEGORIAS DO SISTEMA:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FincoreColors.textMuted)),
                            const SizedBox(height: 8),
                            const Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                CategoryBadge(label: 'Mini Salgados', colorToken: 'orange', icon: Icons.fastfood_outlined, isCompact: true),
                                CategoryBadge(label: 'Bebidas', colorToken: 'blue', icon: Icons.local_bar_outlined, isCompact: true),
                                CategoryBadge(label: 'Doces', colorToken: 'green', icon: Icons.icecream_outlined, isCompact: true),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Botão Simulado com Cor da Marca
                            ElevatedButton.icon(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: activeColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_selectedRadius)),
                              ),
                              icon: const Icon(Icons.check, size: 14, color: Colors.white),
                              label: const Text('Botão de Ação', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Card Informativo do Botão Único de Salvamento
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: activeColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 18, color: activeColor),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Pré-visualização ativa. Clique no botão "Salvar Alterações" no rodapé para aplicar em toda a plataforma.',
                                style: TextStyle(fontSize: 11, color: FincoreColors.textSecondary, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile(String label, IconData icon, ThemeMode mode) {
    final isSel = _selectedThemeMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedThemeMode = mode);
          ThemeController.instance.updateTheme(mode: mode);
          widget.onChanged?.call();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSel ? FincoreColors.primary.withValues(alpha: 0.15) : FincoreColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSel ? FincoreColors.primary : FincoreColors.border, width: isSel ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSel ? FincoreColors.primary : FincoreColors.textMuted, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? FincoreColors.primary : FincoreColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDensityChip(String label) {
    final cleanDensity = label.split(' ').first;
    final isSel = _selectedDensity == cleanDensity;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : FincoreColors.textSecondary)),
      selected: isSel,
      selectedColor: FincoreColors.primary,
      backgroundColor: FincoreColors.background,
      onSelected: (_) {
        setState(() => _selectedDensity = cleanDensity);
        widget.onChanged?.call();
      },
    );
  }

  Widget _buildRadiusChip(String label, double radius) {
    final isSel = _selectedRadius == radius;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : FincoreColors.textSecondary)),
      selected: isSel,
      selectedColor: FincoreColors.primary,
      backgroundColor: FincoreColors.background,
      onSelected: (_) {
        setState(() => _selectedRadius = radius);
        widget.onChanged?.call();
      },
    );
  }
}
