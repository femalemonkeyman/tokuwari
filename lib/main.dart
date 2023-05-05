import 'package:anicross/models/color_schemes.g.dart';
import 'package:anicross/later_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:isar/isar.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'anime/anime.dart';
import 'manga/manga.dart';
import 'models/info_models.dart';
import 'novel/novel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  Isar.openSync(
    [AniDataSchema, MediaSchema],
    name: "later",
    directory: '${dir.path}/.anicross',
  );
  Isar.openSync(
    [AniDataSchema],
    name: "novels",
    directory: '${dir.path}/.anicross',
  );
  runApp(
    MaterialApp(
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: DefaultTabController(
        length: 4,
        child: SafeArea(
          child: Column(
            children: [
              const Expanded(
                child: TabBarView(
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    AniPage(),
                    MangaPage(),
                    NovelPage(),
                    LaterPage(),
                  ],
                ),
              ),
              SizedBox(
                width: clampDouble(MediaQuery.of(context).size.width, 0, 384),
                child: const TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.all(
                      Radius.circular(15),
                    ),
                  ),
                  tabs: [
                    Tab(
                      child: Icon(MdiIcons.youtubeTv),
                    ),
                    Tab(
                      child: Icon(MdiIcons.bookOpenOutline),
                    ),
                    Tab(
                      child: Icon(MdiIcons.book),
                    ),
                    Tab(
                      child: Icon(MdiIcons.bookmark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
