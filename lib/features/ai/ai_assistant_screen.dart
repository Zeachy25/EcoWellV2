import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/ai_message.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../providers/auth_provider.dart';
import '../shared/ecowell_ai_mascot.dart';
import '../shared/ecowell_app_bar.dart';
import '../shared/ecowell_logo.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    ref.read(aiAssistantProvider.notifier).sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final aiState = ref.watch(aiAssistantProvider);
    final userName = user?.name.split(' ').first ?? 'Arlene';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EcoWellAppBar(
        showBack: true,
        showNotifications: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Card matching ai screen.png
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: Responsive.size(context, 16),
                vertical: Responsive.size(context, 4),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.size(context, 16),
                vertical: Responsive.size(context, 12),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Responsive.radius(context, 18)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: Responsive.size(context, 20),
                    backgroundColor: const Color(0xFF889C8E),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                      style: TextStyle(fontSize: Responsive.fontSize(context, 18), color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: Responsive.size(context, 12)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back!',
                        style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: AppColors.textSecondary),
                      ),
                      Text(
                        'Hi, $userName',
                        style: TextStyle(fontSize: Responsive.fontSize(context, 15), fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  EcoWellLeafIcon(size: Responsive.size(context, 32), color: AppColors.mintGreen),
                ],
              ),
            ),

            // Message List / Central Illustration
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.size(context, 16),
                  vertical: Responsive.size(context, 10),
                ),
                children: [
                  // Center Hero Visual matching ai screen.png
                  if (aiState.messages.length <= 1) ...[
                    SizedBox(height: Responsive.size(context, 20)),
                    Center(
                      child: Container(
                        width: Responsive.size(context, 180),
                        height: Responsive.size(context, 180),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.mintLight.withValues(alpha: 0.8),
                          border: Border.all(color: AppColors.mintSoft, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withValues(alpha: 0.12),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: EcoWellAiMascotIcon(
                            size: Responsive.size(context, 90),
                            withShadow: true,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.size(context, 20)),
                    Center(
                      child: Text(
                        'Tell me what\'s on your mind',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, 22),
                          fontWeight: FontWeight.w800,
                          fontFamily: 'serif',
                          color: AppColors.forestDark,
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.size(context, 6)),
                    Center(
                      child: Text(
                        'I\'m here to listen and support you.',
                        style: TextStyle(fontSize: Responsive.fontSize(context, 14), color: AppColors.textSecondary),
                      ),
                    ),
                    SizedBox(height: Responsive.size(context, 20)),
                  ],

                  // Messages list
                  ...aiState.messages.map((msg) => _buildMessageBubble(context, msg)),

                  if (aiState.isThinking)
                    Padding(
                      padding: EdgeInsets.only(
                        left: Responsive.size(context, 8),
                        bottom: Responsive.size(context, 12),
                      ),
                      child: Row(
                        children: [
                          EcoWellAiMascotIcon(
                            size: Responsive.size(context, 26),
                          ),
                          SizedBox(width: Responsive.size(context, 8)),
                          Text(
                            'EcoWell AI is thinking...',
                            style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: AppColors.textTertiary, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),

                  // Quick prompt chips
                  if (aiState.quickPrompts.isNotEmpty) ...[
                    SizedBox(height: Responsive.size(context, 12)),
                    Wrap(
                      spacing: Responsive.size(context, 8),
                      runSpacing: Responsive.size(context, 8),
                      children: aiState.quickPrompts.map((prompt) {
                        return GestureDetector(
                          onTap: () => _send(prompt),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.size(context, 14),
                              vertical: Responsive.size(context, 8),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(Responsive.radius(context, 20)),
                              border: Border.all(color: AppColors.inputBorder),
                            ),
                            child: Text(
                              prompt,
                              style: TextStyle(fontSize: Responsive.fontSize(context, 12), fontWeight: FontWeight.w600, color: AppColors.forestDark),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Medical disclaimer notice
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.size(context, 16),
                vertical: Responsive.size(context, 4),
              ),
              child: Text(
                'EcoWell AI provides general wellness support and is not a medical professional.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: Responsive.fontSize(context, 10), color: AppColors.textTertiary),
              ),
            ),

            // Bottom Input Bar matching ai screen.png
            Container(
              padding: EdgeInsets.fromLTRB(
                Responsive.size(context, 16),
                Responsive.size(context, 8),
                Responsive.size(context, 16),
                Responsive.size(context, 16),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
                ],
              ),
              child: Row(
                children: [
                  // Voice waveform / mic button
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Voice input ready. Speak now...')),
                      );
                    },
                    child: Container(
                      width: Responsive.size(context, 44),
                      height: Responsive.size(context, 44),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF48CAE4), Color(0xFF0096C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(Icons.graphic_eq_rounded, color: Colors.white, size: Responsive.size(context, 22)),
                    ),
                  ),
                  SizedBox(width: Responsive.size(context, 10)),

                  // Pill Text Field
                  Expanded(
                    child: Container(
                      height: Responsive.size(context, 44),
                      padding: EdgeInsets.symmetric(horizontal: Responsive.size(context, 16)),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(Responsive.radius(context, 22)),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: TextField(
                        controller: _textController,
                        onSubmitted: _send,
                        decoration: InputDecoration(
                          hintText: 'Share what\'s on your mind...',
                          hintStyle: TextStyle(fontSize: Responsive.fontSize(context, 13), color: AppColors.textTertiary),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.size(context, 10)),

                  // Send button (Teal paper plane)
                  GestureDetector(
                    onTap: () => _send(_textController.text),
                    child: Container(
                      width: Responsive.size(context, 44),
                      height: Responsive.size(context, 44),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.emerald,
                      ),
                      child: Icon(Icons.send_rounded, color: Colors.white, size: Responsive.size(context, 20)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, AiMessage msg) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.size(context, 14)),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            EcoWellAiMascotIcon(
              size: Responsive.size(context, 26),
            ),
            SizedBox(width: Responsive.size(context, 8)),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.size(context, 16),
                vertical: Responsive.size(context, 12),
              ),
              decoration: BoxDecoration(
                color: msg.isUser ? AppColors.forestMid : Colors.white,
                borderRadius: BorderRadius.circular(Responsive.radius(context, 18)).copyWith(
                  bottomLeft: msg.isUser
                      ? Radius.circular(Responsive.radius(context, 18))
                      : Radius.circular(Responsive.radius(context, 4)),
                  bottomRight: msg.isUser
                      ? Radius.circular(Responsive.radius(context, 4))
                      : Radius.circular(Responsive.radius(context, 18)),
                ),
                border: Border.all(
                  color: msg.isUser ? Colors.transparent : AppColors.cardBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 14),
                  color: msg.isUser ? Colors.white : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (msg.isUser) SizedBox(width: Responsive.size(context, 8)),
        ],
      ),
    );
  }
}