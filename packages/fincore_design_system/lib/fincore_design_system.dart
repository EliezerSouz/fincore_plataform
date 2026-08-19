// ─── Theme & Foundation ──────────────────────────────────────────────────────
export 'src/theme/fincore_colors.dart';
export 'src/theme/fincore_theme.dart';
export 'src/theme/theme_controller.dart';
export 'src/theme/fincore_formatters.dart';
export 'src/theme/fincore_animations.dart';
export 'src/theme/fincore_shadows.dart';
export 'src/theme/theme_scope.dart';
export 'src/theme/wcag_validator.dart';

// Foundation Tokens
export 'src/foundation/colors.dart';
export 'src/foundation/spacing.dart';
export 'src/foundation/radius.dart';
export 'src/foundation/shadows.dart';
export 'src/foundation/motion.dart';

// Semantic and Component Design Tokens
export 'src/tokens/theme_tokens.dart';
export 'src/tokens/interaction_tokens.dart';
export 'src/tokens/component_tokens.dart';
export 'src/tokens/light_tokens.dart';
export 'src/tokens/dark_tokens.dart';

// Widgets Estruturais Legados (sidebar, topbar)
export 'src/widgets/fincore_stat_card.dart';
export 'src/widgets/fincore_shimmer_line.dart';
export 'src/widgets/fincore_sidebar.dart';
export 'src/widgets/fincore_topbar.dart';
export 'src/widgets/audit_diff_table.dart';
export 'src/widgets/sync_health_card.dart';

// ─── Foundation Components ───────────────────────────────────────────────────

// Layout
export 'src/layout/layout_components.dart'
    show AppCard, AppSection, AppToolbar, AppToolbarAction, AppPage;
export 'src/layout/crud_header.dart' show CrudHeader;
export 'src/layout/crud_split_view.dart' show CrudSplitView;
export 'src/layout/fincore_inspector_panel.dart' show FincoreInspectorPanel;
export 'src/layout/crud_workspace.dart' show CrudWorkspace;

// Forms
export 'src/forms/form_components.dart'
    show
        PhoneField,
        CpfCnpjField,
        MoneyField,
        PostalCodeField,
        SearchField,
        QuantityField,
        TextAreaField;

// Feedback
export 'src/feedback/feedback_components.dart'
    show
        AppEmptyState,
        AppLoading,
        AppErrorState,
        AppStatusBadge,
        AppInfoTile;

// Data / Dashboard
export 'src/data/data_components.dart'
    show AppMetricCard, AppDashboardCard, MetricTrend;

// Patterns
export 'src/patterns/app_workspace_page.dart'
    show AppWorkspacePage;
