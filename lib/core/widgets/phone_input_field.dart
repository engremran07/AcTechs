import 'package:flutter/material.dart';
import 'package:ac_techs/core/models/country_dial_code.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

/// Full-featured phone input with country code picker.
/// [onChanged] is called with the E.164 value (digits only, no '+').
/// Default country is KSA (Saudi Arabia).
///
/// Usage:
///   PhoneInputField(
///     initialValue: user.phone,
///     onChanged: (e164) => _phoneValue = e164,
///   )
class PhoneInputField extends StatefulWidget {
  const PhoneInputField({
    super.key,
    this.initialValue,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.defaultCountry = CountryDialCode.ksa,
    this.optional = true,
    this.autofocus = false,
  });

  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? labelText;
  final String? hintText;
  final CountryDialCode defaultCountry;
  final bool optional;
  final bool autofocus;

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late CountryDialCode _country;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _country = widget.defaultCountry;
    final raw = widget.initialValue ?? '';
    if (raw.isNotEmpty) {
      // Try to detect country from stored E.164
      final cleaned = raw.replaceAll(RegExp(r'[\s\-\(\)\+]+'), '');
      CountryDialCode? detected;
      for (final len in [3, 2, 1]) {
        if (cleaned.length < len) continue;
        final prefix = cleaned.substring(0, len);
        final found = CountryDialCode.all.where((c) => c.dialCode == prefix);
        if (found.isNotEmpty) {
          detected = found.first;
          break;
        }
      }
      if (detected != null) {
        _country = detected;
        _ctrl = TextEditingController(
          text: cleaned.substring(detected.dialCode.length),
        );
      } else {
        _ctrl = TextEditingController(text: raw);
      }
    } else {
      _ctrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _e164 {
    final local = _ctrl.text.trim().replaceAll(RegExp(r'[\s\-\(\)\.]+'), '');
    if (local.isEmpty) return '';
    // Strip leading zero if present
    final stripped = local.startsWith('0') ? local.substring(1) : local;
    return '${_country.dialCode}$stripped';
  }

  void _notifyChanged() {
    widget.onChanged?.call(_e164);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Country code button ──────────────────────────────────────────
        Semantics(
          label:
              '${l.selectCountryCode}: ${_country.name} ${_country.prefixLabel}',
          button: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showCountryPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_country.flag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 4),
                  Text(
                    _country.prefixLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down_rounded, size: 18),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // ── Local number input ───────────────────────────────────────────
        Expanded(
          child: TextFormField(
            controller: _ctrl,
            autofocus: widget.autofocus,
            keyboardType: TextInputType.phone,
            onChanged: (_) => _notifyChanged(),
            decoration: InputDecoration(
              labelText: widget.labelText ?? l.phone,
              hintText:
                  widget.hintText ?? _country.localPattern ?? l.phoneLocalHint,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            validator: widget.optional
                ? null
                : (v) {
                    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 6) return l.invalidPhone;
                    return null;
                  },
          ),
        ),
      ],
    );
  }

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet<CountryDialCode>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CountryPickerSheet(
        selected: _country,
        onSelected: (c) {
          setState(() => _country = c);
          _notifyChanged();
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Country picker bottom sheet
// ---------------------------------------------------------------------------

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.selected, required this.onSelected});

  final CountryDialCode selected;
  final ValueChanged<CountryDialCode> onSelected;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _query = '';
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchCtrl.text.length),
      );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CountryDialCode> get _filtered {
    if (_query.isEmpty) return CountryDialCode.all;
    final q = _query.toLowerCase();
    return CountryDialCode.all
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.dialCode.contains(q) ||
              c.isoCode.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final filtered = _filtered;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              l.selectCountryCode,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l.search,
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final c = filtered[i];
                final isSelected = c == widget.selected;
                return ListTile(
                  dense: true,
                  selected: isSelected,
                  leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                  title: Text(c.name),
                  trailing: Text(
                    c.prefixLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => widget.onSelected(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
