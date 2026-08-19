import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/repository/empresa_configuracao_repository.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'fincore_colors.dart';
import 'wcag_validator.dart';
import '../tokens/theme_tokens.dart';
import '../tokens/light_tokens.dart';
import '../tokens/dark_tokens.dart';

/// Modelo imutável das configurações do tema e marca da empresa.
class ThemeSettings {
  final ThemeMode themeMode;
  final String brandColorHex;
  final double borderRadius;
  final String density;
  final String logoUrl;
  final String empresaNome;

  const ThemeSettings({
    this.themeMode = ThemeMode.dark,
    this.brandColorHex = '#F97316',
    this.borderRadius = 8.0,
    this.density = 'Normal',
    this.logoUrl = '',
    this.empresaNome = 'FINCORE FOOD ERP',
  });

  Color get brandColor {
    final clean = brandColorHex.replaceAll('#', '');
    final val = int.tryParse('0xFF$clean') ?? 0xFFF97316;
    return Color(val);
  }

  ThemeSettings copyWith({
    ThemeMode? themeMode,
    String? brandColorHex,
    double? borderRadius,
    String? density,
    String? logoUrl,
    String? empresaNome,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      brandColorHex: brandColorHex ?? this.brandColorHex,
      borderRadius: borderRadius ?? this.borderRadius,
      density: density ?? this.density,
      logoUrl: logoUrl ?? this.logoUrl,
      empresaNome: empresaNome ?? this.empresaNome,
    );
  }
}

/// Factory Responsável pela geração dinâmica do [ThemeData] (Claro e Escuro)
/// com base na cor primária da marca e no arredondamento de bordas.
class ThemeFactory {
  ThemeFactory._();

  static ThemeData build({
    required Brightness brightness,
    required ThemeSettings settings,
  }) {
    final isDark = brightness == Brightness.dark;
    final primaryColor = settings.brandColor;
    final ThemeTokens tokens = isDark ? DarkTokens(brandColor: primaryColor) : LightTokens(brandColor: primaryColor);

    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      primary: tokens.actionPrimary,
      secondary: tokens.info,
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
      error: tokens.danger,
    );

    final bg = tokens.background;
    final surface = tokens.surface;
    final textPrimary = tokens.textPrimary;
    final textSecondary = tokens.textSecondary;
    final borderColor = tokens.border;

    VisualDensity density;
    switch (settings.density.toLowerCase()) {
      case 'compacto':
        density = VisualDensity.compact;
        break;
      case 'confortável':
        density = VisualDensity.comfortable;
        break;
      default:
        density = VisualDensity.standard;
    }

    final radius = settings.borderRadius;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Inter',
      visualDensity: density,
      colorScheme: baseColorScheme,

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: borderColor),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.actionPrimary,
          foregroundColor: tokens.textOnAction,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: tokens.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: tokens.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: tokens.inputBorderFocused, width: 2),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.actionPrimary;
          return isDark ? const Color(0xFF2E2E38) : const Color(0xFFD1D5DB);
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.actionPrimary;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      dividerTheme: DividerThemeData(color: borderColor, space: 1),
    );
  }
}

/// Controller Central de Temas ([ThemeController]) — Padrão Singleton Observável
/// Carrega as configurações do SQLite e notifica o [MaterialApp] em tempo real.
class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._();

  ThemeController._();

  ThemeSettings _settings = const ThemeSettings();

  ThemeSettings get settings => _settings;
  ThemeMode get themeMode => _settings.themeMode;
  Color get primaryColor => _settings.brandColor;

  bool get isDark {
    if (themeMode == ThemeMode.light) return false;
    if (themeMode == ThemeMode.dark) return true;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  /// Retorna os tokens de tema ativos de acordo com o modo atual (Claro ou Escuro).
  ThemeTokens get tokens => isDark ? DarkTokens(brandColor: primaryColor) : LightTokens(brandColor: primaryColor);

  ThemeData get lightTheme => ThemeFactory.build(brightness: Brightness.light, settings: _settings);
  ThemeData get darkTheme => ThemeFactory.build(brightness: Brightness.dark, settings: _settings);

  /// Inicializa o controlador carregando as configurações persistidas no SharedPreferences e SQLite.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString('fincore_theme_mode');
      final brandColor = prefs.getString('fincore_brand_color');
      final radius = prefs.getDouble('fincore_border_radius');
      final density = prefs.getString('fincore_density');
      final empresaNome = prefs.getString('fincore_empresa_nome');

      if (brandColor != null || modeStr != null) {
        _settings = _settings.copyWith(
          themeMode: modeStr != null ? _parseThemeMode(modeStr) : null,
          brandColorHex: brandColor,
          borderRadius: radius,
          density: density,
          empresaNome: empresaNome,
        );
      }

      final repo = DependencyInjection().get<EmpresaConfiguracaoRepository>();
      final configs = await repo.findAll();
      if (configs.isNotEmpty) {
        final cfg = configs.first;
        final dbSettings = _parseTheme(cfg.tema, cfg.logoUrl);
        _settings = _settings.copyWith(
          themeMode: dbSettings.themeMode,
          brandColorHex: dbSettings.brandColorHex,
          borderRadius: dbSettings.borderRadius,
          density: dbSettings.density,
          empresaNome: dbSettings.empresaNome,
          logoUrl: dbSettings.logoUrl,
        );
      }
    } catch (_) {}
    notifyListeners();
  }

  /// Valida o contraste da cor hexadecimal fornecida em relação ao texto branco
  /// de acordo com as normas da WCAG (mínimo de 3.0:1 para elementos de botão grande/bold).
  bool validateContrast(String hexColor) {
    try {
      final clean = hexColor.replaceAll('#', '');
      final val = int.tryParse('0xFF$clean') ?? 0xFFF97316;
      return WcagValidator.isContrastAccessible(Color(val), Colors.white, threshold: 3.0);
    } catch (_) {
      return false;
    }
  }

  /// Atualiza o tema em memória, persiste no SharedPreferences e SQLite, e NOTIFICA toda a aplicação.
  Future<void> updateTheme({
    ThemeMode? mode,
    String? brandColorHex,
    double? radius,
    String? density,
    String? logoUrl,
    String? empresaNome,
  }) async {
    if (brandColorHex != null && !validateContrast(brandColorHex)) {
      debugPrint('Aviso: Cor de marca $brandColorHex rejeitada devido a falha no teste de contraste WCAG.');
      brandColorHex = _settings.brandColorHex; // Reverte para a cor anterior estável
    }

    _settings = _settings.copyWith(
      themeMode: mode,
      brandColorHex: brandColorHex,
      borderRadius: radius,
      density: density,
      logoUrl: logoUrl,
      empresaNome: empresaNome,
    );

    // Rebuild dinâmico do MaterialApp em tempo real
    notifyListeners();

    // 1. Persistência imediata no SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fincore_theme_mode', _settings.themeMode.name);
      await prefs.setString('fincore_brand_color', _settings.brandColorHex);
      await prefs.setDouble('fincore_border_radius', _settings.borderRadius);
      await prefs.setString('fincore_density', _settings.density);
      await prefs.setString('fincore_empresa_nome', _settings.empresaNome);
    } catch (_) {}

    // 2. Persistência em background no SQLite
    try {
      final repo = DependencyInjection().get<EmpresaConfiguracaoRepository>();
      final tenantCtx = DependencyInjection().get<TenantContext>();
      final targetTenantId = tenantCtx.hasContext ? tenantCtx.tenantId : '00000000-0000-4000-a000-000000000001';

      final configs = await repo.findAll();
      CoreEmpresaConfiguracao? currentConfig;
      if (configs.isNotEmpty) {
        currentConfig = configs.firstWhere((c) => c.tenantId == targetTenantId, orElse: () => configs.first);
      }

      final temaJson = jsonEncode({
        'themeMode': _settings.themeMode.name,
        'brandColorHex': _settings.brandColorHex,
        'borderRadius': _settings.borderRadius,
        'density': _settings.density,
        'empresaNome': _settings.empresaNome,
      });

      if (currentConfig != null) {
        final updated = CoreEmpresaConfiguracao(
          id: currentConfig.id,
          tenantId: currentConfig.tenantId,
          printerConfig: currentConfig.printerConfig,
          pixKey: currentConfig.pixKey,
          taxaServico: currentConfig.taxaServico,
          usarWhatsApp: currentConfig.usarWhatsApp,
          logoUrl: _settings.logoUrl,
          tema: temaJson,
          printerCaixa: currentConfig.printerCaixa,
          printerCozinha: currentConfig.printerCozinha,
          printerBalcao: currentConfig.printerBalcao,
          printerExpedicao: currentConfig.printerExpedicao,
          autoPrintCaixa: currentConfig.autoPrintCaixa,
          autoPrintCozinha: currentConfig.autoPrintCozinha,
          autoPrintBalcao: currentConfig.autoPrintBalcao,
          autoPrintExpedicao: currentConfig.autoPrintExpedicao,
          viasCliente: currentConfig.viasCliente,
          viasCozinha: currentConfig.viasCozinha,
          viasBalcao: currentConfig.viasBalcao,
          viasExpedicao: currentConfig.viasExpedicao,
          larguraPapel: currentConfig.larguraPapel,
          cortarPapel: currentConfig.cortarPapel,
          abrirGaveta: currentConfig.abrirGaveta,
          imprimirQRCode: currentConfig.imprimirQRCode,
          imprimirCopiaCola: currentConfig.imprimirCopiaCola,
          imprimirLogo: currentConfig.imprimirLogo,
          imprimirRodape: currentConfig.imprimirRodape,
          mensagemRodape: currentConfig.mensagemRodape,
          pixFavorecido: currentConfig.pixFavorecido,
          pixBanco: currentConfig.pixBanco,
          pixTipo: currentConfig.pixTipo,
          modoDeliveryAtivo: currentConfig.modoDeliveryAtivo,
          modoComandasAtivo: currentConfig.modoComandasAtivo,
          clienteObrigatorioVenda: currentConfig.clienteObrigatorioVenda,
          atendimentoPadrao: currentConfig.atendimentoPadrao,
          metadata: currentConfig.metadata.copyWith(
            updatedAt: DateTime.now().toUtc(),
            syncStatus: SyncStatus.pending,
          ),
        );
        await repo.save(updated);
      } else {
        final newConfig = CoreEmpresaConfiguracao(
          id: const Uuid().v4(),
          tenantId: targetTenantId,
          taxaServico: 10.0,
          usarWhatsApp: true,
          logoUrl: _settings.logoUrl,
          tema: temaJson,
          metadata: SyncMetadata(
            version: 1,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
            createdBy: 'system',
            updatedBy: 'system',
            syncStatus: SyncStatus.pending,
          ),
        );
        await repo.save(newConfig);
      }
    } catch (_) {}
  }

  static ThemeSettings _parseTheme(String? val, String? logoUrl) {
    if (val != null && val.startsWith('{')) {
      try {
        final map = jsonDecode(val) as Map<String, dynamic>;
        return ThemeSettings(
          themeMode: _parseThemeMode(map['themeMode'] as String?),
          brandColorHex: (map['brandColorHex'] as String?) ?? '#F97316',
          borderRadius: (map['borderRadius'] as num?)?.toDouble() ?? 8.0,
          density: (map['density'] as String?) ?? 'Normal',
          logoUrl: logoUrl ?? '',
          empresaNome: (map['empresaNome'] as String?) ?? 'FINCORE FOOD ERP',
        );
      } catch (_) {}
    }
    return ThemeSettings(
      themeMode: _parseThemeMode(val),
      logoUrl: logoUrl ?? '',
    );
  }

  static ThemeMode _parseThemeMode(String? val) {
    switch (val) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }
}



