import 'dart:ui';
import 'media/media_anime.dart';
import 'media/media_manga.dart';
import 'pages/later_page.dart';
import '/novel/novel_reader.dart';
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
import 'pages/info_page.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellkey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  Isar.openSync(
    [AniDataSchema, MediaProvSchema, NovDataSchema],
    name: "later",
    directory: (await Directory(
                '${(await getApplicationDocumentsDirectory()).path}/.anicross')
            .create())
        .path,
  );
  runApp(
    MaterialApp.router(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 119, 0, 255),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        chipTheme: const ChipThemeData(
          showCheckmark: false,
          side: BorderSide(
            color: Color.fromARGB(171, 121, 120, 120),
          ),
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
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => Scaffold(
              body: shell,
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
                      currentIndex: shell.currentIndex,
                      onTap: (value) => shell.goBranch(value),
                      items: [
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
            branches: [
              StatefulShellBranch(
                navigatorKey: _shellkey,
                routes: [
                  GoRoute(
                    name: 'anime',
                    path: '/anime',
                    builder: (context, state) {
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
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    name: 'manga',
                    path: '/manga',
                    builder: (context, state) {
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
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    name: 'novel',
                    path: '/novel',
                    builder: (context, state) => const NovelPage(),
                    routes: [
                      GoRoute(
                        parentNavigatorKey: _rootKey,
                        path: 'viewer',
                        builder: (context, state) => NovelReader(
                          data: state.extra as NovData,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    name: 'later',
                    path: '/later',
                    builder: (context, state) => const LaterPage(),
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
