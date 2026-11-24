import 'package:dio/dio.dart';

import '../domain/models.dart';
import '../domain/services.dart';

class WorkshopEntry {
  const WorkshopEntry(
    this.mod,
    this.description, {
    this.clientOnly = false,
    this.verified = true,
  });
  final ModSpec mod;
  final String description;
  final bool clientOnly, verified;
  bool get selectable => verified && !clientOnly;
}

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

  Future<List<WorkshopEntry>> browse(String query, int page) async {
    final response = await dio.get<String>(
      'https://steamcommunity.com/workshop/browse/',
      queryParameters: {
        'appid': '322330',
        'section': 'readytouseitems',
        'p': page,
        if (query.trim().isNotEmpty) 'searchtext': query.trim(),
      },
      options: Options(responseType: ResponseType.plain),
    );
    final ids =
        RegExp(
              r'''<a\b[^>]*?\bhref=["'](?:https://steamcommunity\.com)?/sharedfiles/filedetails/\?id=([1-9][0-9]{0,19})(?:[&"'])''',
              caseSensitive: false,
            )
            .allMatches(response.data ?? '')
            .map((m) => m[1]!)
            .toSet()
            .take(50)
            .toList();
    return ids.isEmpty ? [] : _details(ids, skipUnavailable: true);
  }

  Future<List<WorkshopEntry>> subscriptions(List<String> ids) async {
    final entries = <String, WorkshopEntry>{};
    for (var i = 0; i < ids.length; i += 80) {
      final batch = ids.skip(i).take(80).toList();
      try {
        for (final entry in await _details(batch, skipUnavailable: true)) {
          entries[entry.mod.id] = entry;
        }
      } on DioException {
        break; // The local subscription list is still available offline.
      }
    }
    return [
      for (final id in ids)
        entries[id] ??
            WorkshopEntry(
              ModSpec(id: id, title: 'Workshop $id'),
              '',
              verified: false,
            ),
    ];
  }

  Future<WorkshopEntry> detail(String id) async =>
      (await _details([parseId(id)])).single;

  Future<List<WorkshopEntry>> _details(
    List<String> ids, {
    bool skipUnavailable = false,
  }) async {
    final r = await dio.post(
      'https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/',
      data: {
        'itemcount': ids.length,
        for (var i = 0; i < ids.length; i++) 'publishedfileids[$i]': ids[i],
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final details = r.data['response']['publishedfiledetails'] as List;
    final entries = <WorkshopEntry>[];
    for (final j in details) {
      if (skipUnavailable &&
          (j['result'] != 1 ||
              j['consumer_app_id'].toString() != '322330' ||
              j['file_type'] == 2)) {
        continue;
      }
      if (j['result'] != 1) {
        throw const FormatException('Workshop item unavailable');
      }
      if (j['consumer_app_id'].toString() != '322330') {
        throw const FormatException('This item is not for DST (322330)');
      }
      entries.add(
        WorkshopEntry(
          ModSpec(
            id: j['publishedfileid'].toString(),
            title: j['title'] ?? j['publishedfileid'].toString(),
            preview: j['preview_url'],
            collection: j['file_type'] == 2,
          ),
          j['description']?.toString() ?? '',
          clientOnly: (j['tags'] as List? ?? []).any(
            (item) => const {
              'client only',
              'client_only_mod',
              'client-only',
            }.contains(item['tag']?.toString().trim().toLowerCase()),
          ),
        ),
      );
    }
    return entries;
  }

  @override
  Future<List<ModSpec>> resolve(String input) async {
    final id = parseId(input);
    final item = (await detail(id)).mod;
    if (!item.collection) return [item];
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
    final mods = (await _details(children)).map((entry) => entry.mod).toList();
    if (mods.any((m) => m.collection)) {
      throw const FormatException('Nested collections are not supported');
    }
    return mods;
  }
}
