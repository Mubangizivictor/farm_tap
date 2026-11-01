// Whether the app runs in a browser. Web mobile (< 600 dp in a browser)
// shows a hamburger menu instead of the bottom bar (UX_SPEC section 1).
// Defaults to kIsWeb; tests and golden screenshots override it.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class FarmTapPlatform extends InheritedWidget {
  const new({required this.isWeb, required super.child, super.key});

  final bool isWeb;

  static bool isWebOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FarmTapPlatform>()?.isWeb ?? kIsWeb;

  @override
  bool updateShouldNotify(FarmTapPlatform oldWidget) => isWeb != oldWidget.isWeb;
}
