import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'mobile_page_header.dart';
import 'app_footer.dart';
import 'card_info_tooltip.dart';

/// Uses the owning screen's live state; opening a graph creates no controller.
class MobileGraphCard extends StatelessWidget {
  const MobileGraphCard({super.key, required this.title,
    required this.actionLabel, required this.listenable, required this.builder,
    this.storageBucket, this.description});

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
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => MobileGraphPage(title: title,
              listenable: listenable, builder: builder,
              storageBucket: storageBucket),
          )),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(Icons.show_chart, color: AppColors.accentGreen),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (description == null)
                    Text(title, style: AppTextStyles.sectionTitle.copyWith(fontSize: 16))
                  else
                    CardInfoTitle(title, description: description!,
                        style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(actionLabel, style: AppTextStyles.cardMeta.copyWith(color: AppColors.accentGreen)),
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
  const MobileGraphPage({super.key, required this.title,
    required this.listenable, required this.builder, this.storageBucket});
  final String title;
  final Listenable listenable;
  final WidgetBuilder builder;
  final PageStorageBucket? storageBucket;

  @override
  Widget build(BuildContext context) {
    final graph = LayoutBuilder(builder: (context, viewport) => _GraphViewport(
      height: (viewport.maxHeight - 32 -
          AppFooter.heightFor(context, viewport.maxWidth - 32))
          .clamp(0.0, double.infinity),
      child: AppFooterScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: ListenableBuilder(listenable: listenable,
        builder: (context, _) => builder(context)),
    )));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Column(children: [
        MobilePageHeader(title: title),
        Expanded(child: storageBucket == null ? graph
            : PageStorage(bucket: storageBucket!, child: graph)),
      ])),
    );
  }
}

class _GraphViewport extends InheritedWidget {
  const _GraphViewport({required this.height, required super.child});
  final double height;
  @override
  bool updateShouldNotify(_GraphViewport oldWidget) => height != oldWidget.height;
}

/// Measures controls and legend at their natural height before sizing the plot.
/// No intrinsic measurements are used because chart widgets use LayoutBuilder.
class MobileGraphComposition extends StatelessWidget {
  const MobileGraphComposition({super.key, required this.children,
    required this.chartIndex, this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max});
  final List<Widget> children;
  final int chartIndex;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    final viewport = context.dependOnInheritedWidgetOfExactType<_GraphViewport>();
    if (!MobileGraphPage.isActive(context) || viewport == null) {
      return Column(crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize, children: children);
    }
    var plot = children[chartIndex];
    if (plot is Flexible) plot = plot.child;
    if (plot is SizedBox && plot.child != null) plot = plot.child!;
    Widget group(List<Widget> items) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment, children: items);
    return _MeasuredGraph(height: viewport.height, children: [
      group(children.sublist(0, chartIndex)),
      plot,
      group(children.sublist(chartIndex + 1)),
    ]);
  }
}

class _MeasuredGraph extends MultiChildRenderObjectWidget {
  const _MeasuredGraph({required this.height, required super.children});
  final double height;
  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMeasuredGraph(height);
  @override
  void updateRenderObject(BuildContext context, _RenderMeasuredGraph renderObject) {
    if (renderObject.viewportHeight != height) {
      renderObject.viewportHeight = height;
      renderObject.markNeedsLayout();
    }
  }
}

class _RenderMeasuredGraph extends RenderStack {
  _RenderMeasuredGraph(this.viewportHeight);
  double viewportHeight;
  @override
  void performLayout() {
    final items = getChildrenAsList();
    final width = constraints.maxWidth;
    for (final index in [0, 2]) {
      items[index].layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
    }
    final plotHeight = (viewportHeight - items[0].size.height - items[2].size.height)
        .clamp(280.0, double.infinity);
    items[1].layout(BoxConstraints.tightFor(width: width, height: plotHeight), parentUsesSize: true);
    double top = 0;
    for (final item in items) {
      (item.parentData as StackParentData).offset = Offset(0, top);
      top += item.size.height;
    }
    size = constraints.constrain(Size(width, top));
  }
  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// Scrolls only the existing plot; controls and legends stay in the viewport.
class MobileGraphTimeline extends StatelessWidget {
  const MobileGraphTimeline({super.key, required this.pointCount, required this.child});
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
  bool updateShouldNotify(_TimelinePoints oldWidget) => count != oldWidget.count;
}

/// Two library-rendered regions share identical Y bounds, ticks and vertical
/// title reservations. Only the plot and its bottom titles scroll.
class MobileLineChart extends StatelessWidget {
  const MobileLineChart(this.data, {super.key});
  final LineChartData data;

  @override
  Widget build(BuildContext context) {
    if (!MobileGraphPage.isActive(context)) return LineChart(data);
    final count = context.dependOnInheritedWidgetOfExactType<_TimelinePoints>()?.count ?? 0;
    return LayoutBuilder(builder: (context, constraints) {
      final fontSize = (constraints.maxWidth / 32).clamp(10.0, 12.0);
      final style = AppTextStyles.cardMeta.copyWith(fontSize: fontSize);
      final painter = TextPainter(
        text: TextSpan(text: '${data.minY.toStringAsFixed(6)}  ', style: style),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final minWidth = painter.width;
      painter.text = TextSpan(text: '${data.maxY.toStringAsFixed(6)}  ', style: style);
      painter.layout();
      final labelWidth = (painter.width > minWidth ? painter.width : minWidth) + 8;
      painter.dispose();
      final oldLeft = data.titlesData.leftTitles;
      final originalInterval = oldLeft.sideTitles.interval ?? (data.maxY - data.minY) / 5;
      final availableTicks = (constraints.maxHeight / (fontSize * 4)).floor().clamp(2, 10);
      final range = data.maxY - data.minY;
      final interval = originalInterval > 0
          ? originalInterval * (range / originalInterval / availableTicks).ceil().clamp(1, 1000)
          : 1.0;
      final left = AxisTitles(
        axisNameWidget: Text('Value', style: style),
        axisNameSize: 20,
        sideTitles: oldLeft.sideTitles.copyWith(
          reservedSize: labelWidth,
          interval: interval,
          getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(6), style: style),
        ),
      );
      final axisWidth = labelWidth + 20;
      final oldBottom = data.titlesData.bottomTitles;
      Widget labelStyle(Widget widget) {
        if (widget is Text && widget.data != null) {
          return Text(widget.data!, style: (widget.style ?? style).copyWith(
            fontSize: (fontSize - 0.5).clamp(9.5, 11.5)),
            textAlign: widget.textAlign, maxLines: widget.maxLines);
        }
        if (widget is Padding && widget.child != null) {
          return Padding(padding: widget.padding, child: labelStyle(widget.child!));
        }
        return widget;
      }
      final bottom = oldBottom.copyWith(sideTitles: oldBottom.sideTitles.copyWith(
        reservedSize: oldBottom.sideTitles.reservedSize < 42 ? 42 : oldBottom.sideTitles.reservedSize,
        getTitlesWidget: (value, meta) {
          final label = oldBottom.sideTitles.getTitlesWidget(value, meta);
          if (label is SideTitleWidget || label is SizedBox) return label;
          return SideTitleWidget(
            axisSide: meta.axisSide,
            space: 4,
            fitInside: SideTitleFitInsideData(enabled: true,
              axisPosition: meta.axisPosition, parentAxisSize: meta.parentAxisSize,
              distanceFromEdge: 4),
            child: labelStyle(label),
          );
        },
      ));
      final titles = data.titlesData.copyWith(leftTitles: left, bottomTitles: bottom,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)));
      final tooltip = data.lineTouchData.touchTooltipData;
      final shared = data.copyWith(titlesData: titles, backgroundColor: Colors.white,
        lineTouchData: data.lineTouchData.copyWith(touchTooltipData: LineTouchTooltipData(
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
      final plotData = shared.copyWith(titlesData: titles.copyWith(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ));
      final viewportWidth = (constraints.maxWidth - axisWidth).clamp(1.0, double.infinity);
      final plotWidth = count <= 6 ? viewportWidth
          : (count * 48.0).clamp(viewportWidth, 12000.0);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(width: axisWidth, child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: constraints.maxWidth,
              maxWidth: constraints.maxWidth,
              child: IgnorePointer(child: LineChart(shared, duration: Duration.zero)),
            ),
          )),
          Expanded(child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: SizedBox(width: plotWidth,
              child: LineChart(plotData, duration: Duration.zero)),
          )),
        ]),
      );
    });
  }
}
