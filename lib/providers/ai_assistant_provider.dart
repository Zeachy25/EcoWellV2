import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_message.dart';

class AiAssistantState {
  final List<AiMessage> messages;
  final bool isThinking;
  final List<String> quickPrompts;

  const AiAssistantState({
    required this.messages,
    this.isThinking = false,
    required this.quickPrompts,
  });

  AiAssistantState copyWith({
    List<AiMessage>? messages,
    bool? isThinking,
    List<String>? quickPrompts,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      quickPrompts: quickPrompts ?? this.quickPrompts,
    );
  }
}

class AiAssistantNotifier extends Notifier<AiAssistantState> {
  @override
  AiAssistantState build() {
    return AiAssistantState(
      messages: [
        AiMessage(
          id: 'welcome-msg',
          text: 'Hello Arlene! 🌿 I am your EcoWell Wellness Companion. How is your mind feeling today? I can help you find a calm green space in Mati City or guide you through a quick mindful breathing session.',
          isUser: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          suggestions: [
            'Suggest a quiet green space nearby',
            'I am feeling stressed today',
            'Guide me through Box Breathing',
            'How does Quiet Score work?',
          ],
        ),
      ],
      quickPrompts: [
        'Suggest a quiet green space nearby',
        'I am feeling stressed today',
        'Guide me through Box Breathing',
        'How does Quiet Score work?',
      ],
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = AiMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isThinking: true,
    );

    await Future.delayed(const Duration(milliseconds: 1200));

    String botResponse = _generateWellnessResponse(text);

    final botMsg = AiMessage(
      id: 'msg-bot-${DateTime.now().millisecondsSinceEpoch}',
      text: botResponse,
      isUser: false,
      timestamp: DateTime.now(),
      suggestions: [
        'Find nature spots',
        'Start 4-7-8 Breathing',
        'Check today\'s weather',
      ],
    );

    state = state.copyWith(
      messages: [...state.messages, botMsg],
      isThinking: false,
    );
  }

  String _generateWellnessResponse(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('quiet') || lower.contains('space') || lower.contains('spot') || lower.contains('place')) {
      return 'Based on current community ratings, Guang-guang Mangrove Park has a high Quiet Score of 4.8 / 5 with very low crowd density right now. Dahican Beach is also wonderful for an open coastal walk!';
    } else if (lower.contains('stress') || lower.contains('anxious') || lower.contains('tired') || lower.contains('overwhelm')) {
      return 'I hear you. Taking 10 minutes in natural surroundings combined with slow rhythmic breathing can lower cortisol levels significantly. Would you like to try our 4-7-8 Breathing or 5-4-3-2-1 Grounding exercise?';
    } else if (lower.contains('breath') || lower.contains('box')) {
      return 'Box Breathing (4s Inhale, 4s Hold, 4s Exhale, 4s Hold) is great for resetting your autonomic nervous system. You can launch it directly from the Guided Activities section!';
    } else if (lower.contains('quiet score') || lower.contains('score')) {
      return 'The Quiet Score is a 1–5 community perception metric evaluating noise levels, crowd density, and natural calming factors. Places above 4.0 are optimal for mindfulness meditation.';
    } else {
      return 'Nature has a profound way of restoring our mental clarity. Taking even a brief 15-minute nature walk in Mati City today can boost your Stress Reduction Score. How else can I assist your wellness journey?';
    }
  }
}

final aiAssistantProvider = NotifierProvider<AiAssistantNotifier, AiAssistantState>(
  AiAssistantNotifier.new,
);
