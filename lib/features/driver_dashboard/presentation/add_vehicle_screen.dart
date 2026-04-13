import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/driver/vehicle_type.dart';
import '../../../core/models/driver/vehicle.dart';
import '../../../theme/extensions/theme_context_extensions.dart';
import '../../../ui/atoms/app_button.dart';
import '../../../ui/atoms/app_text.dart';
import '../../../ui/cat_theme/cat_theme.dart';
import '../../../ui/molecules/labeled_text_field.dart';
import '../data/driver_dashboard_repository.dart';

/// Screen for adding a new vehicle to the driver's fleet.
class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = DriverDashboardRepository();

  VehicleType _selectedType = VehicleType.kamyonet;
  final _plateController = TextEditingController();
  final _capacityController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _plateController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _repository.addVehicle(
        type: _selectedType.apiValue,
        plateNumber: _plateController.text.trim(),
        capacityKg: int.parse(_capacityController.text.trim()),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yeni kedi profili yuvaya eklendi!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Kedi profili eklenirken bir aksilik oldu.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Kedi Profili')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.s16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Container(
                  padding: EdgeInsets.all(spacing.s12),
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
                SizedBox(height: spacing.s16),
              ],
              AppText.bodySmall('Pati karakteri *', color: colors.textPrimary),
              SizedBox(height: spacing.s8),
              DropdownButtonFormField<VehicleType>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.pets_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: VehicleType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
              SizedBox(height: spacing.s16),
              LabeledTextField(
                label: 'Renk / lakap',
                controller: _plateController,
                hint: 'Tekir, duman gri, pasli turuncu...',
                textInputAction: TextInputAction.next,
                isRequired: true,
                prefixIcon: const Icon(Icons.brush_outlined),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Renk veya lakap gerekli';
                  }
                  return null;
                },
              ),
              SizedBox(height: spacing.s16),
              LabeledTextField(
                label: 'Tahmini kilo (kg)',
                controller: _capacityController,
                hint: '4',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                isRequired: true,
                prefixIcon: const Icon(Icons.scale_outlined),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tahmini kilo gerekli';
                  }
                  final kg = int.tryParse(value);
                  if (kg == null || kg <= 0) return 'Gecerli kilo girin';
                  return null;
                },
              ),
              SizedBox(height: spacing.s12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(spacing.s12),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AppText.caption(
                  'Bu profil listede ${CatThemeCopy.vehicleProfile(Vehicle(id: 'preview', type: _selectedType, plateNumber: _plateController.text, capacityKg: int.tryParse(_capacityController.text) ?? 4, driverId: 'preview')).nickname} olarak gorunecek.',
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: spacing.s24),
              AppButton(
                label: 'Profili Yuvaya Ekle',
                onPressed: _isLoading ? null : _handleSubmit,
                isLoading: _isLoading,
                isFullWidth: true,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
