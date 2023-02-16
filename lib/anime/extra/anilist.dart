const base = """
query (\$page: Int!, \$search: String, \$genre: [String])
  {
  Page(perPage: 50, page: \$page) {
    pageInfo {
      hasNextPage
      lastPage
      total
      currentPage
    },
      media(sort: [TRENDING_DESC], type: ANIME, search: \$search, genre_in: \$genre) {
        id
        title {
          romaji
          english
          native
        }
        type
        chapters
        averageScore
        episodes
        description(asHtml: false)
        coverImage{
          extraLarge
        }
        episodes
        tags {
          name
        }
      }
  }
}
""";
