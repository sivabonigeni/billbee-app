import 'package:flutter/material.dart';
import '../../models/business_profile.dart';
import '../../widgets/profile_info_tile.dart';

class SettingsTab extends StatefulWidget {
  final BusinessProfile profile;
  final Future<void> Function(BusinessProfile) onSave;
  const SettingsTab({super.key, required this.profile, required this.onSave});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late final TextEditingController _businessNameController;
  late final TextEditingController _ownerNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _gstinController;
  late final TextEditingController _upiController;
  late final TextEditingController _addressController;
  late final TextEditingController _paymentInstructionsController;
  late final TextEditingController _footerNoteController;
  late final TextEditingController _brandColorController;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.profile.businessName);
    _ownerNameController = TextEditingController(text: widget.profile.ownerName);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _gstinController = TextEditingController(text: widget.profile.gstin);
    _upiController = TextEditingController(text: widget.profile.upiId);
    _addressController = TextEditingController(text: widget.profile.address);
    _paymentInstructionsController = TextEditingController(text: widget.profile.paymentInstructions);
    _footerNoteController = TextEditingController(text: widget.profile.footerNote);
    _brandColorController = TextEditingController(text: widget.profile.brandColorHex);
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _upiController.dispose();
    _addressController.dispose();
    _paymentInstructionsController.dispose();
    _footerNoteController.dispose();
    _brandColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.black12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(int.parse(profile.brandColorHex.replaceFirst('#', '0xFF'))).withOpacity(0.1),
                  child: Text(
                    (profile.businessName.isNotEmpty ? profile.businessName : 'B').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(int.parse(profile.brandColorHex.replaceFirst('#', '0xFF'))),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  profile.businessName.isNotEmpty ? profile.businessName : 'Set Business Name',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                if (profile.ownerName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(profile.ownerName, style: const TextStyle(color: Colors.black54, fontSize: 16)),
                ],
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                ProfileInfoTile(icon: Icons.phone_outlined, label: 'Phone', value: profile.phone.isNotEmpty ? profile.phone : 'Not set'),
                ProfileInfoTile(icon: Icons.branding_watermark_outlined, label: 'GSTIN', value: profile.gstin.isNotEmpty ? profile.gstin : 'Not set'),
                ProfileInfoTile(icon: Icons.account_balance_wallet_outlined, label: 'UPI ID', value: profile.upiId.isNotEmpty ? profile.upiId : 'Not set'),
                ProfileInfoTile(icon: Icons.location_on_outlined, label: 'Address', value: profile.address.isNotEmpty ? profile.address : 'Not set'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _showEditSheet,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Business Info'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text('Edit Business', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(controller: _businessNameController, decoration: const InputDecoration(labelText: 'Business Name', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _ownerNameController, decoration: const InputDecoration(labelText: 'Owner Name', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _gstinController, decoration: const InputDecoration(labelText: 'GSTIN', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _upiController, decoration: const InputDecoration(labelText: 'UPI ID', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _addressController, maxLines: 3, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _paymentInstructionsController, maxLines: 2, decoration: const InputDecoration(labelText: 'Payment Instructions', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _footerNoteController, maxLines: 2, decoration: const InputDecoration(labelText: 'Footer Note', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _brandColorController, decoration: const InputDecoration(labelText: 'Brand Color Hex', hintText: '#1A73E8', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    _save();
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final hex = _brandColorController.text.trim();
    final validHex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$').hasMatch(hex) ? hex : '#1A73E8';
    widget.onSave(
      BusinessProfile(
        businessName: _businessNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        phone: _phoneController.text.trim(),
        gstin: _gstinController.text.trim(),
        upiId: _upiController.text.trim(),
        address: _addressController.text.trim(),
        paymentInstructions: _paymentInstructionsController.text.trim(),
        footerNote: _footerNoteController.text.trim(),
        brandColorHex: validHex,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings updated')));
  }
}
