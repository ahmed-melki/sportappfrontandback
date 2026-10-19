import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/app_scope.dart';
import '../../core/currency_formatter.dart';
import '../../data/mock_shop.dart';
import '../../data/shop_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.cart, required this.onOrderCreated});

  final CartData cart;
  final void Function(ShopOrder order) onOrderCreated;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _complementCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<String> _governorates = kFallbackGovernorates;
  String? _selectedGov;
  bool _loading = false;
  bool _loadingGov = true;
  Map<String, List<String>> _fieldErrors = {};

  ShopRepository get _repo => AppScope.of(context).shop;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGovernorates());
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _complementCtrl.dispose();
    _cityCtrl.dispose();
    _postalCodeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGovernorates() async {
    try {
      final list = await _repo.getGovernorates();
      if (mounted && list.isNotEmpty) {
        setState(() {
          _governorates = list;
          _loadingGov = false;
        });
        return;
      }
    } catch (_) {
      // fallback
    }
    if (mounted) setState(() => _loadingGov = false);
  }

  String? _fieldError(String key) {
    final camelErrors = _fieldErrors[key];
    if (camelErrors != null && camelErrors.isNotEmpty) return camelErrors.first;
    final snakeKey = key.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');
    final snakeErrors = _fieldErrors[snakeKey];
    if (snakeErrors != null && snakeErrors.isNotEmpty) return snakeErrors.first;
    return null;
  }

  Future<void> _submit() async {
    _fieldErrors = {};
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    try {
      final data = <String, dynamic>{
        'fullName': _fullNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().replaceAll(RegExp(r'[\s\-]+'), ''),
        'addressLine1': _addressCtrl.text.trim(),
        'addressLine2': _complementCtrl.text.trim().isEmpty ? null : _complementCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'governorate': _selectedGov ?? '',
        'postalCode': _postalCodeCtrl.text.trim(),
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'paymentMethod': 'cash_on_delivery',
      };
      final order = await _repo.createOrder(data);
      if (mounted) {
        widget.onOrderCreated(order);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commande confirmée · merci pour votre confiance')),
        );
      }
    } on ApiException catch (e) {
      if (e.fieldErrors.isNotEmpty) {
        setState(() {
          _fieldErrors = e.fieldErrors;
          _loading = false;
        });
      } else {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final shippingCost = widget.cart.subtotal >= 250 ? 0.0 : 8.0;
    final total = widget.cart.subtotal + shippingCost;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.md),
              child: Row(
                children: [
                  ApexIconButton(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('COMMANDE', style: text.labelSmall?.copyWith(color: AppColors.coral)),
                        Text('Adresse de livraison', style: text.headlineMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Form ──
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.xxxl),
                  children: [
                    _buildField('Nom complet', _fullNameCtrl, 'fullName', required: true),
                    _buildField('Téléphone', _phoneCtrl, 'phone', required: true, keyboardType: TextInputType.phone,
                      hint: '+216 XX XXX XXX',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Champ requis';
                        final cleaned = v.trim().replaceAll(RegExp(r'[\s\-]+'), '');
                        if (!RegExp(r'^(\+216)?[0-9]{8}$').hasMatch(cleaned)) return '8 chiffres, optionnel +216';
                        return null;
                      },
                    ),
                    _buildField('Adresse', _addressCtrl, 'addressLine1', required: true),
                    _buildField('Complément d\'adresse', _complementCtrl, 'addressLine2'),
                    _buildField('Ville', _cityCtrl, 'city', required: true),
                    // Governorate dropdown
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gouvernorat *', style: text.labelMedium),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedGov,
                            isExpanded: true,
                            decoration: _inputDecoration(hint: _loadingGov ? 'Chargement...' : 'Sélectionner'),
                            dropdownColor: AppColors.surfaceElevated,
                            items: _governorates.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                            onChanged: _loadingGov ? null : (v) => setState(() => _selectedGov = v),
                            validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                          ),
                          if (_fieldError('governorate') != null) ...[
                            const SizedBox(height: 4),
                            Text(_fieldError('governorate')!, style: text.bodySmall?.copyWith(color: AppColors.coral)),
                          ],
                        ],
                      ),
                    ),
                    _buildField('Code postal', _postalCodeCtrl, 'postalCode', required: true, keyboardType: TextInputType.number),
                    _buildField('Notes', _notesCtrl, 'notes', maxLines: 3),

                    const SizedBox(height: AppSpacing.md),
                    // Payment info
                    ApexCard(
                      tone: ApexCardTone.muted,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Icon(Icons.payments_outlined, color: AppColors.mint, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Paiement à la livraison', style: text.titleSmall),
                                const SizedBox(height: 2),
                                Text('Vous payez en espèces à la réception.', style: text.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Summary ──
                    ApexCard(
                      tone: ApexCardTone.muted,
                      child: Column(
                        children: [
                          _SummaryRow(label: 'Sous-total', value: formatDinar(widget.cart.subtotal)),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Livraison',
                            value: shippingCost == 0 ? 'Offerte' : formatDinar(shippingCost),
                            valueColor: AppColors.mint,
                          ),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                          _SummaryRow(label: 'Total', value: formatDinar(total), large: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ApexButton(
                      label: _loading ? 'Envoi en cours…' : 'Confirmer la commande',
                      icon: Icons.lock_outline_rounded,
                      onPressed: _loading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String fieldKey, {
    bool required = false,
    TextInputType? keyboardType,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label${required ? ' *' : ''}', style: text.labelMedium),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: text.bodyLarge,
            decoration: _inputDecoration(hint: hint),
            validator: validator ?? (required ? (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null : null),
          ),
          if (_fieldError(fieldKey) != null) ...[
            const SizedBox(height: 4),
            Text(_fieldError(fieldKey)!, style: text.bodySmall?.copyWith(color: AppColors.coral)),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: AppRadii.mdAll, borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: AppRadii.mdAll, borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: AppRadii.mdAll, borderSide: const BorderSide(color: AppColors.volt)),
    errorBorder: OutlineInputBorder(borderRadius: AppRadii.mdAll, borderSide: const BorderSide(color: AppColors.coral)),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.valueColor, this.large = false});
  final String label;
  final String value;
  final Color? valueColor;
  final bool large;
  @override
  Widget build(BuildContext context) {
    final labelStyle = large ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.bodyMedium;
    final valueStyle = labelStyle?.copyWith(color: valueColor ?? AppColors.textPrimary, fontWeight: large ? FontWeight.w700 : null);
    return Row(children: [Expanded(child: Text(label, style: labelStyle)), Text(value, style: valueStyle)]);
  }
}
