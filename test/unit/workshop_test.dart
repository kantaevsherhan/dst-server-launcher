import 'package:dio/dio.dart';
import 'package:dst_server_launcher/data/workshop_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Collection resolves both child mods using offline Valve responses',
    () async {
      final dio = Dio();
      final calls = <String>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final id = options.data['publishedfileids[0]'] as String;
            calls.add(id);
            final collection = options.path.contains('GetCollectionDetails');
            final response = collection
                ? {
                    'collectiondetails': [
                      {
                        'result': 1,
                        'children': [
                          {'publishedfileid': '101'},
                          {'publishedfileid': '102'},
                        ],
                      },
                    ],
                  }
                : {
                    'publishedfiledetails': [
                      for (final value
                          in id == '100' ? ['100'] : ['101', '102'])
                        {
                          'result': 1,
                          'consumer_app_id': 322330,
                          'publishedfileid': value,
                          'file_type': value == '100' ? 2 : 0,
                          'title': 'Mod $value',
                        },
                    ],
                  };
            handler.resolve(
              Response(requestOptions: options, data: {'response': response}),
            );
          },
        ),
      );
      final mods = await SteamWorkshopRepository(dio: dio).resolve('100');
      expect(calls, ['100', '100', '101']);
      expect(mods.map((m) => m.id), ['101', '102']);
      expect(mods.every((m) => m.master && m.caves && !m.collection), isTrue);
    },
  );

  test('Subscription titles are verified and missing or client-only entries cannot be added', () async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'response': {
                    'publishedfiledetails': [
                      {
                        'result': 1,
                        'consumer_app_id': 322330,
                        'publishedfileid': '12',
                        'title': 'Example',
                      },
                      {
                        'result': 1,
                        'consumer_app_id': 322330,
                        'publishedfileid': '13',
                        'title': 'HUD',
                        'tags': [
                          {'tag': 'client_only_mod'},
                        ],
                      },
                      {'result': 9, 'publishedfileid': '14'},
                    ],
                  },
                },
              ),
            );
          },
        ),
      );
    final items = await SteamWorkshopRepository(dio: dio)
        .subscriptions(['13', '14', '12']);
    expect(items.map((e) => e.mod.title), ['HUD', 'Workshop 14', 'Example']);
    expect(items.map((e) => e.selectable), [false, false, true]);
  });

  test('Wrong game is rejected before adding the item', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'response': {
                  'publishedfiledetails': [
                    {'result': 1, 'consumer_app_id': 123},
                  ],
                },
              },
            ),
          );
        },
      ),
    );
    await expectLater(
      SteamWorkshopRepository(dio: dio).resolve('101'),
      throwsFormatException,
    );
  });
}
