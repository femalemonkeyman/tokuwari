import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'media/media_anime.dart';
import 'media/media_manga.dart';
import 'pages/later_page.dart';
import '/novel/novel_reader.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'media/media.dart';
import 'models/info_models.dart';
import 'novel/novel.dart';
import 'pages/info_page.dart';

final GlobalKey<NavigatorState> _rootKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellkey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  if (!Platform.isAndroid && !Platform.isIOS) {
    await WindowManager.instance.ensureInitialized();
  }
  Isar.openSync(
    [AniDataSchema, MediaProvSchema, NovDataSchema],
    name: "later",
    directory: (await Directory(
                '${(await getApplicationDocumentsDirectory()).path}/.anicross')
            .create())
        .path,
  );
  runApp(
    const Navigation(),
  );
}

class Navigation extends StatelessWidget {
  const Navigation({super.key});

  @override
  Widget build(context) {
    return MaterialApp.router(
      themeMode: ThemeMode.dark,
      darkTheme: FlexThemeData.dark(
        useMaterial3: true,
        darkIsTrueBlack: true,
        scheme: FlexScheme.deepPurple,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
          },
        ),
        typography: Typography.material2021(platform: defaultTargetPlatform),
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
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.ondemand_video_rounded),
                          label: 'Anime',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.menu_book_rounded),
                          label: 'Manga',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.book_rounded),
                          label: 'Novels',
                        ),
                        BottomNavigationBarItem(
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
                navigatorKey: _shellkey,
                routes: [
                  GoRoute(
                    name: 'anime',
                    path: '/anime',
                    builder: (context, state) => AniPage(
                      key: (state.uri.queryParameters.isEmpty)
                          ? null
                          : Key(state.uri.queryParameters['tag']!),
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
                    builder: (context, state) => AniPage(
                      key: (state.uri.queryParameters.isEmpty)
                          ? null
                          : Key(state.uri.queryParameters['tag']!),
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
                    builder: (context, state) => LaterPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
