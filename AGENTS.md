# Nuxtray

Flutter VPN client using V2Ray/Xray protocol. UI defaults to Russian, supports en.

## Commands

- `flutter run` — run on connected device/emulator
- `flutter analyze` — static analysis (uses `flutter_lints` defaults, no custom rules)
- `flutter test` — run tests (stub test at `test/widget_test.dart` references counter UI not in this app; will fail)
- `flutter build apk` / `flutter build ios` / `flutter build windows` / etc

## Architecture

- **Entrypoint:** `lib/main.dart` → `NuxtrayApp`
- **State:** single `VpnProvider` (`ChangeNotifier`) via `provider` package, holds all server state, settings, and VPN control
- **Screens:** `lib/screens/` — `HomeScreen`, `ServerListScreen`, `SettingsScreen`, `SplitTunnelingScreen`, `DomainRoutingScreen`
- **Navigation:** `MainNavigation` with `IndexedStack` + pill-style bottom nav (2 tabs: Home, Servers). Settings and sub-screens pushed via `Navigator.push`

## Key details

- Server configs and settings persist to `servers.json` in the app documents directory
- Subscription input accepts URLs (`https://...`) or direct config links (`vless://`, `vmess://`, `ss://`, `trojan://`, `hysteria2://`, `hy2://`, `wireguard://`)
- Hardcoded servers are commented out in `VpnProvider` — servers must be added via subscription
- Split tunneling uses `device_apps`/`installed_apps` packages (Android focused)
- `flutter_v2ray_plus` handles VPN connection; on Android it requests VPN permission via `requestPermission()`
- **No CI**, **no opencode.json**, **no GitHub Actions** configured
- Supports Android, iOS, Windows, macOS, Linux, web
