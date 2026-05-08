import 'package:cloud_firestore/cloud_firestore.dart';

class SeedService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> injectDummyData() async {
    final List<Map<String, dynamic>> dummyUsers = [
      {
        'uid': 'dummy_1',
        'profileName': 'Sarah Connor',
        'username': 'sarah_connor',
        'rank': 'Diamond Master',
        'xp_score': 24500,
        'last_month_xp': 32000,
        'streak': 12,
        'profileUrl':
            'https://image.tmdb.org/t/p/w500/vqzNJRH4YyquRiWxCCOH0aXggHI.jpg',
        'friends': ['dummy_2', 'dummy_3', 'dummy_4', 'dummy_5'],
      },
      {
        'uid': 'dummy_2',
        'profileName': 'Bruce Wayne',
        'username': 'bruce_wayne',
        'rank': 'Platinum Tracker',
        'xp_score': 15200,
        'last_month_xp': 28000,
        'streak': 5,
        'profileUrl':
            'https://image.tmdb.org/t/p/w500/8rw2UZs9d2t80j44zWkssScc12.jpg',
        'friends': ['dummy_1', 'dummy_3', 'dummy_4', 'dummy_5'],
      },
      {
        'uid': 'dummy_3',
        'profileName': 'Peter Parker',
        'username': 'peter_parker',
        'rank': 'Gold Cinephile',
        'xp_score': 8400,
        'last_month_xp': 25000,
        'streak': 2,
        'profileUrl':
            'https://image.tmdb.org/t/p/w500/q719jXXEzOoYaps6babgKnONONX.jpg',
        'friends': ['dummy_1', 'dummy_2', 'dummy_4', 'dummy_5'],
      },
      {
        'uid': 'dummy_4',
        'profileName': 'Ellen Ripley',
        'username': 'ellen_ripley',
        'rank': 'Silver Binger',
        'xp_score': 4100,
        'last_month_xp': 12000,
        'streak': 0,
        'profileUrl':
            'https://image.tmdb.org/t/p/w500/wM2oQkK1qQzZ964J4lH0hDqZq5.jpg',
        'friends': ['dummy_1', 'dummy_2', 'dummy_3', 'dummy_5'],
      },
      {
        'uid': 'dummy_5',
        'profileName': 'Tony Stark',
        'username': 'tony_stark',
        'rank': 'Bronze Watcher',
        'xp_score': 1200,
        'last_month_xp': 800,
        'streak': 1,
        'profileUrl':
            'https://image.tmdb.org/t/p/w500/7WsyChQLEftFiDOVTGkv3hFpyyt.jpg',
        'friends': ['dummy_1', 'dummy_2', 'dummy_3', 'dummy_4'],
      },
    ];

    final List<Map<String, dynamic>> sampleMedia = [
      {
        'tmdbId': 155,
        'title': 'The Dark Knight',
        'type': 'Movie',
        'posterUrl':
            'https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
      },
      {
        'tmdbId': 1949,
        'title': 'Zodiac',
        'type': 'Movie',
        'posterUrl':
            'https://image.tmdb.org/t/p/w500/6epxrENkoOtiA160R0B8pWe8K6B.jpg',
      },
      {
        'tmdbId': 1891,
        'title': 'Star Wars: Episode III',
        'type': 'Movie',
        'posterUrl':
            'https://image.tmdb.org/t/p/w500/xfSAOEMkiL0FAc8A0iE0o012yUa.jpg',
      },
      {
        'tmdbId': 85552,
        'title': 'Euphoria',
        'type': 'Show',
        'total': 18,
        'posterUrl':
            'https://image.tmdb.org/t/p/w500/3Q0hd3heuWwDWpwcDcgEZvAghjW.jpg',
      },
      {
        'tmdbId': 1396,
        'title': 'Breaking Bad',
        'type': 'Show',
        'total': 62,
        'posterUrl':
            'https://image.tmdb.org/t/p/w500/30erzlzIOtOK3k3T3BAl1GiVMP1.jpg',
      },
      {
        'tmdbId': 71728,
        'title': 'Young Sheldon',
        'type': 'Show',
        'total': 141,
        'posterUrl':
            'https://image.tmdb.org/t/p/w500/sKvxkQx58fQnE68r838UuY0gZ3A.jpg',
      },
      {
        'tmdbId': 114472,
        'title': 'Secret Level',
        'type': 'Show',
        'total': 15,
        'posterUrl':
            'https://image.tmdb.org/t/p/w500/b1T4W8xNOr9o7XhD71O69A6q1c0.jpg',
      },
    ];

    try {
      for (var user in dummyUsers) {
        await _db.collection('users').doc(user['uid']).set({
          'profileName': user['profileName'],
          'username': user['username'],
          'rank': user['rank'],
          'xp_score': user['xp_score'],
          'last_month_xp': user['last_month_xp'],
          'streak': user['streak'],
          'profileUrl': user['profileUrl'],
          'friends': user['friends'],
          'blocked_users': [],
          'last_activity_date': FieldValue.serverTimestamp(),
          'created_at': FieldValue.serverTimestamp(),
        });

        int top5Counter = 0;
        for (int i = 0; i < sampleMedia.length; i++) {
          var media = sampleMedia[i];
          bool isCompleted = i % 2 == 0;
          bool isTop5 = isCompleted && top5Counter < 5;
          if (isTop5) top5Counter++;

          var docRef = await _db
              .collection('users')
              .doc(user['uid'])
              .collection('my_journal')
              .add({
                'tmdbId': media['tmdbId'],
                'title': media['title'],
                'type': media['type'],
                'status': isCompleted ? 'Completed' : 'Active',
                'progress': isCompleted ? (media['total'] ?? 1) : 1,
                'total': media['total'] ?? 1,
                'posterUrl': media['posterUrl'],
                'isWatchLater': !isCompleted && i == 6,
                'isTop5': isTop5,
                'top5Order': isTop5 ? top5Counter - 1 : 0,
                'completedCount': isCompleted ? 1 : 0,
                'isLiked': isCompleted ? true : null,
                'timestamp': Timestamp.fromDate(
                  DateTime.now().subtract(Duration(days: i)),
                ),
              });

          if (isCompleted) {
            await _db
                .collection('users')
                .doc(user['uid'])
                .collection('history_logs')
                .add({
                  'mediaId': docRef.id,
                  'title': media['title'],
                  'type': media['type'],
                  'action': media['type'] == 'Movie'
                      ? 'Watched Movie'
                      : 'Completed Show',
                  'timestamp': Timestamp.fromDate(
                    DateTime.now().subtract(Duration(days: i, hours: 2)),
                  ),
                  'posterUrl': media['posterUrl'],
                  'isLiked': true,
                });
          }
        }
      }
    } catch (e) {
      print("Error Seeding: $e");
    }
  }
}
