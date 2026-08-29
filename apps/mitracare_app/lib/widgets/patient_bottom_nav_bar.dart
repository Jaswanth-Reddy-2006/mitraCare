import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mitracare_app/core/theme/design_system.dart';
import 'package:mitracare_app/services/localization_service.dart';
import 'package:mitracare_app/services/api_service.dart';

class PatientBottomNavBar extends ConsumerWidget {
  final String currentTab;

  const PatientBottomNavBar({
    super.key,
    required this.currentTab,
  });

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double textScale = MediaQuery.of(context).textScaleFactor;
    final lang = ref.watch(languageProvider);
    final isHome = currentTab == 'home';
    final isHelp = currentTab == 'help';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Home Tab
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!isHome) {
                    context.go('/patient-home');
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isHome ? Icons.home : Icons.home_outlined,
                      color: isHome ? DesignSystem.primaryGreen : Colors.grey.shade600,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      LocalizationService.translate('home', lang),
                      style: TextStyle(
                        fontSize: 14 * textScale,
                        fontWeight: isHome ? FontWeight.bold : FontWeight.normal,
                        color: isHome ? DesignSystem.primaryGreen : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Large Microphone Action
            GestureDetector(
              onTap: () => _triggerVoiceHelp(context),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: DesignSystem.primaryGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: DesignSystem.primaryGreen.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),

            // Help Tab
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!isHelp) {
                    context.go('/patient/help');
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isHelp ? Icons.favorite : Icons.favorite_border,
                      color: isHelp ? const Color(0xFFD32F2F) : Colors.grey.shade600,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      LocalizationService.translate('help', lang),
                      style: TextStyle(
                        fontSize: 14 * textScale,
                        fontWeight: isHelp ? FontWeight.bold : FontWeight.normal,
                        color: isHelp ? const Color(0xFFD32F2F) : Colors.grey.shade600,
                      ),
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
}

class VoiceAssistantSheet extends ConsumerStatefulWidget {
  const VoiceAssistantSheet({super.key});

  @override
  ConsumerState<VoiceAssistantSheet> createState() => _VoiceAssistantSheetState();
}

class _VoiceAssistantSheetState extends ConsumerState<VoiceAssistantSheet> with SingleTickerProviderStateMixin {
  String _assistantText = "";
  String _userText = "";
  bool _isListening = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    // Auto start listening after greeting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = ref.read(languageProvider);
      final authState = ref.read(authProvider);
      final patientName = authState.name ?? LocalizationService.translate('default_name', lang);
      
      setState(() {
        _assistantText = "Hello, $patientName! ${LocalizationService.translate('here_to_help', lang)}";
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _assistantText = LocalizationService.translate('listening', lang);
            _isListening = true;
          });
          
          // Simulate speech recognition results
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              String simulatedUserText = "";
              String simulatedAssistantReply = "";
              
              switch (lang) {
                case 'hi':
                  simulatedUserText = "मेरे अनुस्मारक दिखाएं";
                  simulatedAssistantReply = "आपके अनुस्मारक खोल रहा हूँ, $patientName!";
                  break;
                case 'as':
                  simulatedUserText = "মোৰ স্মাৰকবোৰ দেখুওৱা";
                  simulatedAssistantReply = "আপোনাৰ স্মাৰকসমূহ খুলিছো, $patientName!";
                  break;
                case 'bn':
                  simulatedUserText = "আমার রিমাইন্ডারগুলি দেখান";
                  simulatedAssistantReply = "আপনার রিমাইন্ডারগুলি খুলছি, $patientName!";
                  break;
                case 'mni':
                  simulatedUserText = "ঐহাক্কী নিংসিংহনবা থৌরাং উহনউ";
                  simulatedAssistantReply = "নহাক্কী নিংসিংহনবা থৌরাং থোউরে, $patientName!";
                  break;
                case 'brx':
                  simulatedUserText = "आंनि गोसोखां होनायफोरखौ दिनथि";
                  simulatedAssistantReply = "नोंथांनि गोसोखां होनायफोरखौ खेवगासिनो, $patientName!";
                  break;
                case 'mzo':
                  simulatedUserText = "Ka hriattirna te min hmuh rawh";
                  simulatedAssistantReply = "I hriattirna te ka hawng e, $patientName!";
                  break;
                case 'kha':
                  simulatedUserText = "Pyni ia ki jingpynkynmaw jong nga";
                  simulatedAssistantReply = "Pynplie ia ki jingpynkynmaw jong phi, $patientName!";
                  break;
                case 'grt':
                  simulatedUserText = "Ang·ni gisik ra·atgiparangko mesokbo";
                  simulatedAssistantReply = "Nang·ni gisik ra·atgiparangko oenga, $patientName!";
                  break;
                default:
                  simulatedUserText = "Show me my reminders";
                  simulatedAssistantReply = "Opening your reminders, $patientName!";
              }

              setState(() {
                _isListening = false;
                _userText = simulatedUserText;
                _assistantText = simulatedAssistantReply;
              });
              
              // Execute command & close sheet
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  Navigator.pop(context);
                  context.go('/patient/reminders');
                }
              });
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double textScale = MediaQuery.of(context).textScaleFactor;
    final lang = ref.watch(languageProvider);

    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            LocalizationService.translate('mitracare', lang) + " " + LocalizationService.translate('voice_help', lang),
            style: TextStyle(
              fontSize: 22 * textScale,
              fontWeight: FontWeight.bold,
              color: DesignSystem.textDark,
            ),
          ),
          const SizedBox(height: 32),
          
          // Pulsing microphone icon
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignSystem.primaryGreen.withOpacity(0.1),
                  border: Border.all(
                    color: DesignSystem.primaryGreen.withOpacity(
                      _isListening ? 0.6 * _pulseController.value : 0.2,
                    ),
                    width: _isListening ? 12 * _pulseController.value : 4,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: DesignSystem.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          
          Text(
            _assistantText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20 * textScale,
              fontWeight: FontWeight.w600,
              color: DesignSystem.primaryGreen,
            ),
          ),
          if (_userText.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '"$_userText"',
                style: TextStyle(
                  fontSize: 18 * textScale,
                  fontStyle: FontStyle.italic,
                  color: DesignSystem.textDark,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
