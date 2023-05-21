import 'dart:ui';
import 'package:anicross/media/anime_videos.dart';
import 'package:anicross/media/manga_reader.dart';
import 'package:anicross/models/color_schemes.g.dart';
import 'package:anicross/later_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:isar/isar.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'media/media.dart';
import 'models/info_models.dart';
import 'novel/novel.dart';
import 'info_page.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellkey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

void main() async {
  int index = 0;
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  Isar.openSync(
    [AniDataSchema, MediaProvSchema],
    name: "later",
    directory: (await Directory(
                '${(await getApplicationDocumentsDirectory()).path}/.anicross')
            .create())
        .path,
  );
  runApp(
    MaterialApp.router(
      theme: ThemeData(
        dividerTheme: const DividerThemeData(
          color: Colors.transparent,
        ),
        colorScheme: darkColorScheme,
        useMaterial3: true,
        chipTheme: const ChipThemeData(
          showCheckmark: false,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: GoRouter(
        navigatorKey: _rootKey,
        initialLocation: '/media/anime',
        routes: [
          ShellRoute(
            navigatorKey: _shellkey,
            builder: (context, state, child) => Scaffold(
              body: child,
              bottomNavigationBar: SizedBox(
                width: clampDouble(MediaQuery.of(context).size.width, 0, 384),
                child: BottomNavigationBar(
                  useLegacyColorScheme: false,
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  currentIndex: index,
                  onTap: (value) {
                    switch (value) {
                      case 0:
                        {
                          index = 0;
                          context.go('/media/anime');
                        }
                      case 1:
                        {
                          index = 1;
                          context.go('/media/manga');
                        }
                      case 2:
                        {
                          index = 2;
                          context.go('/novel');
                        }
                      case 3:
                        {
                          index = 3;
                          context.go('/later');
                        }
                    }
                  },
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(MdiIcons.youtubeTv),
                      label: 'Anime',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(MdiIcons.bookOpenOutline),
                      label: 'Manga',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(MdiIcons.book),
                      label: 'Novels',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(MdiIcons.bookmark),
                      label: 'Later',
                    )
                  ],
                ),
              ),
            ),
            routes: [
              GoRoute(
                parentNavigatorKey: _shellkey,
                path: '/media/:type',
                builder: (context, state) {
                  index = (state.pathParameters['type']! == 'anime') ? 0 : 1;
                  return AniPage(
                    key: UniqueKey(),
                    type: state.pathParameters['type']!,
                    tag: state.extra as String?,
                  );
                },
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootKey,
                    path: 'info',
                    builder: (context, state) {
                      print(state.pathParameters['type']);
                      return InfoPage(
                        data: state.extra as AniData,
                      );
                    },
                    routes: [
                      GoRoute(
                          parentNavigatorKey: _rootKey,
                          path: 'viewer',
                          builder: (context, state) {
                            print(state.location);
                            return switch (state.location) {
                              '/media/anime/info/viewer' => AniViewer(
                                  episodes: (state.extra as Map)['contents'],
                                  episode: (state.extra as Map)['content'],
                                ),
                              '/media/manga/info/viewer' => MangaReader(
                                  chapter: (state.extra as Map)['content'],
                                  chapters: (state.extra as Map)['contents'],
                                ),
                              _ => Placeholder(),
                            };
                          }),
                    ],
                  ),
                ],
              ),
              GoRoute(
                name: 'novel',
                path: '/novel',
                builder: (context, state) {
                  return const NovelPage();
                },
              ),
              GoRoute(
                name: 'later',
                path: '/later',
                builder: (context, state) {
                  return const LaterPage();
                },
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootKey,
                    path: 'info',
                    builder: (context, state) {
                      index =
                          ((state.extra as AniData).type == 'anime') ? 0 : 1;
                      return InfoPage(
                        data: state.extra as AniData,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
