import 'package:animated_segmented_tab_control/src/utils/double_range.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'tab.dart';
import 'utils/custom_clippers.dart';

/// Widget based on [TabController]. Can simply replace [TabBar].
///
/// Requires [TabController], witch can be read from [context] with
/// [DefaultTabController] using. Or you can provide controller in the constructor.
class SegmentedTabControl extends StatelessWidget {
  const SegmentedTabControl({
    super.key,
    required this.tabs,
    this.height = kTextTabBarHeight,
    this.controller,
    this.tabTextColor,
    this.textStyle,
    this.subLabelTextStyle,
    this.selectedTextStyle,
    this.selectedSubLabelTextStyle,
    this.selectedTabTextColor,
    this.vibrateOnTap = false,
    this.squeezeIntensity = 1,
    this.squeezeDuration = const Duration(milliseconds: 500),
    this.indicatorPadding = EdgeInsets.zero,
    this.tabPadding = const EdgeInsets.symmetric(horizontal: 8),
    this.splashColor,
    this.splashHighlightColor,
    this.barDecoration = const BoxDecoration(
      color: Colors.grey,
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    this.indicatorDecoration = const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
  });

  /// Height of the widget.
  ///
  /// [preferredSize] returns this value.
  final double height;

  /// Selection options. Can be either a list of [SegmentTab] or a list of [Widget].
  final List<dynamic> tabs;

  /// Can be provided by [DefaultTabController].
  final TabController? controller;

  /// Style of all labels. Color will not be applied.
  final TextStyle? textStyle;

  /// Style of sub labels. Color will not be applied.
  final TextStyle? subLabelTextStyle;

  /// Style of selected tab label. Color will not be applied.
  final TextStyle? selectedTextStyle;

  /// Style of selected tab sub label. Color will not be applied
  final TextStyle? selectedSubLabelTextStyle;

  /// The color of the text beyond the indicator.
  final Color? tabTextColor;

  /// The color of the text inside the indicator.
  final Color? selectedTabTextColor;

  final bool vibrateOnTap;

  /// Intensity of squeeze animation.
  ///
  /// This animation starts when you click on the indicator and stops when you
  /// take your finger off the indicator.
  final double squeezeIntensity;

  /// Duration of squeeze animation.
  ///
  /// This animation starts when you click on the indicator and stops when you
  /// take your finger off the indicator.
  final Duration squeezeDuration;

  /// Only vertical padding will be applied.
  final EdgeInsets indicatorPadding;

  /// Padding of labels.
  final EdgeInsets tabPadding;

  /// Splash color of options.
  final Color? splashColor;

  /// Splash highlight color of options.
  final Color? splashHighlightColor;

  /// Segmented control bar decoration
  final BoxDecoration? barDecoration;

  ///Indicator decoration
  final BoxDecoration? indicatorDecoration;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _SegmentedTabControl(
          tabs: tabs,
          height: height,
          maxWidth: constraints.maxWidth,
          controller: controller,
          tabTextColor: tabTextColor,
          textStyle: textStyle,
          subLabelTextStyle: subLabelTextStyle,
          selectedTextStyle: selectedTextStyle,
          selectedSubLabelTextStyle: selectedSubLabelTextStyle,
          vibrateOnTap: vibrateOnTap,
          selectedTabTextColor: selectedTabTextColor,
          squeezeIntensity: squeezeIntensity,
          squeezeDuration: squeezeDuration,
          indicatorPadding: indicatorPadding,
          tabPadding: tabPadding,
          splashColor: splashColor,
          splashHighlightColor: splashHighlightColor,
          barDecoration: barDecoration,
          indicatorDecoration: indicatorDecoration,
        );
      },
    );
  }
}

class _SegmentedTabControl extends StatefulWidget
    implements PreferredSizeWidget {
  const _SegmentedTabControl({
    required this.height,
    required this.tabs,
    required this.maxWidth,
    this.controller,
    this.tabTextColor,
    this.textStyle,
    this.subLabelTextStyle,
    this.selectedTextStyle,
    this.selectedTabTextColor,
    this.selectedSubLabelTextStyle,
    this.vibrateOnTap = false,
    this.squeezeIntensity = 1,
    this.squeezeDuration = const Duration(milliseconds: 500),
    this.indicatorPadding = EdgeInsets.zero,
    this.tabPadding = const EdgeInsets.symmetric(horizontal: 8),
    this.splashColor,
    this.splashHighlightColor,
    this.barDecoration,
    this.indicatorDecoration,
  });

  final List<dynamic> tabs;
  final double height;
  final double maxWidth;
  final TabController? controller;
  final TextStyle? textStyle;
  final TextStyle? subLabelTextStyle;
  final TextStyle? selectedTextStyle;
  final TextStyle? selectedSubLabelTextStyle;
  final Color? tabTextColor;
  final Color? selectedTabTextColor;
  final bool vibrateOnTap;
  final double squeezeIntensity;
  final Duration squeezeDuration;
  final EdgeInsets indicatorPadding;
  final EdgeInsets tabPadding;
  final Color? splashColor;
  final Color? splashHighlightColor;
  final BoxDecoration? barDecoration;
  final BoxDecoration? indicatorDecoration;

  @override
  _SegmentedTabControlState createState() => _SegmentedTabControlState();

  @override
  Size get preferredSize => Size.fromHeight(height);
}

class _SegmentedTabControlState extends State<_SegmentedTabControl>
    with SingleTickerProviderStateMixin {
  EdgeInsets _currentTilePadding = EdgeInsets.zero;
  Alignment _currentIndicatorAlignment = Alignment.centerLeft;
  late AnimationController _internalAnimationController;
  late Animation<Alignment> _internalAnimation;
  TabController? _controller;

  int _totalFlex = 0;

  double _maxWidth = 0;

  List<double> flexFactors = [];

  List<DoubleRange> alignmentXRanges = [];

  bool get _controllerIsValid => _controller?.animation != null;

  int _internalIndex = 0;

  @override
  void initState() {
    super.initState();
    _maxWidth = widget.maxWidth;
    _internalAnimationController = AnimationController(vsync: this);
    _internalAnimationController.addListener(_handleInternalAnimationTick);
    _calculateTotalFlex();
    _calculateFlexFactors();
  }

  void _handleInternalAnimationTick() {
    setState(() {
      _currentIndicatorAlignment = _internalAnimation.value;
    });
  }

  @override
  void dispose() {
    _internalAnimationController.removeListener(_handleInternalAnimationTick);
    _internalAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _updateTabController();
    super.didChangeDependencies();
  }

  void _calculateTotalFlex() {
    _totalFlex = widget.tabs.fold(0, (previousValue, tab) {
      if (tab is SegmentTab) {
        return previousValue + tab.flex;
      } else {
        return previousValue + 1;
      }
    });
  }

  void _calculateFlexFactors() {
    int collectedFlex = 0;
    for (int i = 0; i < widget.tabs.length; i++) {
      final tab = widget.tabs[i];
      if (tab is SegmentTab) {
        collectedFlex += tab.flex;
      } else {
        collectedFlex += 1;
      }
      flexFactors.add(collectedFlex / _totalFlex);
    }
  }

  @override
  void didUpdateWidget(_SegmentedTabControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _calculateTotalFlex();
      _calculateFlexFactors();
      _updateTabController();
    }
  }

  void _updateTabController() {
    final TabController? newController =
        widget.controller ?? DefaultTabController.of(context);
    assert(() {
      if (newController == null) {
        throw FlutterError(
          'No TabController for ${widget.runtimeType}.\n'
          'When creating a ${widget.runtimeType}, you must either provide an explicit '
          'TabController using the "controller" property, or you must ensure that there '
          'is a DefaultTabController above the ${widget.runtimeType}.\n'
          'In this case, there was neither an explicit controller nor a default controller.',
        );
      }
      return true;
    }());

    if (newController == _controller) {
      return;
    }

    if (_controllerIsValid) {
      _controller!.animation!.removeListener(_handleTabControllerAnimationTick);
    }

    _controller = newController;
    _calculateTabIndicatorAlignmentRanges();

    if (_controller != null) {
      _controller!.animation!.addListener(_handleTabControllerAnimationTick);
      _currentIndicatorAlignment =
          _animationValueToAlignment(_controller!.index.toDouble());
    }
  }

  void _handleTabControllerAnimationTick() {
    final currentValue = _controller!.animation!.value;
    _animateIndicatorTo(_animationValueToAlignment(currentValue));
  }

  void _calculateTabIndicatorAlignmentRanges() {
    double computedWidth = 0;
    double alignmentStartX = 0;

    for (int index = 0; index < _controller!.length - 1; index++) {
      final tab = widget.tabs[index];
      final nextTab = widget.tabs[index + 1];

      final tabWidth =
          (tab is SegmentTab ? tab.flex : 1) / _totalFlex * _maxWidth;
      final nextTabWidth =
          (nextTab is SegmentTab ? nextTab.flex : 1) / _totalFlex * _maxWidth;

      if (nextTabWidth >= tabWidth) {
        final alignmentEndX = computedWidth + (tabWidth / 2);
        alignmentXRanges.add(DoubleRange(alignmentStartX, alignmentEndX));
        alignmentStartX = alignmentEndX;
      } else {
        final controlPoint = computedWidth + (nextTabWidth / 2);
        alignmentXRanges.add(DoubleRange(alignmentStartX, controlPoint));
        alignmentStartX = computedWidth + tabWidth - (nextTabWidth / 2);
      }

      computedWidth += tabWidth;
    }
    alignmentXRanges.add(DoubleRange(alignmentStartX, computedWidth));
  }

  Alignment _animationValueToAlignment(double? value) {
    if (value == null) {
      return const Alignment(-1, 0);
    }

    final index = value.round();
    final reminder = value - index;
    final x = _calculateTarget(reminder, index);

    _internalIndex = index;
    return _calculateAlignmentFromTarget(x, index);
  }

  double _calculateTarget(double reminder, int index) {
    final tabLeftX = index > 0 ? flexFactors[index - 1] * _maxWidth : 0;
    double target;
    if (reminder > 0) {
      target = tabLeftX +
          ((reminder * 2) * (alignmentXRanges[index].endInclusive - tabLeftX));
    } else {
      target = tabLeftX +
          ((reminder * 2) * (tabLeftX - alignmentXRanges[index].start));
    }

    return target;
  }

  Alignment _calculateAlignmentFromTarget(double position, int index) {
    final tabWidth =
        (widget.tabs[index] is SegmentTab ? widget.tabs[index].flex : 1) /
            _totalFlex *
            _maxWidth;
    final currentTabHalfWidth = tabWidth / 2;
    final halfMaxWidth = _maxWidth / 2;

    final x = (position - halfMaxWidth + currentTabHalfWidth) /
        (halfMaxWidth - currentTabHalfWidth);

    return Alignment(x, 0);
  }

  TickerFuture _animateIndicatorTo(Alignment target) {
    _internalAnimation = _internalAnimationController.drive(AlignmentTween(
      begin: _currentIndicatorAlignment,
      end: target,
    ));

    return _internalAnimationController.fling();
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = widget.tabs[_internalIndex];

    final textStyle =
        widget.textStyle ?? Theme.of(context).textTheme.bodyMedium!;

    final subLabelTextStyle =
        widget.subLabelTextStyle ?? Theme.of(context).textTheme.bodySmall!;

    final selectedTextStyle = widget.selectedTextStyle ?? textStyle;

    final selectedSubLabelTextStyle =
        widget.selectedSubLabelTextStyle ?? subLabelTextStyle;

    final selectedTabTextColor = currentTab is SegmentTab
        ? currentTab.selectedTextColor ??
            widget.selectedTabTextColor ??
            Colors.white
        : null;

    final tabTextColor = currentTab is SegmentTab
        ? currentTab.textColor ??
            widget.tabTextColor ??
            Colors.white.withOpacity(0.7)
        : null;

    return DefaultTextStyle(
      style: widget.textStyle ?? DefaultTextStyle.of(context).style,
      child: LayoutBuilder(
        builder: (context, _) {
          final indicatorWidth =
              ((_maxWidth - widget.indicatorPadding.horizontal) / _totalFlex) *
                  (currentTab is SegmentTab ? currentTab.flex : 1);

          return ClipRRect(
            borderRadius:
                widget.barDecoration?.borderRadius ?? BorderRadius.zero,
            child: SizedBox(
              height: widget.height,
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: kTabScrollDuration,
                    curve: Curves.ease,
                    decoration: widget.barDecoration?.copyWith(
                      color: currentTab is SegmentTab
                          ? currentTab.backgroundColor
                          : null,
                      gradient: currentTab is SegmentTab
                          ? currentTab.backgroundGradient
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: _Labels(
                        radius: widget.indicatorDecoration?.borderRadius,
                        splashColor: widget.splashColor,
                        splashHighlightColor: widget.splashHighlightColor,
                        callbackBuilder: _onTabTap(),
                        tabs: widget.tabs,
                        currentIndex: _internalIndex,
                        textStyle: textStyle.copyWith(
                          color: tabTextColor,
                        ),
                        subLabelTextStyle: subLabelTextStyle.copyWith(
                          color: tabTextColor,
                        ),
                        selectedTextStyle: selectedTextStyle.copyWith(
                          color: tabTextColor,
                        ),
                        selectedSubLabelTextStyle:
                            selectedSubLabelTextStyle.copyWith(
                          color: tabTextColor,
                        ),
                        tabPadding: widget.tabPadding,
                      ),
                    ),
                  ),
                  Align(
                    alignment: _currentIndicatorAlignment,
                    child: GestureDetector(
                      onPanDown: _onPanDown(),
                      onPanUpdate: _onPanUpdate(_maxWidth),
                      onPanEnd: _onPanEnd(_maxWidth),
                      child: Padding(
                        padding: widget.indicatorPadding,
                        child: _SqueezeAnimated(
                          currentTilePadding: _currentTilePadding,
                          squeezeDuration: widget.squeezeDuration,
                          builder: (_) => AnimatedContainer(
                            duration: kTabScrollDuration,
                            curve: Curves.ease,
                            width: indicatorWidth,
                            height: widget.height -
                                widget.indicatorPadding.vertical,
                            decoration: widget.indicatorDecoration?.copyWith(
                              color: currentTab is SegmentTab
                                  ? currentTab.color
                                  : null,
                              gradient: currentTab is SegmentTab
                                  ? currentTab.gradient
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _SqueezeAnimated(
                    currentTilePadding: _currentTilePadding,
                    squeezeDuration: widget.squeezeDuration,
                    builder: (squeezePadding) => ClipPath(
                      clipper: RRectRevealClipper(
                        size: Size(
                          indicatorWidth,
                          widget.height -
                              widget.indicatorPadding.vertical -
                              squeezePadding.vertical,
                        ),
                        offset: Offset(
                          _xToPercentsCoefficient(_currentIndicatorAlignment) *
                              (_maxWidth - indicatorWidth),
                          0,
                        ),
                      ),
                      child: IgnorePointer(
                        child: _Labels(
                          radius: widget.indicatorDecoration?.borderRadius,
                          splashColor: widget.splashColor,
                          splashHighlightColor: widget.splashHighlightColor,
                          tabs: widget.tabs,
                          currentIndex: _internalIndex,
                          textStyle: textStyle.copyWith(
                            color: tabTextColor,
                          ),
                          subLabelTextStyle: subLabelTextStyle.copyWith(
                            color: tabTextColor,
                          ),
                          selectedTextStyle: selectedTextStyle.copyWith(
                            color: selectedTabTextColor,
                          ),
                          selectedSubLabelTextStyle:
                              selectedSubLabelTextStyle.copyWith(
                            color: selectedTabTextColor,
                          ),
                          tabPadding: widget.tabPadding,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  VoidCallback Function(int)? _onTabTap() {
    if (_controller!.indexIsChanging) {
      return null;
    }
    return (int index) => () {
          if (widget.vibrateOnTap) HapticFeedback.mediumImpact();
          _internalAnimationController.stop();
          _controller!.animateTo(index);
        };
  }

  GestureDragDownCallback? _onPanDown() {
    if (_controller!.indexIsChanging) {
      return null;
    }
    return (details) {
      _internalAnimationController.stop();
      setState(() {
        _currentTilePadding =
            EdgeInsets.symmetric(vertical: widget.squeezeIntensity);
      });
    };
  }

  GestureDragUpdateCallback? _onPanUpdate(double maxWidth) {
    if (_controller!.indexIsChanging) {
      return null;
    }
    return (details) {
      double x = _currentIndicatorAlignment.x +
          details.delta.dx / (maxWidth / widget.tabs.length);
      if (x < -1) {
        x = -1;
      } else if (x > 1) {
        x = 1;
      }
      setState(() {
        _currentIndicatorAlignment = Alignment(x, 0);
        _internalIndex = _alignmentToIndex(_currentIndicatorAlignment);
      });
    };
  }

  int _alignmentToIndex(Alignment alignment) {
    final currentPosition = _xToPercentsCoefficient(alignment);
    final roundedCurrentPosition =
        num.parse(currentPosition.toStringAsFixed(2));

    final index = flexFactors
        .indexWhere((flexFactor) => roundedCurrentPosition <= flexFactor);

    return index == -1 ? _controller!.length - 1 : index;
  }

  /// Converts [Alignment.x] value in range -1..1 to 0..1 percents coefficient
  double _xToPercentsCoefficient(Alignment alignment) {
    return (alignment.x + 1) / 2;
  }

  GestureDragEndCallback _onPanEnd(double maxWidth) {
    return (details) {
      _animateIndicatorToNearest(
        details.velocity.pixelsPerSecond,
        maxWidth,
      );
      _updateControllerIndex();
      setState(() {
        _currentTilePadding = EdgeInsets.zero;
      });
    };
  }

  TickerFuture _animateIndicatorToNearest(
      Offset pixelsPerSecond, double width) {
    final nearest = _internalIndex;
    final target = _animationValueToAlignment(nearest.toDouble());
    _internalAnimation = _internalAnimationController.drive(AlignmentTween(
      begin: _currentIndicatorAlignment,
      end: target,
    ));
    final unitsPerSecondX = pixelsPerSecond.dx / width;
    final unitsPerSecond = Offset(unitsPerSecondX, 0);
    final unitVelocity = unitsPerSecond.distance;

    const spring = SpringDescription(mass: 30, stiffness: 1, damping: 1);

    final simulation = SpringSimulation(spring, 0, 1, -unitVelocity);

    return _internalAnimationController.animateWith(simulation);
  }

  void _updateControllerIndex() {
    _controller!.index = _internalIndex;
  }
}

class _Labels extends StatelessWidget {
  const _Labels({
    Key? key,
    this.callbackBuilder,
    required this.tabs,
    required this.currentIndex,
    required this.textStyle,
    required this.subLabelTextStyle,
    required this.selectedTextStyle,
    required this.selectedSubLabelTextStyle,
    this.radius,
    this.splashColor,
    this.splashHighlightColor,
    this.tabPadding = const EdgeInsets.symmetric(horizontal: 8),
  }) : super(key: key);

  final VoidCallback Function(int index)? callbackBuilder;
  final List<dynamic> tabs;
  final int currentIndex;
  final TextStyle textStyle;
  final TextStyle subLabelTextStyle;
  final TextStyle selectedTextStyle;
  final TextStyle selectedSubLabelTextStyle;
  final EdgeInsets tabPadding;
  final BorderRadiusGeometry? radius;
  final Color? splashColor;
  final Color? splashHighlightColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          tabs.length,
          (index) {
            final tab = tabs[index];
            if (tab is SegmentTab) {
              return Flexible(
                flex: tab.flex,
                child: InkWell(
                  splashColor: tab.splashColor ?? splashColor,
                  highlightColor:
                      tab.splashHighlightColor ?? splashHighlightColor,
                  borderRadius: radius as BorderRadius?,
                  onTap: callbackBuilder?.call(index),
                  child: Padding(
                    padding: tabPadding,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: kTabScrollDuration,
                            curve: Curves.ease,
                            style: (index == currentIndex)
                                ? selectedTextStyle
                                : textStyle,
                            child: Text(
                              tab.label,
                              overflow: TextOverflow.clip,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (tab.subLabel != null)
                            AnimatedDefaultTextStyle(
                              duration: kTabScrollDuration,
                              curve: Curves.ease,
                              style: (index == currentIndex)
                                  ? selectedSubLabelTextStyle
                                  : subLabelTextStyle,
                              child: Text(
                                tab.subLabel!,
                                overflow: TextOverflow.clip,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            } else {
              return Expanded(
                child: InkWell(
                  splashColor: splashColor,
                  highlightColor: splashHighlightColor,
                  borderRadius: radius as BorderRadius?,
                  onTap: callbackBuilder?.call(index),
                  child: Padding(
                    padding: tabPadding,
                    child: Center(
                      child: tab,
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class _SqueezeAnimated extends StatelessWidget {
  const _SqueezeAnimated({
    Key? key,
    required this.builder,
    required this.currentTilePadding,
    this.squeezeDuration = const Duration(milliseconds: 500),
  }) : super(key: key);

  final Widget Function(EdgeInsets) builder;
  final EdgeInsets currentTilePadding;
  final Duration squeezeDuration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<EdgeInsets>(
      curve: Curves.decelerate,
      tween: Tween(
        begin: EdgeInsets.zero,
        end: currentTilePadding,
      ),
      duration: squeezeDuration,
      builder: (context, padding, _) => Padding(
        padding: padding,
        child: builder.call(padding),
      ),
    );
  }
}
