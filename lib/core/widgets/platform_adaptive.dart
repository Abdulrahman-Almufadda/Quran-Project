import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Small helpers to choose platform-native navigation bars and dialogs.
/// Keep these helpers minimal and reversible; they return widgets suitable
/// for assigning to `Scaffold.appBar` (as a `PreferredSizeWidget`).

PreferredSizeWidget platformAppBar({
  required BuildContext context,
  required Widget title,
  Widget? leading,
  List<Widget>? actions,
  Color? backgroundColor,
}) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    final trailing = (actions != null && actions.isNotEmpty)
        ? Row(mainAxisSize: MainAxisSize.min, children: actions)
        : null;
    return PreferredSize(
      preferredSize: const Size.fromHeight(44.0),
      child: CupertinoNavigationBar(
        middle: title,
        leading: leading,
        trailing: trailing,
        backgroundColor: backgroundColor ?? CupertinoTheme.of(context).barBackgroundColor,
      ),
    );
  }

  return AppBar(
    title: title,
    leading: leading,
    actions: actions,
    backgroundColor: backgroundColor,
  );
}

/// Lightweight platform dialog wrapper. It simply chooses the correct
/// show*Dialog implementation; the caller still provides a dialog widget
/// appropriate for the platform (or a Material one which also renders on iOS).
Future<T?> showPlatformDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return showCupertinoDialog<T>(context: context, builder: builder);
  }
  return showDialog<T>(context: context, builder: builder);
}

/// Returns a platform-appropriate PageRoute: `CupertinoPageRoute` on iOS to
/// enable native back-swipe and transitions, and `MaterialPageRoute` elsewhere.
Route<T> platformPageRoute<T>({required WidgetBuilder builder, RouteSettings? settings}) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPageRoute<T>(builder: builder, settings: settings);
  }
  return MaterialPageRoute<T>(builder: builder, settings: settings);
}

/// Show an action sheet on iOS or a bottom sheet on other platforms.
Future<T?> showPlatformActionSheet<T>({required BuildContext context, required WidgetBuilder builder}) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return showCupertinoModalPopup<T>(context: context, builder: builder);
  }
  return showModalBottomSheet<T>(context: context, builder: builder);
}
