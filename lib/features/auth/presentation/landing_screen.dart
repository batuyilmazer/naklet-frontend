import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/route_paths.dart';
import '../../../theme/extensions/theme_context_extensions.dart';
import '../../../ui/atoms/app_text.dart';
import '../../../ui/cat_theme/cat_theme.dart';
import 'auth_providers.dart';

/// Public landing screen for choosing the primary user journey.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(spacing.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: spacing.s24),
              Container(
                padding: EdgeInsets.all(spacing.s24),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.pets_rounded,
                        size: 42,
                        color: colors.primary,
                      ),
                    ),
                    SizedBox(height: spacing.s16),
                    AppText.headline(
                      CatThemeCopy.appName,
                      textAlign: TextAlign.center,
                      color: colors.primary,
                    ),
                    SizedBox(height: spacing.s8),
                    AppText.bodySmall(
                      CatThemeCopy.appTagline,
                      textAlign: TextAlign.center,
                      color: colors.textSecondary,
                    ),
                    SizedBox(height: spacing.s16),
                    Wrap(
                      spacing: spacing.s8,
                      runSpacing: spacing.s8,
                      alignment: WrapAlignment.center,
                      children: const [
                        _LandingTag(
                          icon: Icons.place_outlined,
                          label: 'Yakinindaki kedileri tara',
                        ),
                        _LandingTag(
                          icon: Icons.favorite_border,
                          label: 'Sevilmeye hazir profiller',
                        ),
                        _LandingTag(
                          icon: Icons.wb_sunny_outlined,
                          label: 'Mahalledeki pati hareketi',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.s32),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.driverRegister),
                icon: const Icon(Icons.pets_outlined),
                label: const Text('Sokak Kedisi Olarak Katil'),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: spacing.s16),
                ),
              ),
              SizedBox(height: spacing.s12),
              OutlinedButton.icon(
                onPressed: () {
                  context.authNotifier.continueAsGuest();
                  context.go(AppRoutes.home);
                },
                icon: const Icon(Icons.travel_explore_outlined),
                label: const Text('Kedi Seven Olarak Devam Et'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: spacing.s16),
                ),
              ),
              SizedBox(height: spacing.s24),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: colors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: spacing.s16),
                    child: AppText.caption('veya', color: colors.textSecondary),
                  ),
                  Expanded(
                    child: Divider(
                      color: colors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing.s16),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: AppText.bodySmall(
                  'Zaten hesabim var, giris yap',
                  color: colors.primary,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandingTag extends StatelessWidget {
  const _LandingTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.s12,
        vertical: spacing.s8,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          SizedBox(width: spacing.s6),
          AppText.caption(label, color: colors.textPrimary),
        ],
      ),
    );
  }
}
