import 'package:anicross/anigrid.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:universal_io/io.dart';
import 'epub.dart';
import 'functions.dart';
import 'anisearch.dart';

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
          child: Stack(
            children: [
              const TabBarView(
                physics: NeverScrollableScrollPhysics(),
                children: [
                  AniPage(),
                  MangaPage(),
                  NovelPage(),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  width: MediaQuery.of(context).size.width / 1.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: const Color.fromARGB(255, 0, 0, 0),
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

class MangaPage extends StatelessWidget {
  const MangaPage({Key? key}) : super(key: key);

  @override
  Widget build(context) {
    return ListView(
      controller: ScrollController(),
      primary: false,
      children: [
        const Center(
          child: SearchButton(
            text: "mangadex",
          ),
        ),
        FutureBuilder<dynamic>(
          future: dexList(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return AniGrid(
                data: snapshot.data['data'],
                place: "mangadex",
              );
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ],
    );
  }
}

class AniPage extends StatelessWidget {
  const AniPage({Key? key}) : super(key: key);

  @override
  Widget build(context) {
    return ListView(
      controller: ScrollController(),
      primary: false,
      children: [
        const Center(
          child: SearchButton(
            text: "anilist",
          ),
        ),
        GraphQLProvider(
          client: client,
          child: Query(
            options: QueryOptions(
              document: gql(base),
            ),
            builder: (result, {refetch, fetchMore}) {
              if (result.hasException) {
                print(result.exception);
              }
              if (result.isNotLoading) {
                var data = result.data!['Page']['media'];
                return AniGrid(
                  data: data,
                  place: "anilist",
                );
              }
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SearchButton extends StatelessWidget {
  const SearchButton({Key? key, required this.text}) : super(key: key);

  final String text;

  @override
  Widget build(context) {
    return GestureDetector(
      onTap: (() => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AniSearch(
                place: text,
              ),
            ),
          )),
      child: Container(
        padding: const EdgeInsets.only(left: 10, right: 10),
        margin: const EdgeInsets.only(bottom: 20, top: 20),
        height: 45,
        width: MediaQuery.of(context).size.width / 1.5,
        decoration: BoxDecoration(
          color: Colors.blueGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.search),
            const Spacer(),
            const Text("Search"),
            const Spacer(
              flex: 95,
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
      ),
    );
  }
}
