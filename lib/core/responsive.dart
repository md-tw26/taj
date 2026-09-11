import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// ---------------------------------------------------------------------------
/// TAJ responsive architecture
/// ---------------------------------------------------------------------------
///
/// A single, reusable system the whole app shares so responsive logic is not
/// scattered across dozens of ad-hoc `MediaQuery` calls. The guiding principle
/// is **available space, not device type** — every decision keys off the width
/// (and sometimes height) actually available to the widget, so the same code
/// behaves correctly whether the app is a phone in portrait, a resized desktop
/// window, or an ultra-wide monitor.
///
/// Prefer [Breakpoint.fromWidth] with a `LayoutBuilder`'s `maxWidth` when a
/// widget lives inside a pane whose width differs from the screen (e.g. the POS
/// catalog next to a cart). Use the [BuildContext] getters when the widget
/// genuinely fills the screen.

/// Named width breakpoints (logical pixels). Ranges are half-open `[min, next)`.
///
/// * [phone]   `< 600`   — small/large phones, single column.
/// * [tablet]  `< 1024`  — tablets / narrow windows, 2-column, navigation rail.
/// * [laptop]  `< 1440`  — laptops, full sidebar, multi-column.
/// * [desktop] `< 1920`  — desktops, spacious multi-column.
/// * [ultrawide] `>= 1920` — 2K/4K/ultra-wide; content is capped and centered.
enum Breakpoint { phone, tablet, laptop, desktop, ultrawide }

class AppBreakpoints {
  const AppBreakpoints._();

  static const double phone = 600;
  static const double tablet = 1024;
  static const double laptop = 1440;
  static const double desktop = 1920;

  /// Width at or above which a screen has room to place two panes side by side
  /// (POS catalog + cart, dashboard summary columns) instead of stacking them.
  /// Keyed off *available* width, so it applies to resized desktop windows and
  /// split-screen just as well as to physical tablets.
  static const double splitPane = 820;

  /// Width at or above which the auth screen shows its branding panel beside
  /// the form; below it the form is centered full-width. Slightly wider than
  /// [splitPane] because the branding panel needs breathing room to look right.
  static const double authSplit = 900;

  /// Width at or above which a scrollable page can afford its roomier outer
  /// padding; below it padding tightens to keep the content width comfortable.
  static const double comfortablePadding = 700;

  /// Short-viewport threshold — below this the layout must not assume it can
  /// spend vertical space freely (e.g. 1366×768 in landscape, split windows).
  static const double shortHeight = 640;

  // ---------------------------------------------------------------------------
  // Expenses module thresholds
  // ---------------------------------------------------------------------------
  // Named so the Expenses screen never reaches for an inline magic number.
  // Every constant below is keyed off *available* width (a `LayoutBuilder`'s
  // `maxWidth`), not the physical device, so it holds for resized windows,
  // split-screen and the persistent side panel just as well as for phones.

  /// At or above this width the Expenses page switches from a slide-in form
  /// drawer to a persistent master-detail layout: the log/grid on the leading
  /// side and a fixed-width entry form panel on the trailing side. Equal to
  /// [laptop] — a full sidebar app at this width has room for both panes.
  static const double expenseSidePanel = laptop; // 1440

  /// Fixed width of that persistent entry-form panel. Comfortably below the
  /// 720px form cap and leaves the log pane wide enough to avoid a scroll.
  static const double expenseFormPanelWidth = 380;

  /// Width available to the entry form at or above which its short fields
  /// (amount, branch, method, …) pair up into two columns; below it every
  /// field is full width and single-column. Chosen so each paired column stays
  /// well above [expenseAmountMinWidth].
  static const double expenseFormTwoColumn = 460;

  /// The amount field is financial and must never be cramped: it is never
  /// laid out narrower than this in any configuration.
  static const double expenseAmountMinWidth = 140;

  /// Minimum extent of a ready-category card, fed to [gridColumnsFor] so the
  /// grid reflows from ~2 columns on a 320px phone up to 6 on a laptop instead
  /// of hardcoding a column count per breakpoint.
  static const double expenseCategoryMinWidth = 150;

  /// The Expenses page caps its content column a little wider than the shared
  /// [kContentMaxWidth] so the master-detail layout keeps breathing room on
  /// 4K/ultra-wide displays; beyond it the content centers with gutters rather
  /// than stretching edge to edge.
  static const double expenseContentMaxWidth = 1600;

  // ---------------------------------------------------------------------------
  // Treasury & Banks module thresholds
  // ---------------------------------------------------------------------------
  // Keyed off available width/height, never device type, so they hold for
  // resized windows and split panes as much as for physical devices.

  /// At or above this width the Treasury page becomes a master-detail layout:
  /// an account list pane on the leading side and the selected account's
  /// movements on the trailing side. Equal to [laptop].
  static const double treasurySplit = laptop; // 1440

  /// The Treasury page caps and centers its content beyond this width so the
  /// account pane and table never stretch edge to edge on 4K/ultra-wide.
  static const double treasuryContentMaxWidth = 1600;

  /// The master-detail account pane is flexible but clamped to this range so it
  /// never collapses to unreadable nor stretches on very wide displays.
  static const double treasuryAccountPaneMin = 280;
  static const double treasuryAccountPaneMax = 360;

  /// Minimum extent of a balance card, fed to [gridColumnsFor]; the grid runs
  /// 1 column on a phone (2 once past [treasuryTwoBalanceCols]) up to 3–4 wide.
  static const double treasuryBalanceCardMin = 280;

  /// Width at or above which a phone shows balance cards two-up instead of one.
  static const double treasuryTwoBalanceCols = 380;

  /// Transfer / movement dialog width caps per size class. The dialog never
  /// exceeds [treasuryDialogMax] however wide the screen, and its height is
  /// always 90% of the viewport with an internal scroll.
  static const double treasuryDialogNarrow = 560; // tablet
  static const double treasuryDialogMid = 640; // laptop
  static const double treasuryDialogMax = 720; // desktop and beyond

  /// Below this viewport height the balance summary strip condenses so it never
  /// eats more than ~30% of a 720p screen.
  static const double treasuryCondenseSummaryHeight = 760;

  // ---------------------------------------------------------------------------
  // Accounting module thresholds
  // ---------------------------------------------------------------------------

  /// Chart-of-accounts master-detail split. Below it the tree is a full page and
  /// tapping an account pushes a detail page; at/above it the tree sits beside
  /// the detail. Equal to [splitPane].
  static const double coaSplit = splitPane; // 820

  /// Entry-editor line layout. Below it each debit/credit line is a card; at or
  /// above it the lines become a table (account · description · debit · credit ·
  /// actions).
  static const double entryEditorTable = 720;

  /// At/above this width the accounting workspace can show three panes (tree +
  /// entry list + selected-entry preview); below it, two panes then one. Equal
  /// to [laptop]; also gated on [threePaneMinHeight] so short screens fall back.
  static const double threePane = laptop; // 1440

  /// The third accounting pane is only added when the viewport is at least this
  /// tall, so cramped landscape heights (e.g. 1366×768) drop to two panes
  /// instead of squeezing three. Equal to [shortHeight].
  static const double threePaneMinHeight = shortHeight; // 640

  /// The accounting workspace caps and centers its content beyond this width so
  /// the tree/list panes never stretch on 4K/ultra-wide; extra width goes to the
  /// content pane.
  static const double accountingContentMaxWidth = 1600;

  /// The chart-of-accounts tree pane is `clamp(min, 28% of width, max)` so it
  /// never collapses to unreadable nor stretches on very wide displays.
  static const double coaTreePaneMin = 240;
  static const double coaTreePaneMax = 360;

  // ---------------------------------------------------------------------------
  // Employees & Payroll module thresholds
  // ---------------------------------------------------------------------------

  /// At or above this width the employees list and the selected employee's
  /// profile show side by side (master-detail); below it selecting an employee
  /// opens the profile as a full page. Equal to [tablet].
  static const double employeeSplit = tablet; // 1024

  /// The employees page caps and centers its content beyond this width; the
  /// list pane is clamped so it never stretches, extra width goes to the profile.
  static const double employeeContentMaxWidth = 1600;

  /// The master-detail employee list pane is `clamp(min, ~30% of width, max)`.
  static const double employeeListPaneMin = 320;
  static const double employeeListPaneMax = 400;

  /// Add/edit-employee and pay-salary forms never exceed this width.
  static const double employeeFormMaxWidth = 900;

  // ---------------------------------------------------------------------------
  // Reports centre thresholds
  // ---------------------------------------------------------------------------
  // The reports centre shows an index of report cards and, when opened, wide
  // financial tables. Every threshold below keys off the *available* width or
  // height (a `LayoutBuilder`'s constraints), never the physical device, so it
  // holds for resized windows, split-screen and the persistent side rail just
  // as well as for phones — the reports pane lives inside the app content pane,
  // not the whole window.

  /// The reports centre caps and centres its content beyond this width so the
  /// rail + result never stretch edge-to-edge on 4K/ultra-wide; extra width
  /// becomes symmetric gutters. Within the spec's ~1600–1800 guidance and
  /// consistent with the sibling finance modules.
  static const double reportContentMaxWidth = 1600;

  /// At or above this width the reports centre becomes a master-detail layout:
  /// a persistent report side rail on the leading side and the selected
  /// report's result on the trailing side. Below it the index is a full page
  /// and picking a report opens its result as a pushed page (with a back
  /// affordance). Set inside the tablet→laptop band (not on a screen
  /// breakpoint) so a window resized 1280→…→500 crosses it and the side rail
  /// folds smoothly back into a full-width index page.
  static const double reportIndexRail = 1180;

  /// The report side rail is `clamp(min, ~24% of width, max)` so it never
  /// collapses to unreadable nor stretches on very wide displays.
  static const double reportRailMin = 260;
  static const double reportRailMax = 320;

  /// Minimum extent of a report index card, fed to [gridColumnsFor]; the grid
  /// runs 1 column on a small phone up to 3–4 on a laptop instead of hardcoding
  /// a column count per breakpoint.
  static const double reportCardMinWidth = 240;

  /// At or above this **result-pane** width (and when tall enough — see
  /// [reportInsightsMinHeight]) the result screen shows a persistent insights
  /// side panel (summary stat cards + an accompanying chart) beside the table.
  /// Below it the insights are reached through a segmented toggle in the result
  /// header so the table keeps the full width. Keyed off the pane, not the
  /// screen: at a 1440-screen the index rail + centred cap leave the result
  /// pane near ~1100px, so this sits below [laptop] on purpose.
  static const double reportInsightsPanel = 1080;

  /// Fixed width of that insights side panel — comfortably narrow so the table
  /// keeps the lion's share of the width, and bounded so a chart inside it gets
  /// a sensible (bounded) height from its [AspectRatio].
  static const double reportInsightsPanelWidth = 340;

  /// Below this available height the result screen drops the insights side
  /// panel and the summary strip so the scrollable table always keeps ≥60% of
  /// the height (e.g. 1280×720 and 1366×768 in landscape).
  static const double reportInsightsMinHeight = 760;

  /// Below this available height the result screen hides its summary stat strip
  /// (kept above the table on tall screens) so short viewports give the table
  /// the room instead.
  static const double reportSummaryMinHeight = 820;

  /// At or above this width the result screen shows a persistent filter bar;
  /// between [phone] and here filters render as a horizontal [Wrap]; below
  /// [phone] they move into a bottom sheet opened by a "filter" button that
  /// carries the active-filter count. Equal to [tablet].
  static const double reportFiltersPersistent = tablet; // 1024

  /// At or above this width the persistent filter controls are grouped
  /// (labelled clusters) rather than a flat row. Equal to [laptop].
  static const double reportFiltersGrouped = laptop; // 1440

  /// Export control density. At or above [reportExportButtons] the export
  /// actions are full-text buttons; between [reportExportIcons] and there they
  /// are icon buttons with tooltips; below [reportExportIcons] they collapse to
  /// a single button that opens a menu (PDF / Excel / Print).
  static const double reportExportButtons = tablet; // 1024
  static const double reportExportIcons = phone; // 600

  /// The date-range picker is full-width on a phone and a centered dialog no
  /// wider than this on tablet-and-up, always ≤90% of the viewport height with
  /// an internal scroll.
  static const double reportDateDialogMax = 560;

  /// Chart aspect ratios by size class — a chart is never given unbounded
  /// height; it is wrapped in an [AspectRatio] chosen from the space available
  /// to it (taller/squarer when narrow, wider on desktop).
  static const double reportChartAspectPhone = 4 / 3;
  static const double reportChartAspectWide = 16 / 9;

  /// Hierarchical reports (income statement / balance sheet) indent each level
  /// by `min(depth * reportIndentStep, reportMaxIndent)` so a deep tree never
  /// pushes the account name off its (frozen) column — the name then takes the
  /// remaining width with an [Expanded]/ellipsis.
  static const double reportIndentStep = 16;
  static const double reportMaxIndent = 48;

  // ---------------------------------------------------------------------------
  // Smart reports & analytics thresholds
  // ---------------------------------------------------------------------------
  // The analytics module is chart-heavy: charts need a concrete size while
  // everything around them is fluid. Every threshold below keys off the space
  // available to the widget (a chart card's own width/height via a
  // `LayoutBuilder`), never the device — so a chart behaves the same in a phone
  // column, a resized window, a grid cell or an ultra-wide monitor.

  /// The analytics centre caps and centres its content beyond this width so
  /// charts never stretch to unreadable widths (a 3000px-wide chart is useless);
  /// beyond it, the board adds *more* charts per row rather than widening one.
  static const double smartContentMaxWidth = 1600;

  /// Minimum extent of a ready-question card, fed to [gridColumnsFor]: 1 column
  /// on a small phone up to 3–4 on a laptop.
  static const double smartQuestionCardMin = 250;

  /// Minimum extent of a KPI/stat card in the answer board.
  static const double smartKpiCardMin = 180;

  /// Minimum extent of a chart card, fed to [gridColumnsFor]. At ~360 the board
  /// runs one chart on a phone, 2–3 on a laptop, and *more* (not wider) on 4K.
  static const double smartChartCardMin = 360;

  /// A chart card never grows wider than this, so a lone chart on a wide board
  /// stays readable (a 1600px-wide chart is useless) — extra room becomes
  /// margins/more columns, never a wider single chart.
  static const double smartChartCardMax = 640;

  /// A [ResponsiveChartCard] chooses its aspect ratio from its own width:
  ///  * `< chartAspectTall`  → [chartAspectPhone] (4/3, squarer — narrow cards),
  ///  * `< chartAspectWide`  → [chartAspectMid]   (3/2),
  ///  * otherwise            → [chartAspectWideR] (16/9, wide cards).
  static const double chartAspectTall = 380;
  static const double chartAspectWide = 640;
  static const double chartAspectPhone = 4 / 3;
  static const double chartAspectMid = 3 / 2;
  static const double chartAspectWideR = 16 / 9;

  /// Below this plotted height a chart would be distorted, so the card hides the
  /// plot and shows a numeric summary at this same height instead — the grid
  /// never jumps between a chart and its fallback.
  static const double chartMinHeight = 180;

  /// Below this *viewport* height (landscape phone, very short windows) a chart
  /// card caps its plot to the available height and moves its legend beside the
  /// chart to save vertical space.
  static const double chartShortViewport = 480;

  /// Minimum per-category slot for a bar (also the ≥44px tap target). When the
  /// categories don't fit, vertical bars scroll horizontally at this slot and
  /// long-name charts switch to grouped horizontal bars instead of squeezing.
  static const double chartBarMinSlot = 44;

  /// A legend wraps to at most this many lines before collapsing the remainder
  /// into a "+N" chip, so it can never push the chart out of its card.
  static const int chartLegendMaxLines = 2;

  /// On narrow charts, categories beyond this count collapse to
  /// "top (N-1) + أخرى" rather than being squeezed illegibly (a presentation
  /// change only — the underlying data is unchanged).
  static const int chartMaxCategories = 8;

  // ---------------------------------------------------------------------------
  // AI assistant (chat) thresholds
  // ---------------------------------------------------------------------------
  // A conversation is unreadable as a screen-wide strip, so it is always
  // centred and width-capped; everything else keys off the space available.

  /// The conversation column is capped and centred at this width from [tablet]
  /// up, so it never becomes a 3000px strip on an ultra-wide screen.
  static const double chatMaxWidth = 820;

  /// Between [phone] and [tablet] the conversation caps a little narrower for a
  /// comfortable reading measure.
  static const double chatWidthTablet = 720;

  /// A message bubble is `min(paneWidth * chatBubbleWidthFactor,
  /// chatBubbleMaxWidth)` — a percentage alone is huge on desktop, a fixed
  /// number alone is cramped on a phone, so both bound it.
  static const double chatBubbleMaxWidth = 680;
  static const double chatBubbleWidthFactor = 0.85;

  /// At or above this width the referenced chart/table from the latest answer
  /// moves to a side panel beside the (still-centred) conversation. Equal to
  /// [laptop].
  static const double assistantSidePanel = laptop; // 1440
  static const double assistantPanelMin = 360;
  static const double assistantPanelMax = 460;

  /// The composer grows to this many lines then scrolls internally; in the
  /// short/landscape-phone-with-keyboard state it is capped tighter so the last
  /// message and the input both stay visible.
  static const int chatInputMaxLines = 5;
  static const int chatInputMaxLinesCompact = 2;

  /// Minimum extent of a suggested-question card in the empty-state grid.
  static const double chatSuggestionCardMin = 240;

  /// Below this plotted height an in-bubble chart would be distorted, so it
  /// degrades to a numeric summary instead.
  static const double chatChartMinHeight = 160;

  /// At or below this available height the chat condenses: a slim header, the
  /// suggestion chips hide, and the composer caps at
  /// [chatInputMaxLinesCompact]. This is exactly the landscape-phone-with-open-
  /// keyboard worst case (the resizing scaffold shrinks the pane below it).
  static const double chatCompactHeight = 460;
}

/// The widest a centered content column is allowed to grow on large displays.
/// Beyond this we add symmetric gutters instead of stretching line lengths to
/// uncomfortable reading widths.
const double kContentMaxWidth = 1440;

/// A comfortable cap for single-column forms / auth cards / dialogs.
const double kFormMaxWidth = 480;

extension BreakpointX on Breakpoint {
  /// Classify a raw width into a [Breakpoint].
  static Breakpoint fromWidth(double width) {
    if (width < AppBreakpoints.phone) return Breakpoint.phone;
    if (width < AppBreakpoints.tablet) return Breakpoint.tablet;
    if (width < AppBreakpoints.laptop) return Breakpoint.laptop;
    if (width < AppBreakpoints.desktop) return Breakpoint.desktop;
    return Breakpoint.ultrawide;
  }

  bool get isPhone => this == Breakpoint.phone;
  bool get isTablet => this == Breakpoint.tablet;

  /// Phone-sized available space — use a single-column, touch-first layout.
  bool get isCompact => this == Breakpoint.phone;

  /// Tablet-and-up — enough room for two columns / a navigation rail.
  bool get isExpanded => index >= Breakpoint.tablet.index;

  /// Laptop-and-up — enough room for a persistent full sidebar / dense grids.
  bool get isWide => index >= Breakpoint.laptop.index;
}

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// The screen-level breakpoint. For widgets inside a narrower pane, prefer
  /// [Breakpoint.fromWidth] with a `LayoutBuilder`'s constraints instead.
  Breakpoint get breakpoint => BreakpointX.fromWidth(screenWidth);

  bool get isPhone => breakpoint.isPhone;
  bool get isTabletOrWider => breakpoint.isExpanded;
  bool get isDesktop => breakpoint.isWide;
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  /// True on short viewports where vertical space is scarce.
  bool get isShort => screenHeight < AppBreakpoints.shortHeight;

  /// Pick a value per screen breakpoint. Only [phone] is required; each larger
  /// tier falls back to the nearest smaller one that was supplied, so callers
  /// specify just the tiers they care about.
  T responsive<T>({
    required T phone,
    T? tablet,
    T? laptop,
    T? desktop,
    T? ultrawide,
  }) =>
      responsiveValue(
        breakpoint,
        phone: phone,
        tablet: tablet,
        laptop: laptop,
        desktop: desktop,
        ultrawide: ultrawide,
      );

  /// Content gutter that grows with the display: tighter on phones, roomier on
  /// desktops. Use for the outer padding of scrollable pages.
  double get pagePadding => responsive<double>(
        phone: 16,
        tablet: 20,
        laptop: 24,
        desktop: 24,
      );
}

/// Resolve a per-breakpoint value with smaller-tier fallback.
T responsiveValue<T>(
  Breakpoint bp, {
  required T phone,
  T? tablet,
  T? laptop,
  T? desktop,
  T? ultrawide,
}) {
  switch (bp) {
    case Breakpoint.ultrawide:
      return ultrawide ?? desktop ?? laptop ?? tablet ?? phone;
    case Breakpoint.desktop:
      return desktop ?? laptop ?? tablet ?? phone;
    case Breakpoint.laptop:
      return laptop ?? tablet ?? phone;
    case Breakpoint.tablet:
      return tablet ?? phone;
    case Breakpoint.phone:
      return phone;
  }
}

/// Clamp a side sheet / [Drawer] width so it never exceeds the viewport on
/// small screens. Desktop keeps the designed width; phones get a near-full
/// sheet that always leaves a scrim strip so the underlying screen is visible.
double drawerWidth(BuildContext context, {double desired = 440}) {
  final w = context.screenWidth;
  return math.min(desired, w * 0.92);
}

/// Outer padding for a scrollable page, chosen from the width actually
/// available to it (a `LayoutBuilder`'s `maxWidth`), not the whole screen — so
/// a page rendered inside the app's content pane pads to the pane, not to the
/// window. Roomier once past [AppBreakpoints.comfortablePadding], tighter below
/// so narrow panes keep a comfortable content width. This is the single source
/// the individual pages share instead of each repeating the same ternary.
double pagePaddingForWidth(double availableWidth) =>
    availableWidth >= AppBreakpoints.comfortablePadding ? 24.0 : 16.0;

/// Number of grid columns that fit given a minimum item width — the adaptive
/// alternative to hardcoding a column count per breakpoint. Guarantees at least
/// one column.
int gridColumnsFor(
  double availableWidth, {
  required double minItemWidth,
  double spacing = 16,
  int maxColumns = 8,
}) {
  if (availableWidth <= 0) return 1;
  final raw = ((availableWidth + spacing) / (minItemWidth + spacing)).floor();
  return raw.clamp(1, maxColumns);
}

/// Centers a page's scrollable content and caps its width on large displays,
/// so ultra-wide monitors get comfortable gutters instead of edge-to-edge
/// stretch. Transparent and layout-only — safe to wrap around any child.
///
/// Wrap a page's `ListView`/`CustomScrollView` with this: the scroll view still
/// fills the height and scrolls normally; only its horizontal extent is capped.
class PageContainer extends StatelessWidget {
  const PageContainer({
    super.key,
    required this.child,
    this.maxWidth = kContentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
