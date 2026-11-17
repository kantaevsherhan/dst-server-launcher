import 'package:dio/dio.dart';

import '../domain/models.dart';
import '../domain/services.dart';

class SteamWorkshopRepository implements WorkshopRepository {
  SteamWorkshopRepository({Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 20),
            ),
          );
  final Dio dio;
  static String parseId(String input) {
    final raw = input.trim();
    if (RegExp(r'^[1-9][0-9]{0,19}$').hasMatch(raw)) return raw;
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'steamcommunity.com' ||
        ![
          '/sharedfiles/filedetails/',
          '/sharedfiles/filedetails',
        ].contains(uri.path)) {
      throw const FormatException('Use a Steam Workshop URL or numeric ID');
    }
    final id = uri.queryParameters['id'] ?? '';
    if (!RegExp(r'^[1-9][0-9]{0,19}$').hasMatch(id)) {
      throw const FormatException('Invalid Workshop ID');
    }
    return id;
  }

  Future<List<ModSpec>> _details(List<String> ids) async {
    final r = await dio.post(
      'https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/',
      data: {
        'itemcount': ids.length,
        for (var i = 0; i < ids.length; i++) 'publishedfileids[$i]': ids[i],
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final details = r.data['response']['publishedfiledetails'] as List;
    return details.map((j) {
      if (j['result'] != 1) {
        throw const FormatException('Workshop item unavailable');
      }
      if (j['consumer_app_id'].toString() != '322330') {
        throw const FormatException('This item is not for DST (322330)');
      }
      return ModSpec(
        id: j['publishedfileid'].toString(),
        title: j['title'] ?? j['publishedfileid'].toString(),
        preview: j['preview_url'],
        collection: j['file_type'] == 2,
      );
    }).toList();
  }

  @override
  Future<List<ModSpec>> resolve(String input) async {
    final id = parseId(input);
    final items = await _details([id]);
    if (!items.single.collection) return items;
    final r = await dio.post(
      'https://api.steampowered.com/ISteamRemoteStorage/GetCollectionDetails/v1/',
      data: {'collectioncount': 1, 'publishedfileids[0]': id},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final data = r.data['response']['collectiondetails'][0];
    if (data['result'] != 1) {
      throw const FormatException('Collection is unavailable');
    }
    final children = (data['children'] as List)
        .map((c) => c['publishedfileid'].toString())
        .toList();
    if (children.isEmpty || children.length > 100) {
      throw const FormatException('Collection must contain 1–100 items');
    }
    // Expand explicitly so each shard has actual workshop entries.
    final mods = await _details(children);
    if (mods.any((m) => m.collection)) {
      throw const FormatException('Nested collections are not supported');
    }
    return mods;
  }
}
