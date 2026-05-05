import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _tmdbKey = 'aafb295c383e755baf9065f43fc4bdd6';

  Future<List<Map<String, dynamic>>> searchMedia(String query, String type) async {
    if (type == 'Movie' || type == 'Show') {
      return await _searchTMDB(query, type);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _searchTMDB(String query, String requestedType) async {
    final url = Uri.parse('https://api.themoviedb.org/3/search/multi?api_key=$_tmdbKey&query=$query');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Map<String, dynamic>> normalizedList = [];

      for (var item in data['results']) {
        String mediaType = item['media_type'] == 'tv' ? 'Show' : 'Movie';

        if (mediaType != requestedType) continue;

        String title = item['title'] ?? item['name'] ?? 'Unknown';
        String? posterPath = item['poster_path'];

        normalizedList.add({
          'id': item['id'],
          'title': title,
          'type': mediaType,
          'posterUrl': posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : null,
          'total': 1,
          'year': (item['release_date'] ?? item['first_air_date'] ?? '').toString().split('-').first,
        });
      }
      return normalizedList;
    }
    throw Exception('Failed to search TMDB');
  }

  Future<int> getTMDBTotalEpisodes(int showId) async {
    final url = Uri.parse('https://api.themoviedb.org/3/tv/$showId?api_key=$_tmdbKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body)['number_of_episodes'] ?? 1;
      }
    } catch (e) {
      print(e);
    }
    return 1;
  }
}