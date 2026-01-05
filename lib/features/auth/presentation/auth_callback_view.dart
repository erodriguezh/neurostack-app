import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/features/auth/presentation/widgets/auth_background.dart';

class AuthCallbackView extends StatelessWidget {
  const AuthCallbackView({super.key, required this.routeData});

  final RouteData routeData;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final textTheme = context.theme.textTheme;
    final spacing = context.spacing;

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      kitColors.brandSky,
                    ),
                  ),
                  SizedBox(height: spacing.lg),
                  Text(
                    'Finishing sign-in...',
                    style: textTheme.bodyMedium?.copyWith(
                      color: kitColors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
