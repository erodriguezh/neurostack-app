import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';

/// Forces the subtree to use a dark theme regardless of the system brightness.
///
/// Used for "dark-first" routes (auth, onboarding, offline, paywall, splash)
/// that should always render with a dark appearance.
///
/// Implementation uses [AppTheme.buildTheme] with [Brightness.dark], which
/// returns a complete [ThemeData] with all registered [ThemeExtension]s.
/// This means any new extensions added to [AppTheme.buildTheme] are
/// automatically available inside the scope -- no manual registration needed.
///
/// **Important**: `showModalBottomSheet` / `showDialog` do NOT inherit local
/// [Theme] overrides -- they inherit from the [Navigator]. Modals launched
/// from dark-first routes must wrap their content in [DarkThemeScope]
/// individually.
class DarkThemeScope extends StatelessWidget {
  const DarkThemeScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.buildTheme(Brightness.dark),
      child: child,
    );
  }
}
