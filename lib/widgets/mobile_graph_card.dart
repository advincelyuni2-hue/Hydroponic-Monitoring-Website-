import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'card_info_tooltip.dart';
import 'mobile_page_header.dart';

/// Uses the owning screen's live state; opening a graph creates no controller.
class MobileGraphCard extends StatelessWidget {
  const MobileGraphCard(
      {super.key,
      required this.title,
      required this.actionLabel,
      required this.listenable,
      required this.builder,
      this.storageBucket,
      this.description,
      this.pageBackground,
      this.onMobileTap});

  final Color? pageBackground;
  final VoidCallback? onMobileTap;
  final String title;
  final String? description;
  final String actionLabel;
  final Listenable listenable;
  final WidgetBuilder builder;
  final PageStorageBucket? storageBucket;

  @override
  Widget build(BuildContext context) {
    if (!Responsive.isMobile(context)) return builder(context);
    return Container(
      width: double.infinity,
      decoration: AppDecorations.card(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onMobileTap ??
              () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => MobileGraphPage(
                        title: title,
                        backgroundColor: pageBackground,
                        listenable: listenable,
                        builder: builder,
                        storageBucket: storageBucket),
                  )),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(Icons.show_chart, color: AppColors.accentGreen),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (description == null)
                    Text(title,
                        style:
                            AppTextStyles.sectionTitle.copyWith(fontSize: 16))
                  else
                    CardInfoTitle(title,
                        description: description!,
                        style:
                            AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(actionLabel,
                      style: AppTextStyles.cardMeta
                          .copyWith(color: AppColors.accentGreen)),
                ],
              )),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: AppColors.accentGreen),
            ]),
          ),
        ),
      ),
    );
  }
}

class MobileGraphPage extends StatelessWidget {
  static bool isActive(BuildContext context) =>
      Responsive.isMobile(context) &&
      context.findAncestorWidgetOfExactType<MobileGraphPage>() != null;
  const MobileGraphPage(
      {super.key,
      required this.title,
      required this.listenable,
      required this.builder,
      this.storageBucket,
      this.backgroundColor});
  final Color? backgroundColor;
  final String title;
  final Listenable listenable;
  final WidgetBuilder builder;
  final PageStorageBucket? storageBucket;

  @override
  Widget build(BuildContext context) {
    final graph = LayoutBuilder(
        builder: (context, viewport) => _GraphViewport(
              height: viewport.maxHeight,
              child: ListenableBuilder(
                  listenable: listenable,
                  builder: (context, _) => builder(context)),
            ));
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      body: SafeArea(
          child: Column(children: [
        if (!Responsive.isMobile(context)) MobilePageHeader(title: title),
        Expanded(
            child: storageBucket == null
                ? graph
                : PageStorage(bucket: storageBucket!, child: graph)),
      ])),
    );
  }
}

class _GraphViewport extends InheritedWidget {
  const _GraphViewport({required this.height, required super.child});
  final double height;
  @override
  bool updateShouldNotify(_GraphViewport oldWidget) =>
      height != oldWidget.height;
}

/// Keeps the plot geometry independent of the overlaid details sheet.
class MobileGraphComposition extends StatelessWidget {
  const MobileGraphComposition(
      {super.key,
      required this.children,
      required this.chartIndex,
      this.crossAxisAlignment = CrossAxisAlignment.start,
      this.mainAxisSize = MainAxisSize.max,
      this.subtitle,
      this.sheetTitle = 'Graph details',
      this.summaries = const [],
      this.sheetContent});
  final List<Widget> children;
  final int chartIndex;
  final String? subtitle;
  final String sheetTitle;
  final List<Widget> summaries;
  final List<Widget>? sheetContent;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    final viewport =
        context.dependOnInheritedWidgetOfExactType<_GraphViewport>();
    if (!MobileGraphPage.isActive(context) || viewport == null) {
      return Column(
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: children);
    }
    var plot = children[chartIndex];
    if (plot is Flexible) plot = plot.child;
    if (plot is SizedBox && plot.child != null) plot = plot.child!;
    return SizedBox(
        height: viewport.height,
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(children: [
                Material(
                    color: AppColors.iconCircle,
                    shape: const CircleBorder(),
                    child: IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20))),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          context
                              .findAncestorWidgetOfExactType<MobileGraphPage>()!
                              .title,
                          style: AppTextStyles.sectionTitle
                              .copyWith(fontSize: 17)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style:
                                AppTextStyles.cardMeta.copyWith(fontSize: 11)),
                    ])),
              ])),
          Expanded(child: LayoutBuilder(builder: (context, constraints) {
            const peek = 0.0;
            return Stack(fit: StackFit.expand, children: [
              // Only reserve the collapsed header; expansion never resizes the plot.
              Positioned.fill(
                  bottom: peek,
                  child: LayoutBuilder(
                      builder: (context, plotSpace) => SingleChildScrollView(
                            primary: false,
                            physics: const ClampingScrollPhysics(),
                            child: SizedBox(
                                height:
                                    math.max(520.0, plotSpace.maxHeight * 1.25),
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: plot)),
                          ))),
              MobileGraphBottomSheet(
                  title: sheetTitle,
                  controls: children.first,
                  children: sheetContent ??
                      [
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12)),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: children.sublist(chartIndex + 1))),
                        if (summaries.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          LayoutBuilder(builder: (context, space) {
                            if (space.maxWidth < 260 ||
                                MediaQuery.textScalerOf(context).scale(12) >
                                    17) {
                              return Column(children: summaries);
                            }
                            return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (var i = 0;
                                      i < summaries.length;
                                      i++) ...[
                                    if (i > 0) const SizedBox(width: 8),
                                    Expanded(child: summaries[i]),
                                  ],
                                ]);
                          }),
                        ],
                      ]),
            ]);
          })),
        ]));
  }
}

/// Vertical sheet gestures stay separate from the uncovered chart's timeline.
class MobileGraphBottomSheet extends StatefulWidget {
  const MobileGraphBottomSheet(
      {super.key,
      required this.title,
      required this.controls,
      required this.children});
  final String title;
  final Widget controls;
  final List<Widget> children;
  @override
  State<MobileGraphBottomSheet> createState() => _MobileGraphBottomSheetState();
}

class _MobileGraphBottomSheetState extends State<MobileGraphBottomSheet> {
  bool _expanded = false;
  double _contentHeight = 0;
  double _dragDistance = 0;
  final _scroll = ScrollController();

  void _setExpanded(bool value) {
    if (!value && _scroll.hasClients) _scroll.jumpTo(0);
    setState(() => _expanded = value);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, space) {
        final maximum = math.min(480.0, space.maxHeight * 0.7);
        final expanded = (48 + _contentHeight).clamp(48.0, maximum);
        return Stack(fit: StackFit.expand, children: [
          if (!_expanded)
            Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.small(
                  heroTag: null,
                  tooltip: 'Expand details',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryButton,
                  onPressed: () => _setExpanded(true),
                  child: const Icon(Icons.keyboard_arrow_up),
                )),
          Offstage(
              offstage: !_expanded,
              child: ExcludeFocus(
                  excluding: !_expanded,
                  child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeInOutCubic,
                        height: expanded,
                        decoration: const BoxDecoration(
                            color: Color(0xFFF1F3E3),
                            border: Border(
                                top: BorderSide(color: Color(0xFFD7DCC1))),
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(28)),
                            boxShadow: [
                              BoxShadow(
                                  color: Color(0x18000000),
                                  blurRadius: 16,
                                  offset: Offset(0, -3))
                            ]),
                        clipBehavior: Clip.antiAlias,
                        child: Column(children: [
                          GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onVerticalDragStart: (_) => _dragDistance = 0,
                              onVerticalDragUpdate: (details) =>
                                  _dragDistance += details.delta.dy,
                              onVerticalDragEnd: (details) {
                                final velocity = details.primaryVelocity ?? 0;
                                if (velocity.abs() > 150 ||
                                    _dragDistance.abs() > 12) {
                                  _setExpanded(velocity.abs() > 150
                                      ? velocity < 0
                                      : _dragDistance < 0);
                                }
                              },
                              child: SizedBox(
                                  height: 48,
                                  child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                            width: 44,
                                            height: 5,
                                            decoration: BoxDecoration(
                                                color: const Color(0xFFB9BBA8),
                                                borderRadius:
                                                    BorderRadius.circular(4))),
                                        Row(children: [
                                          const SizedBox(width: 16),
                                          Expanded(
                                              child: Text(
                                                  _expanded ? '' : widget.title,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTextStyles.cardMeta
                                                      .copyWith(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight
                                                              .w700))),
                                          IconButton(
                                              tooltip: _expanded
                                                  ? 'Collapse details'
                                                  : 'Expand details',
                                              onPressed: () =>
                                                  _setExpanded(!_expanded),
                                              icon: Container(
                                                  decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                          color: const Color(
                                                              0xFFDDDECF))),
                                                  child: Icon(
                                                      _expanded
                                                          ? Icons
                                                              .keyboard_arrow_down
                                                          : Icons
                                                              .keyboard_arrow_up,
                                                      size: 20))),
                                        ]),
                                      ]))),
                          Expanded(
                              child: SingleChildScrollView(
                                  controller: _scroll,
                                  child: _MeasureGraphContent(
                                      onSize: (size) {
                                        if (mounted)
                                          setState(() =>
                                              _contentHeight = size.height);
                                      },
                                      child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              12, 0, 12, 8),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                widget.controls,
                                                const SizedBox(height: 8),
                                                ...widget.children,
                                              ]))))),
                        ]),
                      )))),
        ]);
      });
}

/// Measures the real scroll content once, including wrapping and text scaling.
class _MeasureGraphContent extends SingleChildRenderObjectWidget {
  const _MeasureGraphContent({required this.onSize, required super.child});
  final ValueChanged<Size> onSize;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderGraphContent(onSize);
  @override
  void updateRenderObject(
      BuildContext context, _RenderGraphContent renderObject) {
    renderObject.onSize = onSize;
  }
}

class _RenderGraphContent extends RenderProxyBox {
  _RenderGraphContent(this.onSize);
  ValueChanged<Size> onSize;
  Size? _previous;
  @override
  void performLayout() {
    super.performLayout();
    if (size == _previous) return;
    _previous = size;
    final measured = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onSize(measured);
    });
  }
}

/// Compact dropdown and horizon/timeframe pills shared by mobile graph sheets.
class MobileGraphControls extends StatelessWidget {
  const MobileGraphControls(
      {super.key,
      required this.value,
      required this.values,
      required this.onChanged,
      required this.trailing});
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final dropdown = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDDDECF))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Show',
                  style: AppTextStyles.cardMeta.copyWith(fontSize: 10)),
              DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                value: value,
                isDense: true,
                style: AppTextStyles.cardMeta
                    .copyWith(fontWeight: FontWeight.w700),
                items: values
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (item) {
                  if (item != null) onChanged(item);
                },
              )),
            ]));
    return LayoutBuilder(builder: (context, space) {
      if (space.maxWidth < 270 ||
          MediaQuery.textScalerOf(context).scale(12) > 17) {
        return Wrap(spacing: 12, runSpacing: 8, children: [dropdown, trailing]);
      }
      return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [dropdown, trailing]);
    });
  }
}

class MobileGraphSummary extends StatelessWidget {
  const MobileGraphSummary(
      {super.key,
      required this.title,
      required this.value,
      this.detail,
      this.valueColor});
  final String title;
  final String value;
  final String? detail;
  final Color? valueColor;
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.cardMeta),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.cardMeta.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        if (detail != null) ...[
          const SizedBox(height: 4),
          Text(detail!,
              style: AppTextStyles.cardMeta
                  .copyWith(fontSize: 11, color: valueColor)),
        ],
      ]));
}

/// Scrolls only the existing plot; controls and legends stay in the viewport.
class MobileGraphTimeline extends StatelessWidget {
  const MobileGraphTimeline(
      {super.key, required this.pointCount, required this.child});
  final int pointCount;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!MobileGraphPage.isActive(context)) return child;
    return _TimelinePoints(count: pointCount, child: child);
  }
}

class _TimelinePoints extends InheritedWidget {
  const _TimelinePoints({required this.count, required super.child});
  final int count;
  @override
  bool updateShouldNotify(_TimelinePoints oldWidget) =>
      count != oldWidget.count;
}

/// Two library-rendered regions share identical Y bounds, ticks and vertical
/// title reservations. Only the plot and its bottom titles scroll.
class MobileLineChart extends StatefulWidget {
  const MobileLineChart(this.data, {super.key, this.preserveAxes = false});
  final bool preserveAxes;
  final LineChartData data;

  @override
  State<MobileLineChart> createState() => _MobileLineChartState();
}

class _MobileLineChartState extends State<MobileLineChart> {
  final _scroll = ScrollController();
  Drag? _chartDrag;
  DragStartDetails? _panStart;
  bool _verticalDrag = false;
  Offset _panDistance = Offset.zero;
  LineChartData get data => widget.data;

  void _onTouch(FlTouchEvent event, LineTouchResponse? response) {
    // The chart library claims pans. Lock each gesture to its first movement's
    // dominant axis and forward it to the corresponding scroll position.
    if (event is FlPanStartEvent) {
      _chartDrag?.cancel();
      _chartDrag = null;
      _panStart = event.details;
      _panDistance = Offset.zero;
    } else if (event is FlPanUpdateEvent) {
      final movement = event.details.delta;
      if (_chartDrag == null && _panStart != null) {
        _panDistance += movement;
        // Ignore initial finger jitter before committing to a scroll axis.
        if (_panDistance.distance < 8) return;
        _verticalDrag = _panDistance.dy.abs() > _panDistance.dx.abs();
        final position = _verticalDrag
            ? Scrollable.maybeOf(context, axis: Axis.vertical)?.position
            : (_scroll.hasClients ? _scroll.position : null);
        _chartDrag = position?.drag(_panStart!, () => _chartDrag = null);
        _panStart = null;
      }
      final delta = _verticalDrag ? movement.dy : movement.dx;
      _chartDrag?.update(DragUpdateDetails(
          delta: _verticalDrag ? Offset(0, delta) : Offset(delta, 0),
          primaryDelta: delta,
          globalPosition: event.details.globalPosition,
          localPosition: event.details.localPosition));
    } else if (event is FlPanEndEvent) {
      final velocity = _verticalDrag
          ? event.details.velocity.pixelsPerSecond.dy
          : event.details.velocity.pixelsPerSecond.dx;
      _chartDrag?.end(DragEndDetails(
          velocity: Velocity(
              pixelsPerSecond:
                  _verticalDrag ? Offset(0, velocity) : Offset(velocity, 0)),
          primaryVelocity: velocity));
      _chartDrag = null;
      _panStart = null;
    } else if (event is FlPanCancelEvent) {
      _chartDrag?.cancel();
      _chartDrag = null;
      _panStart = null;
    }
    data.lineTouchData.touchCallback?.call(event, response);
  }

  @override
  void dispose() {
    _chartDrag?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!MobileGraphPage.isActive(context)) return LineChart(data);
    final count =
        context.dependOnInheritedWidgetOfExactType<_TimelinePoints>()?.count ??
            0;
    String axisLabel(double value) =>
        value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
    return LayoutBuilder(builder: (context, constraints) {
      final fontSize = (constraints.maxWidth / 32).clamp(10.0, 12.0);
      final style = AppTextStyles.cardMeta.copyWith(fontSize: fontSize);
      final painter = TextPainter(
        text: TextSpan(text: '${axisLabel(data.minY)}  ', style: style),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final minWidth = painter.width;
      painter.text = TextSpan(text: '${axisLabel(data.maxY)}  ', style: style);
      painter.layout();
      final labelWidth =
          (painter.width > minWidth ? painter.width : minWidth) + 8;
      painter.dispose();
      final oldLeft = data.titlesData.leftTitles;
      final originalInterval =
          oldLeft.sideTitles.interval ?? (data.maxY - data.minY) / 5;
      final availableTicks =
          (constraints.maxHeight / (fontSize * 4)).floor().clamp(2, 10);
      final range = data.maxY - data.minY;
      final interval = originalInterval > 0
          ? originalInterval *
              (range / originalInterval / availableTicks).ceil().clamp(1, 1000)
          : 1.0;
      final left = widget.preserveAxes
          ? oldLeft
          : AxisTitles(
              axisNameWidget: Text('Value', style: style),
              axisNameSize: 20,
              sideTitles: oldLeft.sideTitles.copyWith(
                reservedSize: labelWidth,
                interval: interval,
                getTitlesWidget: (value, meta) =>
                    Text(axisLabel(value), style: style),
              ),
            );
      final axisWidth = left.sideTitles.reservedSize + left.axisNameSize;
      final right = widget.preserveAxes
          ? data.titlesData.rightTitles
          : const AxisTitles(sideTitles: SideTitles(showTitles: false));
      final rightWidth = right.sideTitles.showTitles
          ? right.sideTitles.reservedSize + right.axisNameSize
          : 0.0;
      final oldBottom = data.titlesData.bottomTitles;
      Widget labelStyle(Widget widget) {
        if (widget is Text && widget.data != null) {
          return Text(widget.data!,
              style: (widget.style ?? style)
                  .copyWith(fontSize: (fontSize - 0.5).clamp(9.5, 11.5)),
              textAlign: widget.textAlign,
              maxLines: widget.maxLines);
        }
        if (widget is Padding && widget.child != null) {
          return Padding(
              padding: widget.padding, child: labelStyle(widget.child!));
        }
        return widget;
      }

      final top = oldBottom.copyWith(
          sideTitles: oldBottom.sideTitles.copyWith(
        reservedSize:
            math.max(56.0, MediaQuery.textScalerOf(context).scale(12) * 4),
        getTitlesWidget: (value, meta) {
          final label = oldBottom.sideTitles.getTitlesWidget(value, meta);
          if (label is SideTitleWidget ||
              (label is SizedBox && label.child == null)) return label;
          return SideTitleWidget(
            axisSide: meta.axisSide,
            space: 4,
            fitInside: SideTitleFitInsideData(
                enabled: true,
                axisPosition: meta.axisPosition,
                parentAxisSize: meta.parentAxisSize,
                distanceFromEdge: 4),
            child: labelStyle(label),
          );
        },
      ));
      final titles = data.titlesData.copyWith(
          leftTitles: left,
          topTitles: top,
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: right);
      final tooltip = data.lineTouchData.touchTooltipData;
      final shared = data.copyWith(
        titlesData: titles,
        backgroundColor: Colors.white,
        lineTouchData: data.lineTouchData.copyWith(
            touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: tooltip.tooltipRoundedRadius,
          tooltipPadding: tooltip.tooltipPadding,
          tooltipMargin: tooltip.tooltipMargin,
          tooltipHorizontalAlignment: tooltip.tooltipHorizontalAlignment,
          tooltipHorizontalOffset: tooltip.tooltipHorizontalOffset,
          maxContentWidth: tooltip.maxContentWidth,
          getTooltipItems: tooltip.getTooltipItems,
          getTooltipColor: tooltip.getTooltipColor,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          showOnTopOfTheChartBoxArea: tooltip.showOnTopOfTheChartBoxArea,
          rotateAngle: tooltip.rotateAngle,
          tooltipBorder: tooltip.tooltipBorder,
        )),
      );
      // Fixed axes need labels and matching reservations, not extra copies of
      // every line, gradient, annotation and touch recognizer in the chart.
      final axisData = shared.copyWith(
        lineBarsData: const [],
        betweenBarsData: const [],
        showingTooltipIndicators: const [],
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        extraLinesData: const ExtraLinesData(),
        rangeAnnotations: const RangeAnnotations(),
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: titles.copyWith(
            topTitles: top.copyWith(
                sideTitles: top.sideTitles.copyWith(
                    getTitlesWidget: (_, __) => const SizedBox.shrink()))),
      );
      final plotData = shared.copyWith(
          lineTouchData: shared.lineTouchData.copyWith(touchCallback: _onTouch),
          titlesData: titles.copyWith(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ));
      final viewportWidth = (constraints.maxWidth - axisWidth - rightWidth)
          .clamp(1.0, double.infinity);
      final xPositions = data.lineBarsData
          .expand((bar) => bar.spots)
          .where((spot) => spot.x.isFinite)
          .map((spot) => spot.x)
          .toSet()
          .toList()
        ..sort();
      final gaps = <double>[
        for (var i = 1; i < xPositions.length; i++)
          if (xPositions[i] > xPositions[i - 1])
            xPositions[i] - xPositions[i - 1],
      ]..sort();
      // An almost-duplicate timestamp must not create a millions-of-pixels
      // canvas. Use the normal cadence for sizing, retaining all plotted spots.
      final typicalGap = gaps.isEmpty ? 0.0 : gaps[gaps.length ~/ 2];
      final spacedWidth = typicalGap > 0
          ? (data.maxX - data.minX) / typicalGap * 36.0
          : count * 48.0;
      final plotWidth = xPositions.length < 2
          ? viewportWidth
          : math.max(viewportWidth * 1.25, math.max(count * 48.0, spacedWidth));
      return RepaintBoundary(
          child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
              width: axisWidth,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: constraints.maxWidth,
                  maxWidth: constraints.maxWidth,
                  child: IgnorePointer(
                      child: LineChart(axisData, duration: Duration.zero)),
                ),
              )),
          Expanded(
              child: SingleChildScrollView(
            controller: _scroll,
            physics: const ClampingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: SizedBox(
                width: plotWidth,
                child: LineChart(plotData, duration: Duration.zero)),
          )),
          if (rightWidth > 0)
            SizedBox(
                width: rightWidth,
                child: ClipRect(
                  child: OverflowBox(
                      alignment: Alignment.centerRight,
                      minWidth: constraints.maxWidth,
                      maxWidth: constraints.maxWidth,
                      child: IgnorePointer(
                          child: LineChart(axisData, duration: Duration.zero))),
                )),
        ]),
      ));
    });
  }
}
