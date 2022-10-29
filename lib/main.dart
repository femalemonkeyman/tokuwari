import 'package:anicross/anigrid.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:universal_io/io.dart';
import 'anime.dart';
import 'epub.dart';
import 'anisearch.dart';
import 'manga.dart';

void main() async {
  await DartVLC.initialize();
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter("anisettings");
  Hive.openBox("settings");
  runApp(
    MaterialApp(
      theme: ThemeData(
        dividerColor: Colors.transparent,
        primarySwatch: Colors.purple,
        brightness: Brightness.dark,
        primaryColor: Colors.purple,
        backgroundColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.black,
        /* dark theme settings */
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
                decoration: BoxDecoration(
                  color: const Color.fromARGB(200, 0, 0, 20),
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

class NovelPage extends StatefulWidget {
  const NovelPage({Key? key}) : super(key: key);

  @override
  State createState() => NovelPageState();
}

class NovelPageState extends State {
  Directory? directory;
  @override
  Widget build(context) {
    return ListView(
      controller: ScrollController(),
      primary: false,
      shrinkWrap: true,
      children: [
        const Center(
          child: SearchButton(
            text: "local novels",
          ),
        ),
        if (Hive.box("settings").get("novels") == null)
          StreamBuilder(
              stream: importBooks(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  //print(snapshot.data);
                  setState(() {});
                  return Text(snapshot.data.toString());
                }
                return const CircularProgressIndicator();
              }
              //child: const Text("Please select a directory"),
              ),
        if (Hive.box("settings").get("novels") != null)
          AniGrid(
              data: Hive.box("settings").get("novels"), place: "local novels"),
        IconButton(
          onPressed: () {
            Hive.box("settings").delete("novels");
            setState(() {});
          },
          icon: const Icon(Icons.refresh),
        )
      ],
    );
  }
}
