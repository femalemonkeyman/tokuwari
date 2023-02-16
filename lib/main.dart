import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'anime/anime.dart';
import 'manga/manga.dart';
import 'novel/novel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter("anisettings");
  Hive.openBox("settings");
  runApp(
    MaterialApp(
      theme: ThemeData(
        dividerColor: Colors.transparent,
        brightness: Brightness.dark,
        primaryColor: Colors.purple,
        scaffoldBackgroundColor: const Color.fromARGB(200, 0, 0, 20),
        colorScheme:
            ColorScheme.fromSwatch(primarySwatch: Colors.purple).copyWith(
          background: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: OpenUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: OpenUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: OpenUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        "Dashboard": (context) => const AniNav(),
      },
      initialRoute: 'Dashboard',
    ),
  );
}

class AniNav extends StatelessWidget {
  const AniNav({Key? key}) : super(key: key);

  @override
  Widget build(context) {
    return const Scaffold(
      body: DefaultTabController(
        length: 4,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    AniPage(),
                    MangaPage(),
                    NovelPage(),
                    SizedBox.shrink(),
                  ],
                ),
              ),
              TabBar(
                unselectedLabelStyle: TextStyle(fontSize: 0),
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 2, color: Colors.blue),
                  insets: EdgeInsets.fromLTRB(50, 0, 50, 8),
                ),
                tabs: [
                  Tab(
                    child: Wrap(
                      children: [
                        Icon(MdiIcons.youtubeTv),
                        SizedBox(
                          width: 10,
                        ),
                        Text("Anime"),
                      ],
                    ),
                  ),
                  Tab(
                    child: Wrap(
                      children: [
                        Icon(MdiIcons.bookOpenOutline),
                        SizedBox(
                          width: 10,
                        ),
                        Text("Manga"),
                      ],
                    ),
                  ),
                  Tab(
                    child: Wrap(
                      children: [
                        Icon(MdiIcons.book),
                        SizedBox(
                          width: 10,
                        ),
                        Text("Novel"),
                      ],
                    ),
                  ),
                  Tab(
                    child: Wrap(
                      children: [
                        Icon(MdiIcons.bookmark),
                        SizedBox(
                          width: 10,
                        ),
                        Text("Saved"),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
