import 'dart:convert';
import 'dart:io';

void main() {
  final data = {
    for (final locale in ['ru', 'en'])
      locale: jsonDecode(File('l10n/app_$locale.arb').readAsStringSync()),
  };
  File('lib/app/catalogs.dart').writeAsStringSync(
    '// Generated from l10n/*.arb by scripts/generate_l10n.dart.\nconst catalogs = <String, Map<String, String>>${jsonEncode(data).replaceAll(r'$', r'\$')};\n',
  );
}
