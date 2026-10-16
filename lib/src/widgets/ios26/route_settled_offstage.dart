import 'package:flutter/widgets.dart';

/// Leaves [child] out of the frame while its route moves: while the route
/// slides in or out, while a route above it slides, and during a back swipe.
///
/// For a platform view that draws nothing of its own, such as the
/// transparent touch layer of the widget mode of the iOS 26 popup menu
/// button. The iOS engine gives the Flutter content after each platform view
/// one overlay, the bounding box of all its overlaps with the platform views
/// below it, and clips that box out of the background for every later
/// layer. During a route transition both pages show their platform views, so
/// a box can span plain content, and the content of a later layer inside
/// that box is drawn nowhere: the page slides in with holes
/// (flutter/flutter#166682). Without platform views in the moving frames,
/// the engine does not slice them.
///
/// [Offstage] keeps the native view alive: the engine takes it out of the
/// view tree only while it is not painted, and puts it back on the first
/// frame after the route stops.
class RouteSettledOffstage extends StatefulWidget {
  /// Creates a gate for [child].
  const RouteSettledOffstage({super.key, required this.child});

  /// The platform view to leave out of the moving frames.
  final Widget child;

  @override
  State<RouteSettledOffstage> createState() => _RouteSettledOffstageState();
}

class _RouteSettledOffstageState extends State<RouteSettledOffstage> {
  Animation<double>? _animation;
  Animation<double>? _secondaryAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<Object?>? route = ModalRoute.of(context);
    _watch(route?.animation, route?.secondaryAnimation);
  }

  void _watch(Animation<double>? animation, Animation<double>? secondary) {
    if (animation == _animation && secondary == _secondaryAnimation) return;
    _unwatch();
    _animation = animation?..addStatusListener(_onStatus);
    _secondaryAnimation = secondary?..addStatusListener(_onStatus);
  }

  void _unwatch() {
    _animation?.removeStatusListener(_onStatus);
    _secondaryAnimation?.removeStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) => setState(() {});

  /// The route is fully in, and no route above it moves or covers it.
  bool get _settled =>
      (_animation?.isCompleted ?? true) &&
      (_secondaryAnimation?.isDismissed ?? true);

  @override
  void dispose() {
    _unwatch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Offstage(offstage: !_settled, child: widget.child);
}
