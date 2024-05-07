import 'dart:io';
import 'dart:ui';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tokuwari/pages/settings_page.dart';
import 'package:tokuwari/viewers/Novel/media_novel.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tokuwari_models/info_models.dart';

import 'viewers/Anime/media_anime.dart';
import 'viewers/Manga/media_manga.dart';
import 'pages/novel_page.dart';
import 'pages/info_page.dart';
import 'pages/later_page.dart';
import 'pages/media_page.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();
  }
  MediaKit.ensureInitialized();
  Isar.open(
    schemas: [AniDataSchema, HistorySchema, NovDataSchema],
    name: "tokudb",
    directory: (await Directory('${(await getApplicationDocumentsDirectory()).path}/.tokuwari').create()).path,
  );
  runApp(
    Navigation(),
  );
}

class Navigation extends StatelessWidget {
  Navigation({super.key});

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/anime',
    routes: [
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootKey,
        builder: (context, state, shell) => Scaffold(
          body: shell,
          bottomNavigationBar: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: clampDouble(MediaQuery.of(context).size.width, 0, 384),
                ),
                child: NavigationBar(
                  elevation: 0,
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  onDestinationSelected: (value) => shell.goBranch(value),
                  selectedIndex: shell.currentIndex,
                  labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.ondemand_video_rounded),
                      label: 'Anime',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.menu_book_rounded),
                      label: 'Manga',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.book_rounded),
                      label: 'Novels',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.bookmark),
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
            routes: [
              GoRoute(
                name: 'anime',
                path: '/anime',
                builder: (context, state) => AniPage(
                  key: (state.uri.queryParameters.isEmpty) ? null : Key(state.uri.queryParameters['tag']!),
                  type: 'anime',
                  tag: state.uri.queryParameters['tag'],
                ),
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
                        onExit: (context, state) {
                          SystemChrome.setEnabledSystemUIMode(
                            SystemUiMode.manual,
                            overlays: SystemUiOverlay.values,
                          );
                          SystemChrome.setPreferredOrientations(
                            [],
                          );
                          return true;
                        },
                        builder: (context, state) => AniViewer(
                          episode: (state.extra as Map)['index'],
                          anime: (state.extra as Map)['data'],
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
                builder: (context, state) => AniPage(
                  key: (state.uri.queryParameters.isEmpty) ? null : Key(state.uri.queryParameters['tag']!),
                  type: 'manga',
                  tag: state.uri.queryParameters['tag'],
                ),
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
                          chapter: (state.extra as Map)['index'],
                          manga: (state.extra as Map)['data'],
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
                    builder: (context, state) => NovelViewer(
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
                builder: (context, state) => LaterPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        name: 'settings',
        path: '/settings',
        builder: (context, state) => Settings(),
      ),
    ],
  );

  @override
  Widget build(context) {
    return MaterialApp.router(
      themeMode: ThemeMode.dark,
      darkTheme: FlexThemeData.dark(
        useMaterial3: true,
        darkIsTrueBlack: true,
        scheme: FlexScheme.deepPurple,
        //typography: Typography.material2021(platform: Theme.of(context).platform),
      ),
      scrollBehavior: const Allow(),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}

class Allow extends MaterialScrollBehavior {
  const Allow();
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
