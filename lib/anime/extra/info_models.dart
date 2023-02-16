class AniData {
  final String title;
  final String description;
  AniData({required this.title, required this.description});
}

class AnimeData extends AniData {
  AnimeData(String description, String title)
      : super(description: description, title: title);
}

class MangaData extends AniData {
  MangaData(String description, String title)
      : super(description: description, title: title);
}
