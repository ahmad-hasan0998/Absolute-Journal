import 'media_item.dart';

class Friend {
  String name;
  int rank;
  int xp;
  bool isAdded;
  List<MediaItem> allMedia;

  Friend({
    required this.name,
    required this.rank,
    required this.xp,
    this.isAdded = true,
    required this.allMedia,
  });
}

// Dummy data to populate your network
class MockNetwork {
  static List<Friend> friends = [
    Friend(
      name: 'Omar', rank: 1, xp: 2100,
      allMedia: [
        MediaItem(title: 'Jujutsu Kaisen', type: 'Anime', status: 'Completed', progress: 24, total: 24, lastUpdated: '2 hrs ago', posterUrl: 'https://image.tmdb.org/t/p/w500/hFWP5HkbVEe40hrptcgHQLe2nUC.jpg', completedCount: 2),
        MediaItem(title: 'The Dark Knight', type: 'Movie', status: 'Completed', progress: 1, total: 1, lastUpdated: 'Yesterday', posterUrl: 'https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg', completedCount: 1),
      ],
    ),
    Friend(
      name: 'Sara', rank: 2, xp: 1850,
      allMedia: [
        MediaItem(title: 'Interstellar', type: 'Movie', status: 'Completed', progress: 1, total: 1, lastUpdated: '3 days ago', posterUrl: 'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg', completedCount: 1),
      ],
    ),
    Friend(name: 'Khaled', rank: 4, xp: 1200, isAdded: false, allMedia: []),
    Friend(name: 'Lana', rank: 5, xp: 950, isAdded: true, allMedia: []),
  ];
}