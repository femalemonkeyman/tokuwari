import 'dart:ui';
import 'package:tokuwari/graphql/client.dart';
import 'package:tokuwari/models/anidata.dart';

import 'package:flutter/material.dart';
import 'package:graphql/client.dart';
import 'package:tokuwari/models/constants.dart';
import 'package:tokuwari/models/repo.dart';
import '../widgets/search_button.dart';
import '../widgets/grid.dart';

class AniPage extends StatefulWidget {
  final String? tag;
  final String type;

  const AniPage({super.key, required this.type, this.tag});

  @override
  State<AniPage> createState() => _AniPageState();
}

class _AniPageState extends State<AniPage> {
  static final _client = GQL.client;
  final _textController = TextEditingController();
  final _box = Repo.i.settings;
  final _selectedGenres = <String>[];
  final _animeData = <AniData>[];
  final _pageInfo = <String, dynamic>{};
  late String? _tag = widget.tag;
  String? _search;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _queryData());
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _queryData() async {
    try {
      final result = await _client.query(
        QueryOptions(
          fetchPolicy: FetchPolicy.networkOnly,
          document: gql(qString),
          variables: {
            'page': _pageInfo['currentPage'] == null ? 1 : _pageInfo['currentPage'] + 1,
            'type': widget.type.toUpperCase(),
            'search': _search,
            'genre': _selectedGenres.isEmpty ? null : _selectedGenres,
            'tag': _tag,
            if (_box.get(1)?.isNsfw != true) 'adult': false,
          },
        ),
      );
      if (result.hasException) {
        debugPrint(result.exception.toString());
        return;
      }
      final data = result.data?['Page'];
      if (data != null) {
        setState(() {
          _pageInfo
            ..clear()
            ..addAll(data['pageInfo']);
          _animeData.addAll([for (final m in data['media']) AniData.fromJson(m, widget.type)]);
          _pageInfo['loading'] = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching AniList data: $e');
    }
  }

  Future<void> _updateGenreFilter() async {
    final width = clampDouble(MediaQuery.of(context).size.width, 0, 384);
    await showModalBottomSheet(
      context: context,
      constraints: BoxConstraints.tightFor(width: width),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(15),
          child: StatefulBuilder(
            builder: (context, modalState) {
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final genre in AniConstants.genresList)
                    FilterChip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      labelPadding: EdgeInsets.zero,
                      label: Text(genre),
                      selected: _selectedGenres.contains(genre),
                      onSelected:
                          (bool value) => modalState(() {
                            value ? _selectedGenres.add(genre) : _selectedGenres.remove(genre);
                          }),
                    ),
                ],
              );
            },
          ),
        );
      },
    );

    setState(() {
      _pageInfo.clear();
      _animeData.clear();
    });
    await _queryData();
  }

  Future<void> _searchData() async {
    _pageInfo['currentPage'] = 0;
    _animeData.clear();
    _selectedGenres.clear();
    if (_textController.text.isNotEmpty) {
      _search = _textController.text;
    } else {
      _tag = null;
      _search = null;
    }
    print('here');
    await _queryData();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!_pageInfo['loading'] &&
            notification.metrics.pixels == notification.metrics.maxScrollExtent &&
            _pageInfo['currentPage'] != _pageInfo['lastPage']) {
          _pageInfo['loading'] = true;
          _queryData();
        }
        return false;
      },
      child: RefreshIndicator(
        edgeOffset: 100,
        onRefresh: () async {
          _pageInfo.clear();
          _animeData.clear();
          await _queryData();
        },
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SearchButton(text: widget.type, controller: _textController, search: _searchData),
              SliverToBoxAdapter(
                child: Center(child: TextButton(onPressed: _updateGenreFilter, child: const Text("Filter by genre"))),
              ),
              if (_animeData.isNotEmpty)
                Grid(data: _animeData)
              else
                const SliverToBoxAdapter(
                  child: Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator())),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
