import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _telegramLink = 'https://t.me/InvisibleShrimpBot?start=ref_uZG5CQP0DP';

class ShrimpAd extends StatelessWidget {
  const ShrimpAd({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.tertiaryContainer.withValues(alpha: 0.3),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: cs.tertiary.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 20, color: cs.tertiary),
                const SizedBox(width: 8),
                Text(
                  'Invisible Shrimp',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: cs.onTertiaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте премиум-сервис Invisible Shrimp —'
              ' быстрые серверы по всему миру, стабильное подключение и низкий пинг даже при отключениях интернета.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onTertiaryContainer.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Подписаться в Telegram'),
              onPressed: () async {
                final uri = Uri.parse(_telegramLink);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   SnackBar(content: Text('Не удалось открыть: $_telegramLink')),
                    // );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
