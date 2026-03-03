import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/result.dart';
import '../../../core/models/driver/vehicle_type.dart';
import '../../../theme/extensions/theme_context_extensions.dart';
import '../../../ui/atoms/app_button.dart';
import '../../../ui/atoms/app_text.dart';
import '../../../ui/molecules/labeled_text_field.dart';
import '../../../features/auth/presentation/auth_notifier.dart';
import '../data/driver_register_repository.dart';
import '../../../routing/route_paths.dart';

/// Multi-step driver registration screen.
///
/// Steps:
/// 1. Account info (email, password)
/// 2. Profile info (firstName, lastName, phoneNumber)
/// 3. Vehicle info (at least 1 vehicle required)
class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  String? _error;

  // Step 1 — Account
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Step 2 — Profile
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Step 3 — Vehicles
  final List<_VehicleEntry> _vehicles = [_VehicleEntry()];

  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  final _repository = DriverRegisterRepository();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    for (final v in _vehicles) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKeys[2].currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final vehicles = _vehicles
        .map((v) => {
              'type': v.type.name,
              'plateNumber': v.plateController.text.trim(),
              'capacityKg': int.tryParse(v.capacityController.text.trim()) ?? 0,
            })
        .toList();

    final result = await _repository.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      vehicles: vehicles,
    );

    if (!mounted) return;

    result.when(
      success: (user) {
        // Login the user in the auth notifier
        final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
        authNotifier.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        // Navigate to home
        context.go(AppRoutes.home);
      },
      failure: (failure) {
        setState(() {
          _isLoading = false;
          _error = failure.message;
        });
      },
    );
  }

  void _onStepContinue() {
    if (_formKeys[_currentStep].currentState!.validate()) {
      if (_currentStep < 2) {
        setState(() => _currentStep += 1);
      } else {
        _handleSubmit();
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  void _addVehicle() {
    setState(() => _vehicles.add(_VehicleEntry()));
  }

  void _removeVehicle(int index) {
    if (_vehicles.length > 1) {
      setState(() {
        _vehicles[index].dispose();
        _vehicles.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sürücü Kaydı'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(spacing.s12),
              margin: EdgeInsets.symmetric(
                horizontal: spacing.s16,
                vertical: spacing.s8,
              ),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colors.error, size: 20),
                  SizedBox(width: spacing.s8),
                  Expanded(
                    child: AppText.bodySmall(_error!, color: colors.error),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: _isLoading ? null : _onStepContinue,
              onStepCancel: _isLoading ? null : _onStepCancel,
              controlsBuilder: (context, details) {
                return Padding(
                  padding: EdgeInsets.only(top: spacing.s16),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: _currentStep == 2 ? 'Kayıt Ol' : 'Devam',
                          onPressed: _isLoading ? null : details.onStepContinue,
                          isLoading: _isLoading && _currentStep == 2,
                          isFullWidth: true,
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        SizedBox(width: spacing.s12),
                        Expanded(
                          child: AppButton(
                            label: 'Geri',
                            onPressed: details.onStepCancel,
                            variant: AppButtonVariant.outline,
                            isFullWidth: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Hesap Bilgileri'),
                  subtitle: const Text('Email ve şifre'),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0
                      ? StepState.complete
                      : StepState.indexed,
                  content: _buildAccountStep(),
                ),
                Step(
                  title: const Text('Profil Bilgileri'),
                  subtitle: const Text('Ad, soyad, telefon'),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1
                      ? StepState.complete
                      : StepState.indexed,
                  content: _buildProfileStep(),
                ),
                Step(
                  title: const Text('Araç Bilgileri'),
                  subtitle: const Text('En az 1 araç gerekli'),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2
                      ? StepState.complete
                      : StepState.indexed,
                  content: _buildVehicleStep(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStep() {
    final spacing = context.appSpacing;

    return Form(
      key: _formKeys[0],
      child: Column(
        children: [
          LabeledTextField(
            label: 'Email',
            controller: _emailController,
            hint: 'ornek@email.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            isRequired: true,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email gerekli';
              if (!value.contains('@') || !value.contains('.')) {
                return 'Geçerli bir email girin';
              }
              return null;
            },
          ),
          SizedBox(height: spacing.s16),
          LabeledTextField(
            label: 'Şifre',
            controller: _passwordController,
            hint: 'En az 6 karakter',
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            isRequired: true,
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Şifre gerekli';
              if (value.length < 6) return 'Şifre en az 6 karakter olmalı';
              return null;
            },
          ),
          SizedBox(height: spacing.s16),
          LabeledTextField(
            label: 'Şifre Tekrar',
            controller: _confirmPasswordController,
            hint: 'Şifrenizi tekrar girin',
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            isRequired: true,
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre tekrarı gerekli';
              }
              if (value != _passwordController.text) {
                return 'Şifreler eşleşmiyor';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStep() {
    final spacing = context.appSpacing;

    return Form(
      key: _formKeys[1],
      child: Column(
        children: [
          LabeledTextField(
            label: 'Ad',
            controller: _firstNameController,
            hint: 'Adınız',
            textInputAction: TextInputAction.next,
            isRequired: true,
            prefixIcon: const Icon(Icons.person_outline),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ad gerekli';
              return null;
            },
          ),
          SizedBox(height: spacing.s16),
          LabeledTextField(
            label: 'Soyad',
            controller: _lastNameController,
            hint: 'Soyadınız',
            textInputAction: TextInputAction.next,
            isRequired: true,
            prefixIcon: const Icon(Icons.person_outline),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Soyad gerekli';
              return null;
            },
          ),
          SizedBox(height: spacing.s16),
          LabeledTextField(
            label: 'Telefon',
            controller: _phoneController,
            hint: '05XX XXX XX XX',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            isRequired: true,
            prefixIcon: const Icon(Icons.phone_outlined),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Telefon numarası gerekli';
              }
              if (value.length < 10) return 'Geçerli bir telefon girin';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleStep() {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return Form(
      key: _formKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < _vehicles.length; i++) ...[
            if (i > 0) ...[
              SizedBox(height: spacing.s16),
              Divider(color: colors.textSecondary.withValues(alpha: 0.2)),
              SizedBox(height: spacing.s8),
            ],
            _buildVehicleCard(i),
          ],
          SizedBox(height: spacing.s16),
          OutlinedButton.icon(
            onPressed: _addVehicle,
            icon: const Icon(Icons.add),
            label: const Text('Araç Ekle'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: spacing.s12,
                horizontal: spacing.s16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(int index) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final vehicle = _vehicles[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.bodySmall(
              'Araç ${index + 1}',
              color: colors.textPrimary,
            ),
            if (_vehicles.length > 1)
              IconButton(
                onPressed: () => _removeVehicle(index),
                icon: Icon(Icons.close, color: colors.error, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        SizedBox(height: spacing.s8),
        // Vehicle type dropdown
        DropdownButtonFormField<VehicleType>(
          initialValue: vehicle.type,
          decoration: InputDecoration(
            labelText: 'Araç Tipi *',
            prefixIcon: const Icon(Icons.local_shipping_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: VehicleType.values
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => vehicle.type = value);
            }
          },
        ),
        SizedBox(height: spacing.s16),
        LabeledTextField(
          label: 'Plaka',
          controller: vehicle.plateController,
          hint: '34 ABC 123',
          textInputAction: TextInputAction.next,
          isRequired: true,
          prefixIcon: const Icon(Icons.confirmation_number_outlined),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Plaka gerekli';
            return null;
          },
        ),
        SizedBox(height: spacing.s16),
        LabeledTextField(
          label: 'Kapasite (kg)',
          controller: vehicle.capacityController,
          hint: '1500',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          isRequired: true,
          prefixIcon: const Icon(Icons.scale_outlined),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Kapasite gerekli';
            final kg = int.tryParse(value);
            if (kg == null || kg <= 0) return 'Geçerli bir kapasite girin';
            return null;
          },
        ),
      ],
    );
  }
}

/// Internal vehicle entry helper for the stepper form.
class _VehicleEntry {
  VehicleType type = VehicleType.kamyonet;
  final plateController = TextEditingController();
  final capacityController = TextEditingController();

  void dispose() {
    plateController.dispose();
    capacityController.dispose();
  }
}
