import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/ai_provider.dart';
import '../theme.dart';
import '../widgets.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await context.read<AiProvider>().sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    final ai = context.watch<AiProvider>();
    final messages = ai.messages;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text('Nutrition assistant')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  NVSpace.x5,
                  NVSpace.x4,
                  NVSpace.x5,
                  NVSpace.x4,
                ),
                children: [
                  NVCard(
                    padding: const EdgeInsets.all(NVSpace.x4),
                    child: Text(
                      'Estimates only. Not medical advice.',
                      style: TextStyle(color: c.textMuted, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: NVSpace.x4),
                  if (messages.isEmpty)
                    _PromptPills(
                      onPick: (value) {
                        _controller.text = value;
                        _send();
                      },
                    )
                  else
                    ...messages.map(
                      (message) => _MessageBubble(
                        mine: message.role == 'user',
                        text: message.content,
                      ),
                    ),
                  if (ai.isChatting)
                    const Padding(
                      padding: EdgeInsets.only(top: NVSpace.x3),
                      child: NVSkeleton(height: 48, radius: 18),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                NVSpace.x4,
                NVSpace.x3,
                NVSpace.x4,
                NVSpace.x3,
              ),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Ask about this meal',
                      ),
                    ),
                  ),
                  const SizedBox(width: NVSpace.x2),
                  NVCircleIconButton(
                    icon: Icons.send_rounded,
                    background: NV.accent,
                    foreground: Colors.white,
                    onTap: ai.isChatting ? null : _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptPills extends StatelessWidget {
  const _PromptPills({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final prompts = const [
      'How much protein is here?',
      'What should I edit before saving?',
      'What can I replace for more iron?',
    ];
    return Wrap(
      spacing: NVSpace.x2,
      runSpacing: NVSpace.x2,
      children: prompts
          .map(
            (prompt) => ActionChip(
              label: Text(prompt),
              onPressed: () => onPick(prompt),
            ),
          )
          .toList(),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.mine, required this.text});

  final bool mine;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = NVColors.of(context);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: NVSpace.x3),
        padding: const EdgeInsets.all(NVSpace.x4),
        decoration: BoxDecoration(
          color: mine ? NV.accent : c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: mine ? NV.accent : c.border),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: mine ? Colors.white : c.text,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}
