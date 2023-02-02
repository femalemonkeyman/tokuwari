import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
      body: DefaultTabController(
        length: 3,
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
                  ],
                ),
              ),
              Container(
                //margin: const EdgeInsets.only(bottom: 20),
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(200, 0, 0, 20),
                ),
                child: const TabBar(
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(width: 2, color: Colors.blue),
                    insets: EdgeInsets.fromLTRB(50, 0, 50, 8),
                  ),
                  tabs: [
                    Tab(
                      text: "Anime",
                    ),
                    Tab(
                      text: "Manga",
                    ),
                    Tab(
                      text: "Novel",
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
