import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';
class ApiService {
  static const String _tmdbKey = 'aafb295c383e755baf9065f43fc4bdd6';
  DateTime _parseSmartDate(String dateStr, String type) {
    DateTime baseDate = DateTime.parse(dateStr);
    if (type == 'Show') {
      DateTime utcDrop = DateTime.utc(baseDate.year, baseDate.month, baseDate.day).add(const Duration(hours: 26));
      return utcDrop.toLocal();
    }
    return baseDate.toLocal();
  }
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
        normalizedList.add({'id': item['id'], 'title': title, 'type': mediaType, 'posterUrl': posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : null, 'total': 1, 'year': (item['release_date'] ?? item['first_air_date'] ?? '').toString().split('-').first});
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
  Future<Map<int, List<Map<String, dynamic>>>> getPersonalizedSchedule(int year, int month, List<MediaItem> userItems) async {
    Map<int, List<Map<String, dynamic>>> schedule = {};
    for (var item in userItems) {
      if (item.tmdbId == null) continue;
      try {
        if (item.type == 'Movie') {
          final res = await http.get(Uri.parse('https://api.themoviedb.org/3/movie/${item.tmdbId}?api_key=$_tmdbKey'));
          if (res.statusCode == 200) {
            var data = json.decode(res.body);
            String? rDate = data['release_date'];
            if (rDate != null && rDate.isNotEmpty) {
              DateTime dt = _parseSmartDate(rDate, 'Movie');
              if (dt.year == year && dt.month == month) {
                schedule.putIfAbsent(dt.day, () => []).add({'title': item.title, 'posterUrl': item.posterUrl, 'type': 'Movie'});
              }
            }
          }
        } else if (item.type == 'Show') {
          final res = await http.get(Uri.parse('https://api.themoviedb.org/3/tv/${item.tmdbId}?api_key=$_tmdbKey'));
          if (res.statusCode == 200) {
            var data = json.decode(res.body);
            List seasons = data['seasons'] ?? [];
            for (var s in seasons) {
              if (s['season_number'] == 0) continue;
              String? sDate = s['air_date'];
              if (sDate != null && sDate.isNotEmpty) {
                DateTime sDt = _parseSmartDate(sDate, 'Show');
                int monthDiff = (year - sDt.year) * 12 + (month - sDt.month);
                if (monthDiff >= -2 && monthDiff <= 8) {
                  final epRes = await http.get(Uri.parse('https://api.themoviedb.org/3/tv/${item.tmdbId}/season/${s['season_number']}?api_key=$_tmdbKey'));
                  if (epRes.statusCode == 200) {
                    var epData = json.decode(epRes.body);
                    List episodes = epData['episodes'] ?? [];
                    for (var ep in episodes) {
                      String? eDate = ep['air_date'];
                      if (eDate != null && eDate.isNotEmpty) {
                        DateTime eDt = _parseSmartDate(eDate, 'Show');
                        if (eDt.year == year && eDt.month == month) {
                          schedule.putIfAbsent(eDt.day, () => []).add({'title': '${item.title} \nS${s['season_number']} E${ep['episode_number']}', 'posterUrl': item.posterUrl, 'type': 'Show'});
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        print('Error fetching schedule for ${item.title}: $e');
      }
    }
    return schedule;
  }
}