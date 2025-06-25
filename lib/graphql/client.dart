import 'package:graphql/client.dart';

class GQL {
  static final client = GraphQLClient(
    cache: GraphQLCache(),
    link: HttpLink(
      "https://graphql.anilist.co/",
      defaultHeaders: {
        'referer': 'https://anilist.co/',
        'origin': 'https://anilist.co',
        'user-agent':
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
      },
    ),
  );
}

const qString = """
query (\$page: Int!, \$type: MediaType, \$tag: String, \$search: String, \$genre: [String], \$adult: Boolean)
  {
  Page(perPage: 50, page: \$page) {
    pageInfo {
      hasNextPage
      lastPage
      total
      currentPage
    },
    media(sort: [TRENDING_DESC], type: \$type, search: \$search, genre_in: \$genre, tag: \$tag, isAdult: \$adult) {
      id
      title {
        romaji
        english
        native
      }
      status
      chapters
      idMal
      genres
      status
      averageScore
      description(asHtml: false)
      episodes
      relations {
        edges {
          id
          node {
            id
          }
        }
      }
      coverImage {
        extraLarge
      }
      tags {
        name
      }
    }
  }
}
""";
