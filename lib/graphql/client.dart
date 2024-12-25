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
