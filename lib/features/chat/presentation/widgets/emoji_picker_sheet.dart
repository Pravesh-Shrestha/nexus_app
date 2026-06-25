import 'package:flutter/material.dart';
import 'package:nexus_app/core/theme/app_colors.dart';

class EmojiPickerSheet extends StatelessWidget {
  final ValueChanged<String> onEmojiSelected;

  const EmojiPickerSheet({
    super.key,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> gamingEmojis = [
      '😂', '👍', '🔥', 'GG', '❤️', '🎮', '😮', '😢', '👑',
      '😎', '👏', '🙌', '💯', '✨', '⚡', '🤖', '💀', '🎉'
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'QUICK EMOJIS',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: gamingEmojis.length,
              itemBuilder: (context, index) {
                final emoji = gamingEmojis[index];
                final isTextEmoji = emoji == 'GG';

                return InkWell(
                  onTap: () {
                    onEmojiSelected(emoji);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isTextEmoji
                        ? const Text(
                            'GG',
                            style: TextStyle(
                              color: AppColors.primaryCyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
