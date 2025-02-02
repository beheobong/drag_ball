import 'dart:math' as math show pi;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderProxyBox;

part 'drag_ball_controller.dart';
part 'drag_ball_position.dart';
part 'enum.dart';
part 'utils.dart';

const Duration _kDefaultAnimationDuration = Duration(milliseconds: 300);

class Dragball extends StatefulWidget {
  const Dragball({
    Key? key,
    required this.child,
    required this.ball,
    required this.onTap,
    required this.initialPosition,
    required this.onPositionChanged,
    this.onIconBallTapped,
    this.controller,
    this.marginTopBottom = 150,
    this.withIcon = true,
    this.icon,
    this.iconSize = 24,
    this.rotateIcon = true,
    this.animationSizeDuration,
    this.curveSizeAnimation,
    this.iconPosition = IconPosition.center,
    this.scrollAndHide = true,
  }) : super(key: key);

  /// Put your screen here
  /// example your [Scaffold]
  final Widget child;

  /// This widget for Custom your ball
  /// example with image
  /// make sure the size is the same as [ballSize] property
  final Widget ball;

  final DragballController? controller;

  /// This function will be called when the ball is pressed
  final VoidCallback onTap;

  /// This function will called when icon is tapped / pressed
  /// default when tapped icon is show / hide ball
  /// If you need show / close ball this function will help you
  final OnIconBallTapped? onIconBallTapped;

  /// [initialPosition] will be the location or display
  /// or configuration of the first position [Dragball]
  final DragballPosition initialPosition;

  /// Custom Margin top bottom
  /// Ball would not be in that position
  /// default [marginTopBottom: 150]
  final double marginTopBottom;

  /// If you don't want to show ball with icon,
  /// Change value to false
  /// default[withIcon: true]
  final bool withIcon;

  /// Custom icon for controll hide/show ball
  final Widget? icon;

  /// If you want custom icon size
  /// Change value with you want
  /// default icon size 24
  final double iconSize;

  /// if you don't want any icon rotation animation on [ball] in hide or show,
  /// change this property to false
  /// default true
  final bool rotateIcon;

  /// Custom duration for size animation
  /// default [duration: Duration(milliseconds: 200)]
  final Duration? animationSizeDuration;

  /// CurvesSizeAnimation
  /// default [curve: Curves.easeIn]
  final Curve? curveSizeAnimation;

  /// this function will return the value of [DragballPosition]
  /// every time the position changes
  final ValueChanged<DragballPosition> onPositionChanged;

  /// Use this property to set [IconPosition] the top, center, or bottom position of the icon.
  /// Default [IconPostion] is center
  final IconPosition iconPosition;

  /// if you don't want size animation when user scrolls, set this property value to false
  /// Default true
  final bool scrollAndHide;
  @override
  _DragballState createState() => _DragballState();
}

class _DragballState extends State<Dragball> with TickerProviderStateMixin {
  bool _isBallDraged = false,
      _isBallHide = false,
      _isPositionOnRight = false,
      _isClose = false;
  double? _top, _left = 0, _right, _bottom;
  Size? _ballSize;
  late DragballPosition _dragballPosition;
  late DragballController _controller;
  late AnimationController _animationController;
  late AnimationController _offsetAnimationController;
  late AnimationController _rotateIconAnimationController;
  late Animation<double> _sizeAnimation;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _rotateIconAnimation;

  @override
  void initState() {
    _animationController = AnimationController(
        vsync: this,
        duration: widget.animationSizeDuration ?? _kDefaultAnimationDuration);
    _sizeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: widget.curveSizeAnimation ?? Curves.easeIn,
      ),
    );
    _offsetAnimationController =
        AnimationController(vsync: this, duration: _kDefaultAnimationDuration);
    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.6, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _offsetAnimationController,
        curve: Curves.easeIn,
      ),
    );
    _rotateIconAnimationController =
        AnimationController(vsync: this, duration: _kDefaultAnimationDuration);
    _rotateIconAnimation = Tween<double>(begin: 0, end: -math.pi)
        .animate(_rotateIconAnimationController);

    _initialPosition();
    _initController();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant Dragball oldWidget) {
    if (widget.animationSizeDuration != oldWidget.animationSizeDuration) {
      _animationController.duration = widget.animationSizeDuration;
    }
    super.didUpdateWidget(oldWidget);
  }

  /// function to initialize position
  /// just called on [initState]
  ///
  void _initialPosition() {
    final position = widget.initialPosition;
    final isRight = position.isRight;
    final isHide = position.isHide;
    _dragballPosition = widget.initialPosition;
    _top = widget.initialPosition.top;
    _isBallHide = isHide;
    if (isRight) {
      _left = null;
      _right = 0;
      _isPositionOnRight = true;

      if (!isHide) {
        _rotateIconAnimationController.value = 1.0;
      } else {
        _offsetAnimationController.value = 1.0;
      }
    } else {
      _left = 0;
      _right = null;
      _isPositionOnRight = false;

      if (isHide) {
        _offsetAnimationController.value = 1.0;
        _rotateIconAnimationController.value = 1.0;
      }
    }
  }

  void _initController() {
    _controller = widget.controller ?? DragballController();
    _isClose = _controller.value == BallState.close;
    _controller.addListener(() {
      final ballState = _controller.value;
      if (ballState == BallState.close) {
        setState(() {
          _isClose = true;
        });
      } else if (_isClose) {
        setState(() {
          _isClose = false;
        });
      }
    });
  }

  /// Monitor if there is scroll activity
  /// if there is scroll activity this function will trigger size animation
  bool _onNotification(ScrollNotification? scrollNotification) {
    if (scrollNotification == null || !widget.scrollAndHide) {
      return false;
    }
    if (scrollNotification is ScrollStartNotification) {
      if (scrollNotification.metrics.axis == Axis.vertical) {
        _animationController.forward();
      }
    }
    if (scrollNotification is ScrollEndNotification) {
      if (scrollNotification.metrics.axis == Axis.vertical) {
        _animationController.reverse();
      }
    }
    return false;
  }

  /// This function will be called the first time
  /// when the user drag the ball
  void _onDragStarted() {
    setState(() {
      _isBallDraged = true;
    });
  }

  /// This function will hide the ball or show the ball
  void _onHideOrShowBall() {
    if (!_isBallHide) {
      _offsetAnimationController.forward();
      if (_isPositionOnRight) {
        _rotateIconAnimationController.reverse();
      } else {
        _rotateIconAnimationController.forward();
      }
    } else {
      _offsetAnimationController.reverse();
      if (_isPositionOnRight) {
        _rotateIconAnimationController.forward();
      } else {
        _rotateIconAnimationController.reverse();
      }
    }
    _isBallHide = !_isBallHide;
// khi chuyển sang bên trái bị bug là bên phải
//     widget.onPositionChanged(
//       _dragballPosition.copyWith(isHide: _isBallHide),
//     );

    setState(() {});
  }

  /// When the user releases the ball, this function will
  /// calculate the position of the ball
  void _onDragEnd(DraggableDetails details, Size size) {
    final Offset offset = details.offset;
    final double halfWidthBall = _ballSize!.width / 1.5;
    final double halfWidth = size.width / 2 - halfWidthBall;
    final double maxHeight = size.height - 150.0;

    if (offset.dy < widget.marginTopBottom) {
      _top = widget.marginTopBottom;
      _bottom = null;
    } else if (offset.dy > widget.marginTopBottom && offset.dy < maxHeight) {
      _top = offset.dy;
      _bottom = null;
    } else {
      _bottom = widget.marginTopBottom;
      _top = null;
    }
    if (offset.dx > halfWidth) {
      _right = 0;
      _isBallHide
          ? _rotateIconAnimationController.reverse()
          : _rotateIconAnimationController.forward();
      _isPositionOnRight = true;
      _left = null;
    } else {
      _right = null;
      _isPositionOnRight = false;
      !_isBallHide
          ? _rotateIconAnimationController.reverse()
          : _rotateIconAnimationController.forward();
      _left = 0;
    }
    _isBallDraged = false;
    widget.onPositionChanged(
      _dragballPosition.copyWith(isRight: _isPositionOnRight, top: _top),
    );
    setState(() {});
  }

  /// When ball position change from left to right or right to left
  /// this method will determine the position of the icon
  /// based on [widget.iconPosition] Property
  Alignment _iconAlignment() {
    if (_isPositionOnRight) {
      switch (widget.iconPosition) {
        case IconPosition.top:
          return Alignment.topLeft;
        case IconPosition.center:
          return Alignment.centerLeft;
        default:
          return Alignment.bottomLeft;
      }
    } else {
      switch (widget.iconPosition) {
        case IconPosition.top:
          return Alignment.topRight;
        case IconPosition.center:
          return Alignment.centerRight;
        default:
          return Alignment.bottomRight;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _offsetAnimationController.dispose();
    _rotateIconAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final ThemeData theme = Theme.of(context);

    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: Stack(
        children: [
          Opacity(
            opacity: 0,
            child: MeasureProperty(
              onChanged: (size) {
                _ballSize = size;
                setState(() {});
              },
              child: widget.ball,
            ),
          ),
          RepaintBoundary(
            child: widget.child,
          ),
          if (_ballSize != null)
            Positioned(
              top: _top,
              left: _left,
              right: _right,
              bottom: _bottom,
              width: _ballSize!.width +
                  (widget.iconSize + (widget.icon == null ? 3 : 0)) / 2,
              height: _ballSize!.width,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                reverseDuration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOutSine,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                  alignment: _isPositionOnRight
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                ),
                child: _isClose
                    ? SizedBox.fromSize(
                        size: _ballSize ?? Size.zero,
                      )
                    : AnimatedBuilder(
                        animation: _offsetAnimationController,
                        builder: (context, child) {
                          if (_isPositionOnRight) {
                            return FractionalTranslation(
                              translation: _offsetAnimation.value,
                              child: child,
                            );
                          } else {
                            return FractionalTranslation(
                              translation:
                                  Offset(-_offsetAnimation.value.dx, 0.0),
                              child: child,
                            );
                          }
                        },
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _sizeAnimation.value,
                              child: child,
                            );
                          },
                          child: Draggable(
                            child: Visibility(
                              visible: !_isBallDraged,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    right: _isPositionOnRight ? 0 : null,
                                    left: !_isPositionOnRight ? 0 : null,
                                    child: MouseRegion(
                                      cursor:
                                          MaterialStateMouseCursor.clickable,
                                      child: GestureDetector(
                                        child: widget.ball,
                                        onTap: !_isBallHide
                                            ? () {
                                                widget.onTap();
                                              }
                                            : null,
                                      ),
                                    ),
                                  ),
                                  if (widget.withIcon)
                                    Align(
                                      alignment: _iconAlignment(),
                                      child: GestureDetector(
                                        onTap: () {
                                          if (widget.onIconBallTapped != null) {
                                            widget
                                                .onIconBallTapped!(_controller);
                                          } else {
                                            _onHideOrShowBall();
                                          }
                                        },
                                        behavior: HitTestBehavior.translucent,
                                        child: MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: AnimatedBuilder(
                                            animation:
                                                _rotateIconAnimationController,
                                            builder: (context, icon) {
                                              return Transform.rotate(
                                                angle: widget.rotateIcon
                                                    ? _rotateIconAnimation.value
                                                    : 0.0,
                                                child: icon,
                                              );
                                            },
                                            child: widget.icon ??
                                                DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: theme.primaryColor,
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(3),
                                                    child: Icon(
                                                      Icons
                                                          .navigate_before_rounded,
                                                      size: widget.iconSize,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            feedback: widget.ball,
                            onDragStarted: () => _onDragStarted(),
                            onDragEnd: (details) => _onDragEnd(details, size),
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
