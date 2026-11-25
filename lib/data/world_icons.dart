import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

typedef SettingsIcons = Map<String, Uint8List>;
final _cache = <String, Future<SettingsIcons>>{};

Future<SettingsIcons> worldIcons(String? install) => install == null
    ? Future.value({})
    : _cache.putIfAbsent(install, () => Isolate.run(() => readIcons(install)));

/// Decode only the small (32px per icon) BC3 mip from the local Klei atlas.
SettingsIcons readIcons(String install) {
  final icons = <String, Uint8List>{};
  for (final family in ['worldgen', 'worldsettings']) {
    final stem = path.join(
      install,
      'data',
      'images',
      '${family}_customization',
    );
    try {
      final tex = File('$stem.tex');
      final xml = File('$stem.xml');
      if (!tex.existsSync() ||
          !xml.existsSync() ||
          tex.lengthSync() > 32 * 1024 * 1024) {
        continue;
      }
      final bytes = tex.readAsBytesSync(), b = ByteData.sublistView(bytes);
      if (b.getUint32(0) != 0x4b544558) continue;
      final header = b.getUint32(4, Endian.little),
          levels = (header >> 13) & 31;
      if (((header >> 4) & 31) != 2 || levels < 3) continue;
      int offset = 8 + levels * 10;
      for (int i = 0; i < 2; i++) {
        offset += b.getUint32(14 + i * 10, Endian.little);
      }
      final width = b.getUint16(28, Endian.little),
          height = b.getUint16(30, Endian.little);
      if (width < 4 ||
          height < 4 ||
          width % 4 != 0 ||
          height % 4 != 0 ||
          offset + width * height > bytes.length) {
        continue;
      }
      final atlas = img.Image(width: width, height: height, numChannels: 4);
      for (int y = 0; y < height; y += 4) {
        for (int x = 0; x < width; x += 4) {
          final a0 = bytes[offset], a1 = bytes[offset + 1], alpha = [a0, a1];
          if (a0 > a1) {
            for (int k = 1; k <= 6; k++) {
              alpha.add(((7 - k) * a0 + k * a1) ~/ 7);
            }
          } else {
            for (int k = 1; k <= 4; k++) {
              alpha.add(((5 - k) * a0 + k * a1) ~/ 5);
            }
            alpha.addAll([0, 255]);
          }
          int abits = 0;
          for (int k = 0; k < 6; k++) {
            abits |= bytes[offset + 2 + k] << (8 * k);
          }
          List<int> rgb(int c) => [
            ((c >> 11) & 31) * 255 ~/ 31,
            ((c >> 5) & 63) * 255 ~/ 63,
            (c & 31) * 255 ~/ 31,
          ];
          final c0 = rgb(b.getUint16(offset + 8, Endian.little)),
              c1 = rgb(b.getUint16(offset + 10, Endian.little));
          final palette = [
            c0,
            c1,
            for (final weight in [2, 1])
              [
                for (int ch = 0; ch < 3; ch++)
                  (weight * c0[ch] + (3 - weight) * c1[ch]) ~/ 3,
              ],
          ];
          final cbits = b.getUint32(offset + 12, Endian.little);
          for (int i = 0; i < 16; i++) {
            final color = palette[(cbits >> (2 * i)) & 3],
                a = alpha[(abits >> (3 * i)) & 7];
            atlas.setPixelRgba(
              x + i % 4,
              height - 1 - y - i ~/ 4,
              color[0],
              color[1],
              color[2],
              a,
            );
          }
          offset += 16;
        }
      }
      for (final m in RegExp(
        r'<Element name="([^"]+)" u1="([\d.]+)" u2="([\d.]+)" v1="([\d.]+)" v2="([\d.]+)"',
      ).allMatches(xml.readAsStringSync())) {
        final x = (double.parse(m[2]!) * width).floor(),
            right = (double.parse(m[3]!) * width).ceil();
        final y = ((1 - double.parse(m[5]!)) * height).floor(),
            bottom = ((1 - double.parse(m[4]!)) * height).ceil();
        if (x < 0 ||
            y < 0 ||
            right > width ||
            bottom > height ||
            x >= right ||
            y >= bottom) {
          continue;
        }
        icons['$family/${m[1]}'] = img.encodePng(
          img.copyCrop(atlas, x: x, y: y, width: right - x, height: bottom - y),
          level: 1,
        );
      }
    } on FileSystemException {
      continue;
    } on RangeError {
      continue;
    }
  }
  return icons;
}
