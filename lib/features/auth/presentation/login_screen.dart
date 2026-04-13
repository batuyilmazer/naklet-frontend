import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/validation_failure.dart';
import '../../../routing/route_paths.dart';
import '../../../theme/extensions/theme_context_extensions.dart';
import '../../../ui/atoms/app_text.dart';
import '../../../ui/cat_theme/cat_theme.dart';
import '../../../ui/organisms/auth_form.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

/// Login screen for user authentication.
///
/// Uses [AuthForm] component and [AuthNotifier] for state management.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _emailError;
  String? _passwordError;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kulubeye Gir'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.landing),
        ),
      ),
      body: SafeArea(
        child: Consumer<AuthNotifier>(
          builder: (context, authNotifier, child) {
            final state = authNotifier.state;

            // Handle error state
            if (state is AuthErrorState) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showErrorSnackBar(context, state.message);
                authNotifier.clearError();
              });
            }

            // Navigate on successful login
            if (state is AuthenticatedState) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Navigation will be handled by routing layer
                // For now, just clear errors
                _emailError = null;
                _passwordError = null;
              });
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(spacing.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: spacing.s24),
                  Container(
                    padding: EdgeInsets.all(spacing.s24),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.headline(
                          CatThemeCopy.appName,
                          color: colors.primary,
                        ),
                        SizedBox(height: spacing.s8),
                        AppText.bodySmall(
                          'Mahalle hesabinla giris yap ve kendi pati profillerini yonet.',
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: spacing.s24),
                  AuthForm(
                    onSubmit: (email, password) async {
                      _emailError = null;
                      _passwordError = null;
                      await authNotifier.login(
                        email: email,
                        password: password,
                      );

                      // Check for field-level validation errors if present.
                      final state = authNotifier.state;
                      if (state is AuthErrorState &&
                          state.failure is ValidationFailure) {
                        final failure = state.failure as ValidationFailure;
                        _applyFieldErrors(failure);
                      } else if (state is AuthErrorState) {
                        // Fallback to simple parsing for non-validation failures.
                        _parseError(state.message);
                      }
                    },
                    submitLabel: 'Kulubeye Gir',
                    emailLabel: 'Email',
                    passwordLabel: 'Şifre',
                    emailHint: 'Mahalle hesabinizin emaili',
                    passwordHint: 'Gizli miyav sifreniz',
                    isLoading: state is AuthLoadingState,
                    emailError: _emailError,
                    passwordError: _passwordError,
                  ),
                  SizedBox(height: spacing.s24),
                  TextButton(
                    onPressed: () {
                      _showInfoSnackBar(
                        context,
                        'Mama kabi sifirlama ekrani yakinda gelecek.',
                      );
                    },
                    child: AppText.caption(
                      'Mama Kabini Unuttum',
                      color: colors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.landing),
                    child: AppText.caption(
                      'Landing ekranina don',
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _parseError(String message) {
    // Simple error parsing - can be enhanced based on backend error format
    if (message.toLowerCase().contains('email')) {
      _emailError = message;
    } else if (message.toLowerCase().contains('password')) {
      _passwordError = message;
    }
    setState(() {});
  }

  void _applyFieldErrors(ValidationFailure failure) {
    final emailErrors = failure.fieldErrors['email'];
    final passwordErrors = failure.fieldErrors['password'];

    _emailError = (emailErrors != null && emailErrors.isNotEmpty)
        ? emailErrors.first
        : null;
    _passwordError = (passwordErrors != null && passwordErrors.isNotEmpty)
        ? passwordErrors.first
        : null;

    setState(() {});
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    final colors = context.appColors;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText.bodySmall(message),
        backgroundColor: colors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(BuildContext context, String message) {
    final colors = context.appColors;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText.bodySmall(message),
        backgroundColor: colors.textSecondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
