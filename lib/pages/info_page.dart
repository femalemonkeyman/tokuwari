import '../media/providers/providers.dart';
import '/models/info_models.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../widgets/image.dart';

extension on Widget {
  Widget padBottom() {
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: this);
  }
}

class InfoPage extends StatefulWidget {
  final AniData data;
  final Isar isar = Isar.getInstance('later')!;

  InfoPage({required this.data, super.key});

  @override
  State createState() => InfoPageState();
}

class InfoPageState extends State<InfoPage> {
  final List<MediaProv> content = [];
  late Function init = providers[widget.data.type]![0]['data'];
  bool subs = false;

  @override
  void initState() {
    Future.microtask(
      () async => loadEpisodes(),
    );
    super.initState();
  }

  Future<void> loadEpisodes() async {
    content
      ..clear()
      ..addAll(
        await init(widget.data),
      );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text(widget.data.title),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom: 10,
              ),
              sliver: InfoArea(
                data: widget.data,
                button: ActionChip(
                  shape: const StadiumBorder(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(
                    () {
                      final media =
                          widget.isar.aniDatas.filter().mediaIdMatches(
                                widget.data.mediaId,
                              );
                      if (media.isEmptySync()) {
                        widget.isar.writeTxnSync(
                          () => widget.isar.aniDatas.putSync(widget.data),
                        );
                      } else {
                        widget.isar.writeTxnSync(
                          () => media.deleteAllSync(),
                        );
                      }
                    },
                  ),
                  avatar: (widget.isar.aniDatas
                          .filter()
                          .mediaIdMatches(widget.data.mediaId)
                          .isEmptySync())
                      ? Icon(MdiIcons.bookmarkOutline)
                      : Icon(MdiIcons.bookmark),
                  label: const Text("Later"),
                ),
                selector: DropdownButton(
                  value: init,
                  padding: const EdgeInsets.only(left: 15),
                  underline: const SizedBox.shrink(),
                  focusColor: const Color.fromARGB(0, 0, 0, 0),
                  borderRadius: BorderRadius.circular(30),
                  items: List.generate(
                    providers[widget.data.type]!.length,
                    (index) => DropdownMenuItem(
                      value: providers[widget.data.type]![index]['data'],
                      child: Text(
                        providers[widget.data.type]![index]['name'],
                      ),
                    ),
                    growable: false,
                  ),
                  onChanged: (value) => Future.microtask(
                    () async {
                      init = (value as Function);
                      await loadEpisodes();
                    },
                  ),
                ),
              ),
            ),
            if (content.isNotEmpty)
              EpisodeList(content: content, type: widget.data.type)
          ],
        ),
      ),
    );
  }
}

class InfoArea extends StatelessWidget {
  final AniData data;
  final Widget button;
  final Widget selector;

  const InfoArea({
    super.key,
    required this.data,
    required this.button,
    required this.selector,
  });

  @override
  Widget build(context) {
    final Widget expands = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        button.padBottom(),
        ExpandableText(
          data.description,
          expandText: "More",
          collapseText: "Less",
          maxLines: 4,
        ).padBottom(),
        Wrap(
          spacing: 3,
          runSpacing: 7,
          children: List.generate(
            data.tags.length.clamp(0, 15),
            (index) {
              return ActionChip(
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: Colors.blueGrey[800],
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                label: Text(
                  data.tags[index],
                ),
                onPressed: () => context.go(
                  '/${data.type}?tag=${data.tags[index]}',
                ),
              );
            },
          ),
        ).padBottom(),
      ],
    );
    final double ratio =
        MediaQuery.of(context).size.width / MediaQuery.of(context).size.height;
    return SliverList.list(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              flex: 7,
              fit: FlexFit.tight,
              child: AniImage(
                image: data.image,
              ).padBottom(),
            ),
            const SizedBox(
              width: 20,
            ),
            Expanded(
              flex: 15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    data.status,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Score: ${data.score}',
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Count: ${data.count}',
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ).padBottom(),
                  if (ratio > 1.2) expands,
                ],
              ),
            ),
          ],
        ),
        if (ratio < 1.2) expands,
        //  ⠄⠄⡔⠙⠢⡀⠄⠄⠄⢀⠼⠅⠈⢂⠄⠄⠄⠄
        //  ⠄⠄⡌⠄⢰⠉⢙⢗⣲⡖⡋⢐⡺⡄⠈⢆⠄⠄⠄
        //  ⠄⡜⠄⢀⠆⢠⣿⣿⣿⣿⢡⢣⢿⡱⡀⠈⠆⠄⠄
        //  ⠄⠧⠤⠂⠄⣼⢧⢻⣿⣿⣞⢸⣮⠳⣕⢤⡆⠄⠄
        //  ⢺⣿⣿⣶⣦⡇⡌⣰⣍⠚⢿⠄⢩⣧⠉⢷⡇⠄⠄
        //  ⠘⣿⣿⣯⡙⣧⢎⢨⣶⣶⣶⣶⢸⣼⡻⡎⡇⠄⠄
        //  ⠄⠘⣿⣿⣷⡀⠎⡮⡙⠶⠟⣫⣶⠛⠧⠁⠄⠄⠄
        //  ⠄⠄⠘⣿⣿⣿⣦⣤⡀⢿⣿⣿⣿⣄⠄⠄⠄⠄⠄
        //  ⠄⠄⠄⠈⢿⣿⣿⣿⣿⣷⣯⣿⣿⣷⣾⣿⣷⡄⠄
        //  ⠄⠄⠄⠄⠄⢻⠏⣼⣿⣿⣿⣿⡿⣿⣿⣏⢾⠇⠄
        //  ⠄⠄⠄⠄⠄⠈⡼⠿⠿⢿⣿⣦⡝⣿⣿⣿⠷⢀⠄
        //  ⠄⠄⠄⠄⠄⠄⡇⠄⠄⠄⠈⠻⠇⠿⠋⠄⠄⢘⡆
        //  ⠄⠄⠄⠄⠄⠄⠱⣀⠄⠄⠄⣀⢼⡀⠄⢀⣀⡜⠄
        //  ⠄⠄⠄⠄⠄⠄⠄⢸⣉⠉⠉⠄⢀⠈⠉⢏⠁⠄⠄
        //  ⠄⠄⠄⠄⠄⠄⡰⠃⠄⠄⠄⠄⢸⠄⠄⢸⣧⠄⠄
        //  ⠄⠄⠄⠄⠄⣼⣧⠄⠄⠄⠄⠄⣼⠄⠄⡘⣿⡆⠄
        //  ⠄⠄⠄⢀⣼⣿⡙⣷⡄⠄⠄⠄⠃⠄⢠⣿⢸⣿⡀
        //  ⠄⠄⢀⣾⣿⣿⣷⣝⠿⡀⠄⠄⠄⢀⡞⢍⣼⣿⠇
        //  ⠄⠄⣼⣿⣿⣿⣿⣿⣷⣄⠄⠄⠠⡊⠴⠋⠹⡜⠄
        //  ⠄⠄⣿⣿⣿⣿⣿⣿⣿⣿⡆⣤⣾⣿⣿⣧⠹⠄⠄
        //  ⠄⠄⢿⣿⣿⣿⣿⣿⣿⣿⢃⣿⣿⣿⣿⣿⡇⠄⠄
        //  ⠄⠄⠐⡏⠉⠉⠉⠉⠉⠄⢸⠛⠿⣿⣿⡟⠄⠄⠄
        //  ⠄⠄⠄⠹⡖⠒⠒⠒⠒⠊⢹⠒⠤⢤⡜⠁⠄⠄⠄
        //  ⠄⠄⠄⠄⠱⠄⠄⠄⠄⠄⢸
        selector,
      ],
    );
  }
}

class EpisodeList extends StatelessWidget {
  final String type;
  final List<MediaProv> content;

  const EpisodeList({super.key, required this.content, required this.type});

  @override
  Widget build(context) {
    return SliverPadding(
      padding: const EdgeInsets.only(left: 15, right: 15),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          mainAxisSpacing: 5,
          crossAxisSpacing: 6,
          maxCrossAxisExtent: 400,
          mainAxisExtent: 100,
        ),
        delegate: SliverChildBuilderDelegate(
          childCount: content.length,
          (context, index) {
            return GestureDetector(
              onTap: () => context.push(
                '/$type/info/viewer',
                extra: {
                  'content': index,
                  'contents': content,
                },
              ),
              child: Card(
                elevation: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        content[index].title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '${(type == 'anime') ? 'Episode:' : 'Chapter:'} ${content[index].number}',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
