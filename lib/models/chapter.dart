class Chapter {
  /// Each page should be a link to the image
  final List<String> pages;

  /// Any headers you might need for the request
  final Map<String, String>? headers;

  const Chapter({required this.pages, this.headers});
}
