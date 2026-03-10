import 'dart:convert';
import 'dart:io';

Future<String> getPlatformDeviceId() async {
  try {
    if (Platform.isMacOS) {
      final result = await Process.run(
        'ioreg',
        ['-rd1', '-c', 'IOPlatformExpertDevice'],
      );
      final output = (result.stdout ?? '').toString();
      final match = RegExp(r'"IOPlatformUUID"\s*=\s*"([^"]+)"').firstMatch(output);
      if (match != null) {
        return match.group(1)!;
      }
    }

    if (Platform.isLinux) {
      final file = File('/etc/machine-id');
      if (await file.exists()) {
        final id = (await file.readAsString()).trim();
        if (id.isNotEmpty) {
          return id;
        }
      }
    }

    if (Platform.isWindows) {
      final result = await Process.run(
        'powershell',
        [
          '-Command',
          'Get-CimInstance -ClassName Win32_ComputerSystemProduct | Select-Object -ExpandProperty UUID'
        ],
        runInShell: true,
      );
      final uuid = (result.stdout ?? '').toString().trim();
      if (uuid.isNotEmpty && !uuid.toUpperCase().startsWith('FFFFFFFF')) {
        return uuid;
      }
    }
  } catch (_) {}

  final fallbackRaw = '${Platform.operatingSystem}-${Platform.localHostname}-${Platform.operatingSystemVersion}';
  return base64Url.encode(utf8.encode(fallbackRaw));
}
