import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Lets mouse drag (not just touch) pan scrollables — Flutter's default
/// [MaterialScrollBehavior] omits [PointerDeviceKind.mouse], so horizontal
/// lists like the dashboard's lesson carousel look static on web/desktop.
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
