import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nuxtray/vpn_provider.dart';
import 'package:nuxtray/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showAddServerDialog(BuildContext context, VpnProvider vpn) {
    final theme = Theme.of(context);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Icon(Icons.add_link, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Новая подписка'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Введите ссылку на подписку или конфигурацию:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'vless://... или https://...',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.content_paste_go),
                    tooltip: 'Вставить из буфера',
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        controller.text = data!.text!;
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton.tonal(
            onPressed: () async {
              final input = controller.text.trim();
              if (input.isNotEmpty) {
                final success = await vpn.addSubscription(input);
                if (success) {
                  if (context.mounted) Navigator.pop(context);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ошибка при добавлении подписки. Проверьте ссылку.')),
                    );
                  }
                }
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vpn = Provider.of<VpnProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddServerDialog(context, vpn),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ConnectionStatusCircle(vpn: vpn),
            const SizedBox(height: 32),
            if (vpn.selectedServer != null) ...[
              Text(
                vpn.selectedServer!.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatItem(
                    icon: Icons.arrow_downward_rounded,
                    value: vpn.downSpeed,
                    label: 'ВХОД',
                    color: Colors.greenAccent,
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _StatItem(
                    icon: Icons.arrow_upward_rounded,
                    value: vpn.upSpeed,
                    label: 'ИСХОД',
                    color: Colors.blueAccent,
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _StatItem(
                    icon: Icons.speed_rounded,
                    value: '${vpn.selectedServer!.ping} ms',
                    label: 'ПИНГ',
                    color: Colors.orangeAccent,
                  ),
                ],
              ),
            ] else if (vpn.servers.isNotEmpty) ...[
               Text(
                'Выберите сервер',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              Text(
                'Нет подписок',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConnectionStatusCircle extends StatelessWidget {
  final VpnProvider vpn;
  const _ConnectionStatusCircle({required this.vpn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConnected = vpn.status == VpnStatus.connected;
    final isConnecting = vpn.status == VpnStatus.connecting;

    return Center(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          vpn.toggleConnection();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected 
                ? theme.colorScheme.primary 
                : theme.colorScheme.primary.withAlpha(35),
            boxShadow: isConnected ? [
              BoxShadow(
                color: theme.colorScheme.primary.withAlpha(100),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ] : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.power_settings_new,
                size: 72,
                color: isConnected ? theme.colorScheme.onPrimary : theme.colorScheme.primary.withAlpha(180),
              ),
              if (isConnected) ...[
                const SizedBox(height: 12),
                Text(
                  _formatDuration(vpn.connectionDuration),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
