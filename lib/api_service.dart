import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ==========================================
  // API KEYS
  // ==========================================
  static const String _tmdbKey = 'aafb295c383e755baf9065f43fc4bdd6';
  static const String _rawgKey = 'ca3a50a237ad4530a2c1600d9f743fd5';

  /// Master Search Function
  /// Takes a query and the category type, routes to the correct API,
  /// and normalizes the data into a standard format for the UI.
  Future<List<Map<String, dynamic>>> searchMedia(String query, String type) async {
    if (type == 'Movie' || type == 'Show') {
      return await _searchTMDB(query, type);
    } else if (type == 'Game') {
      return await _searchGames(query);
    } else if (type == 'Book') {
      return await _searchBooks(query);
    } else if (type == 'Anime') {
      return await _searchAnime(query);
    }
    return [];
  }

  // --- 1. TMDB (Movies & Shows) ---
  Future<List<Map<String, dynamic>>> _searchTMDB(String query, String requestedType) async {
    final url = Uri.parse('https://api.themoviedb.org/3/search/multi?api_key=$_tmdbKey&query=$query');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Map<String, dynamic>> normalizedList = [];

      for (var item in data['results']) {
        String mediaType = item['media_type'] == 'tv' ? 'Show' : 'Movie';

        // Filter: If user selected 'Movie', only show movies. If 'Show', only shows.
        if (mediaType != requestedType) continue;

        String title = item['title'] ?? item['name'] ?? 'Unknown';
        String? posterPath = item['poster_path'];

        normalizedList.add({
          'id': item['id'],
          'title': title,
          'type': mediaType,
          'posterUrl': posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : null,
          'total': 1, // Default, will be updated later for shows via getTMDBTotalEpisodes
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

  // --- 2. RAWG API (Games) ---
  Future<List<Map<String, dynamic>>> _searchGames(String query) async {
    final url = Uri.parse('https://api.rawg.io/api/games?key=$_rawgKey&search=$query');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Map<String, dynamic>> normalizedList = [];

      for (var item in data['results']) {
        normalizedList.add({
          'id': item['id'],
          'title': item['name'] ?? 'Unknown',
          'type': 'Game',
          'posterUrl': item['background_image'], // RAWG provides full URLs directly
          'total': 100, // Games default to 100% completion tracking
          'year': (item['released'] ?? '').toString().split('-').first,
        });
      }
      return normalizedList;
    }
    throw Exception('Failed to search RAWG Games');
  }

  // --- 3. Google Books API (Books, Manga, Comics) ---
  Future<List<Map<String, dynamic>>> _searchBooks(String query) async {
    // Google Books requires no API key
    final url = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=$query&maxResults=10');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Map<String, dynamic>> normalizedList = [];

      if (data['items'] != null) {
        for (var item in data['items']) {
          var info = item['volumeInfo'];
          // Replace http with https to avoid Flutter cleartext traffic errors
          String? thumb = info['imageLinks']?['thumbnail']?.replaceAll('http://', 'https://');

          normalizedList.add({
            'id': item['id'],
            'title': info['title'] ?? 'Unknown',
            'type': 'Book',
            'posterUrl': thumb,
            'total': info['pageCount'] ?? 1, // Track reading by pages
            'year': (info['publishedDate'] ?? '').toString().split('-').first,
          });
        }
      }
      return normalizedList;
    }
    throw Exception('Failed to search Google Books');
  }

  // --- 4. Jikan API (Anime via MyAnimeList) ---
  Future<List<Map<String, dynamic>>> _searchAnime(String query) async {
    // sfw=true filters out explicit content
    final url = Uri.parse('https://api.jikan.moe/v4/anime?q=$query&sfw=true');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Map<String, dynamic>> normalizedList = [];

      for (var item in data['data']) {
        normalizedList.add({
          'id': item['mal_id'],
          'title': item['title_english'] ?? item['title'] ?? 'Unknown',
          'type': 'Anime',
          'posterUrl': item['images']['jpg']['image_url'],
          'total': item['episodes'] ?? 1, // Jikan provides total episodes immediately
          'year': item['year']?.toString() ?? 'N/A',
        });
      }
      return normalizedList;
    }
    throw Exception('Failed to search Jikan API');
  }
}