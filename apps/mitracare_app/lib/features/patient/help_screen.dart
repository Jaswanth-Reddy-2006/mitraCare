import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_system.dart';
import '../../services/api_service.dart';
import 'package:mitracare_app/widgets/patient_bottom_nav_bar.dart';
import 'package:mitracare_app/services/localization_service.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final textScale = MediaQuery.of(context).textScaleFactor;
    final lang = ref.watch(languageProvider);
    
    final patientProfile = authState.userDetails?['patient_profile'];
    final emergencyName = patientProfile?['emergency_contact_name'] ?? 'Caregiver';
    final emergencyPhone = patientProfile?['emergency_contact_phone'] ?? 'None Configured';

    return Scaffold(
      backgroundColor: DesignSystem.backgroundLight,
      appBar: AppBar(
        title: Text(
          LocalizationService.translate('help', lang),
          style: TextStyle(
            color: DesignSystem.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 22.0 * textScale,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignSystem.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.red.shade400,
                        size: 80 * textScale,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      LocalizationService.translate('here_for_you', lang),
                      style: TextStyle(
                        fontSize: 24 * textScale,
                        fontWeight: FontWeight.bold,
                        color: DesignSystem.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      LocalizationService.translate('tap_below', lang),
                      style: TextStyle(
                        fontSize: 16 * textScale,
                        color: DesignSystem.textSubtle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Connect Button (Light green background)
                  _buildHelpButton(
                    context: context,
                    icon: Icons.qr_code,
                    title: "Connect to Caregiver",
                    subtitle: "Show connection QR or code",
                    cardBgColor: const Color(0xFFE8F5E9),
                    borderColor: const Color(0xFFC8E6C9),
                    iconColor: Colors.white,
                    iconBgColor: DesignSystem.primaryGreen,
                    titleColor: const Color(0xFF1B5E20),
                    subtitleColor: const Color(0xFF2E7D32),
                    arrowColor: const Color(0xFF1B5E20),
                    onTap: () => context.push('/patient/my-id'),
                    textScale: textScale,
                  ),
                  const SizedBox(height: 16),

                  // Call Caregiver Button (Light pink background)
                  _buildHelpButton(
                    context: context,
                    icon: Icons.phone,
                    title: LocalizationService.translate('call_caregiver', lang),
                    subtitle: LocalizationService.translate('talk_caregiver', lang),
                    cardBgColor: const Color(0xFFFFEBEE),
                    borderColor: const Color(0xFFFFCDD2),
                    iconColor: Colors.white,
                    iconBgColor: const Color(0xFFEF5350),
                    titleColor: const Color(0xFFC62828),
                    subtitleColor: const Color(0xFFE53935),
                    arrowColor: const Color(0xFFC62828),
                    onTap: () => _callCaregiver(context, emergencyName, emergencyPhone, textScale, lang),
                    textScale: textScale,
                  ),
                  const SizedBox(height: 16),

                  // Voice Help Button (Light orange background)
                  _buildHelpButton(
                    context: context,
                    icon: Icons.mic,
                    title: LocalizationService.translate('voice_help', lang),
                    subtitle: LocalizationService.translate('tell_need', lang),
                    cardBgColor: const Color(0xFFFFF3E0),
                    borderColor: const Color(0xFFFFE0B2),
                    iconColor: Colors.white,
                    iconBgColor: const Color(0xFFFF7043),
                    titleColor: const Color(0xFFD84315),
                    subtitleColor: const Color(0xFFF4511E),
                    arrowColor: const Color(0xFFD84315),
                    onTap: () => _triggerVoiceHelp(context),
                    textScale: textScale,
                  ),
                  const SizedBox(height: 36),

                  // Emergency Warn Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade800, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            LocalizationService.translate('emergency_warning', lang),
                            style: TextStyle(
                              fontSize: 14 * textScale,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PatientBottomNavBar(currentTab: 'help'),
    );
  }

  Widget _buildHelpButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color cardBgColor,
    required Color borderColor,
    required Color iconColor,
    required Color iconBgColor,
    required Color titleColor,
    required Color subtitleColor,
    required Color arrowColor,
    required VoidCallback onTap,
    required double textScale,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: DesignSystem.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 30 * textScale),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20 * textScale,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 15 * textScale,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: arrowColor,
                  size: 20 * textScale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _callCaregiver(BuildContext context, String name, String phone, double textScale, String lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("${LocalizationService.translate('calling', lang)} $name"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Phone Number: $phone"),
            const SizedBox(height: 16),
            const Center(
              child: Icon(Icons.phone_in_talk, size: 64, color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.translate('cancel', lang)),
          )
        ],
      ),
    );
  }

  void _triggerVoiceHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => const VoiceAssistantSheet(),
    );
  }
}
