/// InheritedNotifier exposing the [ProfileService] to all screens.
library;

import 'package:flutter/widgets.dart';
import '../services/profile_service.dart';
export '../services/profile_service.dart';

class ProfileScope extends InheritedNotifier<ProfileService> {
  const ProfileScope({
    super.key,
    required ProfileService profile,
    required super.child,
  }) : super(notifier: profile);

  static ProfileService of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ProfileScope>();
    assert(scope != null, 'ProfileScope not found in widget tree');
    return scope!.notifier!;
  }
}
