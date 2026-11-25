import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../domain/models.dart';
import 'config_generator.dart';

Uint8List linuxWorldBundle(
  ServerProfile profile,
  String installer,
  String setup,
) {
  final generator = ClusterConfigGenerator();
  final entries = {
    for (final e in generator.generate(profile).entries)
      '${profile.id}/${e.key}': e.value,
    'cluster-id': profile.id,
    'install-dst-server.sh': installer,
    'configure-world.sh': setup,
    'workshop-setup.lua': generator.workshopSetup(profile.mods),
  };
  final archive = Archive();
  for (final e in entries.entries) {
    final bytes = utf8.encode(e.value);
    archive.addFile(ArchiveFile(e.key, bytes.length, bytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}
