import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dst_server_launcher/domain/models.dart';
import 'package:dst_server_launcher/data/config_generator.dart';
import 'package:dst_server_launcher/data/linux_world_bundle.dart';
import 'package:dst_server_launcher/data/mod_settings.dart';

import 'config_test.dart' show fixture;

void main() {
  test(
    'Surface and cave settings use their own files; global sync reaches Caves',
    () {
      final p = ServerProfile.fromJson({
        ...fixture().toJson(),
        'surfaceOptions': {'grass': 'often', 'ghostsanitydrain': 'none'},
        'caveOptions': {'grass': 'rare', 'wormattacks': 'often'},
      });
      final files = ClusterConfigGenerator().generate(p);
      expect(files['Master/worldgenoverride.lua'], contains('grass = "often"'));
      expect(
        files['Master/worldgenoverride.lua'],
        isNot(contains('wormattacks')),
      );
      expect(files['Caves/worldgenoverride.lua'], contains('grass = "rare"'));
      expect(
        files['Caves/worldgenoverride.lua'],
        contains('ghostsanitydrain = "none"'),
      );
      expect(
        files['Caves/worldgenoverride.lua'],
        contains('wormattacks = "often"'),
      );
      expect(
        () => ServerProfile.fromJson({
          ...p.toJson(),
          'surfaceOptions': {'wormattacks': 'often'},
        }).validate(),
        throwsFormatException,
      );
    },
  );
  test('Typed Workshop options are read as data and survive shard toggles', () {
    final options = parseModOptions('''
local switches = { {description="Off",data=false}, {description="On",data=true} }
configuration_options = {
 {name="show", label="Show", options=switches, default=false},
 {name="count", options={{description="Two",data=2}},default=2},
 {name="dynamic",options=make_options()}
}''');
    expect(options.map((o) => o.key), ['show', 'count']);
    expect(options.first.choices[false], 'Off');
    final m = ModSpec(id: '12', title: 'Example')
        .configured({'show': false, 'count': 2, 'text': 'A"B'})
        .enabled(caves: false);
    final p = fixture(mods: [m]);
    final restore = ServerProfile.fromJson(p.toJson());
    final files = ClusterConfigGenerator().generate(restore);
    expect(files['Master/modoverrides.lua'], contains('["show"] = false'));
    expect(files['Master/modoverrides.lua'], contains('["count"] = 2'));
    expect(files['Master/modoverrides.lua'], contains(r'["text"] = "A\"B"'));
    expect(files['Caves/modoverrides.lua'], isNot(contains('workshop-12')));
  });
  test('Headless ZIP contains independent cluster config and setup, token entered on host', () {
    final p = fixture();
    final archive = ZipDecoder().decodeBytes(
      linuxWorldBundle(p, 'installer', 'setup'),
    );
    expect(archive.findFile('cluster-id')!.content, utf8.encode(p.id));
    expect(archive.findFile('${p.id}/Caves/worldgenoverride.lua'), isNotNull);
    expect(archive.findFile('configure-world.sh'), isNotNull);
    expect(archive.files.any((f) => f.name.contains('token')), isFalse);
  });
}
