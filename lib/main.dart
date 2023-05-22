import 'dart:ui';
import 'package:anicross/media/anime_videos.dart';
import 'package:anicross/media/manga_reader.dart';
import 'package:anicross/later_page.dart';
import 'package:anicross/novel/novel_reader.dart';
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
        colorScheme: const ColorScheme.dark(),
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
        initialLocation: '/anime',
        routes: [
          ShellRoute(
            navigatorKey: _shellkey,
            builder: (context, state, child) => Scaffold(
              body: child,
              bottomNavigationBar: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width:
                        clampDouble(MediaQuery.of(context).size.width, 0, 384),
                    child: BottomNavigationBar(
                      elevation: 0,
                      useLegacyColorScheme: false,
                      showUnselectedLabels: false,
                      currentIndex: index,
                      onTap: (value) {
                        switch (value) {
                          case 0:
                            {
                              index = 0;
                              context.go('/anime');
                            }
                          case 1:
                            {
                              index = 1;
                              context.go('/manga');
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
                ],
              ),
            ),
            routes: [
              GoRoute(
                parentNavigatorKey: _shellkey,
                name: 'anime',
                path: '/anime',
                builder: (context, state) {
                  index = 0;
                  return AniPage(
                    key: (state.queryParameters.isEmpty)
                        ? null
                        : Key(state.queryParameters['tag']!),
                    type: 'anime',
                    tag: state.queryParameters['tag'],
                  );
                },
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootKey,
                    path: 'info',
                    builder: (context, state) => InfoPage(
                      data: state.extra as AniData,
                    ),
                    routes: [
                      GoRoute(
                        parentNavigatorKey: _rootKey,
                        path: 'viewer',
                        builder: (context, state) => AniViewer(
                          episodes: (state.extra as Map)['contents'],
                          episode: (state.extra as Map)['content'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                parentNavigatorKey: _shellkey,
                name: 'manga',
                path: '/manga',
                builder: (context, state) {
                  index = 1;
                  return AniPage(
                    key: (state.queryParameters.isEmpty)
                        ? null
                        : Key(state.queryParameters['tag']!),
                    type: 'manga',
                    tag: state.queryParameters['tag'],
                  );
                },
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootKey,
                    path: 'info',
                    builder: (context, state) => InfoPage(
                      data: state.extra as AniData,
                    ),
                    routes: [
                      GoRoute(
                        parentNavigatorKey: _rootKey,
                        path: 'viewer',
                        builder: (context, state) => MangaReader(
                          chapter: (state.extra as Map)['content'],
                          chapters: (state.extra as Map)['contents'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                name: 'novel',
                path: '/novel',
                builder: (context, state) => const NovelPage(),
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootKey,
                    path: 'viewer',
                    builder: (context, state) => NovelReader(
                      data: state.extra as AniData,
                    ),
                  ),
                ],
              ),
              GoRoute(
                name: 'later',
                path: '/later',
                builder: (context, state) => const LaterPage(),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
