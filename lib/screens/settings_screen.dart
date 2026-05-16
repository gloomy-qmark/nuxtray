import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vpn_provider.dart';
import 'app_routing_screens.dart';
import 'split_tunneling_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnProvider>();
    final settings = vpn.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _SectionHeader(title: 'Подключение'),
          _SettingTile(
            icon: Icons.lan_outlined,
            title: 'Обход локальной сети',
            subtitle: 'Не направлять трафик локальной сети через VPN',
            trailing: Switch(
              value: settings.bypassLan,
              onChanged: (val) {
                vpn.updateSettings(VpnSettings(
                  socksPort: settings.socksPort,
                  httpPort: settings.httpPort,
                  bypassLan: val,
                  themeMode: settings.themeMode,
                  language: settings.language,
                  allowedApps: settings.allowedApps,
                  excludedApps: settings.excludedApps,
                  proxyDomains: settings.proxyDomains,
                  directDomains: settings.directDomains,
                  splitMode: settings.splitMode,
                ));
              },
            ),
          ),
          _SettingTile(
            icon: Icons.numbers,
            title: 'SOCKS Порт',
            subtitle: settings.socksPort.toString(),
            onTap: () => _showPortDialog(context, 'SOCKS Port', settings.socksPort, (val) {
               vpn.updateSettings(VpnSettings(
                  socksPort: val,
                  httpPort: settings.httpPort,
                  bypassLan: settings.bypassLan,
                  themeMode: settings.themeMode,
                  language: settings.language,
                  allowedApps: settings.allowedApps,
                  excludedApps: settings.excludedApps,
                  proxyDomains: settings.proxyDomains,
                directDomains: settings.directDomains,
                splitMode: settings.splitMode,
                ));
            }),
          ),
          _SettingTile(
            icon: Icons.http,
            title: 'HTTP Порт',
            subtitle: settings.httpPort.toString(),
            onTap: () => _showPortDialog(context, 'HTTP Port', settings.httpPort, (val) {
               vpn.updateSettings(VpnSettings(
                  socksPort: settings.socksPort,
                  httpPort: val,
                  bypassLan: settings.bypassLan,
                  themeMode: settings.themeMode,
                  language: settings.language,
                  allowedApps: settings.allowedApps,
                  excludedApps: settings.excludedApps,
                  proxyDomains: settings.proxyDomains,
                directDomains: settings.directDomains,
                splitMode: settings.splitMode,
                ));
            }),
          ),
          _SettingTile(
            icon: Icons.apps,
            title: 'Проксирование приложений',
            subtitle: 'Выбрать приложения для работы через VPN',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SplitTunnelingScreen()),
              );
            },
          ),
          _SettingTile(
            icon: Icons.domain,
            title: 'Маршрутизация доменов',
            subtitle: 'Настройка обхода или проксирования доменов',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DomainRoutingScreen()),
              );
            },
          ),
          const Divider(),
          _SectionHeader(title: 'Приложение'),
          _SettingTile(
            icon: Icons.palette_outlined,
            title: 'Тема оформления',
            subtitle: _getThemeName(settings.themeMode),
            onTap: () => _showThemeDialog(context, vpn),
          ),
          _SettingTile(
            icon: Icons.language,
            title: 'Язык',
            subtitle: settings.language.toUpperCase(),
            onTap: () => _showLanguageDialog(context, vpn),
          ),
          const Divider(),
          _SettingTile(
            icon: Icons.info_outline,
            title: 'О приложении',
            subtitle: 'Nuxtray v1.0.0-alpha',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Nuxtray',
                applicationVersion: '1.0.0-alpha',
                applicationIcon: const FlutterLogo(),
                children: [
                  const Text('Продвинутый клиент для Xray/V2Ray на Flutter.'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _getThemeName(String mode) {
    switch (mode) {
      case 'light': return 'Светлая';
      case 'dark': return 'Темная';
      default: return 'Системная';
    }
  }

  void _showPortDialog(BuildContext context, String title, int currentVal, Function(int) onSave) {
    final controller = TextEditingController(text: currentVal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Порт (1024-65535)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(onPressed: () {
            final val = int.tryParse(controller.text);
            if (val != null && val > 1024 && val < 65535) {
              onSave(val);
              Navigator.pop(context);
            }
          }, child: const Text('Сохранить')),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, VpnProvider vpn) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Выберите тему'),
        children: [
          _ThemeOption(mode: 'system', label: 'Системная', vpn: vpn),
          _ThemeOption(mode: 'light', label: 'Светлая', vpn: vpn),
          _ThemeOption(mode: 'dark', label: 'Темная', vpn: vpn),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, VpnProvider vpn) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Выберите язык'),
        children: [
          _LangOption(code: 'ru', label: 'Русский', vpn: vpn),
          _LangOption(code: 'en', label: 'English', vpn: vpn),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String mode;
  final String label;
  final VpnProvider vpn;
  const _ThemeOption({required this.mode, required this.label, required this.vpn});

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: () {
        final s = vpn.settings;
        vpn.updateSettings(VpnSettings(
          socksPort: s.socksPort,
          httpPort: s.httpPort,
          bypassLan: s.bypassLan,
          themeMode: mode,
          language: s.language,
          allowedApps: s.allowedApps,
          excludedApps: s.excludedApps,
          proxyDomains: s.proxyDomains,
          directDomains: s.directDomains,
          splitMode: s.splitMode,
        ));
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(label),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String code;
  final String label;
  final VpnProvider vpn;
  const _LangOption({required this.code, required this.label, required this.vpn});

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: () {
        final s = vpn.settings;
        vpn.updateSettings(VpnSettings(
          socksPort: s.socksPort,
          httpPort: s.httpPort,
          bypassLan: s.bypassLan,
          themeMode: s.themeMode,
          language: code,
          allowedApps: s.allowedApps,
          excludedApps: s.excludedApps,
          proxyDomains: s.proxyDomains,
          directDomains: s.directDomains,
          splitMode: s.splitMode,
        ));
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(label),
      ),
    );
  }
}
