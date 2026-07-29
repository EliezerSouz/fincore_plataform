export 'src/theme/fincore_colors.dart';
export 'src/theme/fincore_theme.dart';
export 'src/theme/fincore_formatters.dart';

// Widgets Estruturais Legados (sidebar, topbar)
export 'src/widgets/fincore_stat_card.dart';
export 'src/widgets/fincore_shimmer_line.dart';
export 'src/widgets/fincore_sidebar.dart';
export 'src/widgets/fincore_topbar.dart';

// ─── Foundation Components ───────────────────────────────────────────────────

// Layout
export 'src/layout/layout_components.dart'
    show AppCard, AppSection, AppToolbar, AppToolbarAction, AppPage;

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
