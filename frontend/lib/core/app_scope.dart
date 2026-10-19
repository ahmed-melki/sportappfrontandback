import 'package:flutter/widgets.dart';

import 'api/app_repositories.dart';

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.repositories, required super.child});
  final AppRepositories repositories;
  static AppRepositories? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()?.repositories;
  static AppRepositories of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    if (scope == null) {
      throw FlutterError('AppScope.of() called with a context that does not contain an AppScope.');
    }
    return scope.repositories;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => repositories != oldWidget.repositories;
}
