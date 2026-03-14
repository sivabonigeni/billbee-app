import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/business_profile.dart';

class SettingsTab extends StatefulWidget {
  final BusinessProfile profile;
  final Function(BusinessProfile) onSave;

  const SettingsTab({super.key, required this.profile, required this.onSave});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final List<Color> _brandingColors = [
    const Color(0xFF1E3A8A), // Deep Blue
    const Color(0xFF1A73E8), // Google Blue
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFFEC4899), // Pink
    const Color(0xFFEF4444), // Red
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF10B981), // Emerald
    const Color(0xFF0F172A), // Slate
  ];

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 20),
          _buildBusinessCard(context),
          const SizedBox(height: 24),
          _buildSectionHeader('App Configuration'),
          _buildSettingsTile(
            icon: Icons.palette_outlined,
            title: 'Theme & Branding',
            subtitle: 'Customize your invoice colors and fonts',
            onTap: () => _editBusinessInfo(context), // Primary action for branding
          ),
          _buildSettingsTile(
            icon: Icons.language_rounded,
            title: 'Currency & Locale',
            subtitle: 'Set your default currency and date formats',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Support & Legal'),
          _buildSettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Help Center',
            subtitle: 'Guides and FAQs for using BillBee',
            onTap: () => _launchUrl('https://example.com/help'),
          ),
          _buildSettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Read our usage terms and conditions',
            onTap: () => _launchUrl('https://example.com/terms'),
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data',
            onTap: () => _launchUrl('https://example.com/privacy'),
          ),
          const SizedBox(height: 40),
          const Center(
            child: Text(
              'BillBee v1.0.0 (Build 2026)',
              style: TextStyle(color: Colors.black26, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.blueAccent, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.blue, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black26),
      ),
    );
  }

  Widget _buildBusinessCard(BuildContext context) {
    final Color brandColor = Color(int.parse(widget.profile.brandColorHex.replaceFirst('#', '0xFF')));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [brandColor, const Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: brandColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Icon(Icons.business_center, size: 150, color: Colors.white.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Text('Business Profile', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => _editBusinessInfo(context),
                      icon: const Icon(Icons.edit_rounded, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(widget.profile.businessName.isEmpty ? 'Set Business Name' : widget.profile.businessName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(widget.profile.email.isEmpty ? 'No email set' : widget.profile.email, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildQuickInfo(Icons.phone, widget.profile.phone.isEmpty ? 'No phone' : widget.profile.phone),
                    const SizedBox(width: 24),
                    _buildQuickInfo(Icons.color_lens, widget.profile.brandColorHex),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _editBusinessInfo(BuildContext context) {
    final nameCtrl = TextEditingController(text: widget.profile.businessName);
    final phoneCtrl = TextEditingController(text: widget.profile.phone);
    final emailCtrl = TextEditingController(text: widget.profile.email);
    final addressCtrl = TextEditingController(text: widget.profile.address);
    String selectedHex = widget.profile.brandColorHex;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Edit Business Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildField('Business Name', nameCtrl, Icons.business_rounded),
                _buildField('Phone Number', phoneCtrl, Icons.phone_rounded),
                _buildField('Email Address', emailCtrl, Icons.email_rounded),
                _buildField('Street Address', addressCtrl, Icons.location_on_rounded, maxLines: 2),
                
                const Text('Brand Color', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _brandingColors.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final color = _brandingColors[index];
                      final hex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                      final isSelected = selectedHex == hex;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedHex = hex),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))
                            ],
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      widget.onSave(widget.profile.copyWith(
                        businessName: nameCtrl.text,
                        phone: phoneCtrl.text,
                        email: emailCtrl.text,
                        address: addressCtrl.text,
                        brandColorHex: selectedHex,
                      ));
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
