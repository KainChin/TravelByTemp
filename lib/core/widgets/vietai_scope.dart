import 'package:flutter/material.dart';
import 'package:assignment/services/app_session.dart';

class VietaiScope extends InheritedNotifier<AppSession> {
  const VietaiScope({
    super.key,
    required AppSession session,
    required super.child,
  }) : super(notifier: session);

  static AppSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<VietaiScope>();
    assert(scope != null, 'VietaiScope not found');
    return scope!.notifier!;
  }
}
