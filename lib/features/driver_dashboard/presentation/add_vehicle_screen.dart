import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/driver/vehicle_type.dart';
import '../../../theme/extensions/theme_context_extensions.dart';
import '../../../ui/atoms/app_button.dart';
import '../../../ui/atoms/app_text.dart';
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

  VehicleType _selectedType = VehicleType.KAMYONET;
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
        type: _selectedType.name,
        plateNumber: _plateController.text.trim(),
        capacityKg: int.parse(_capacityController.text.trim()),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Araç başarıyla eklendi!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Araç eklenirken bir hata oluştu.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Araç Ekle'),
      ),
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
              // Vehicle type dropdown
              AppText.bodySmall('Araç Tipi *', color: colors.textPrimary),
              SizedBox(height: spacing.s8),
              DropdownButtonFormField<VehicleType>(
                initialValue: _selectedType,
                decoration: InputDecoration(
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
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
              SizedBox(height: spacing.s16),
              LabeledTextField(
                label: 'Plaka',
                controller: _plateController,
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
                controller: _capacityController,
                hint: '1500',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                isRequired: true,
                prefixIcon: const Icon(Icons.scale_outlined),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Kapasite gerekli';
                  final kg = int.tryParse(value);
                  if (kg == null || kg <= 0) return 'Geçerli kapasite girin';
                  return null;
                },
              ),
              SizedBox(height: spacing.s24),
              AppButton(
                label: 'Araç Ekle',
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
