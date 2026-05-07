class MediaItem {
  String? id;
  String title;
  String type;
  String status;
  int progress;
  int total;
  String lastUpdated;
  DateTime? timestamp;
  bool? isLiked;
  bool isWatchLater;
  bool isTop5;
  String? posterUrl;
  int completedCount;
  MediaItem({
    this.id,
    required this.title,
    required this.type,
    required this.status,
    this.progress = 0,
    this.total = 1,
    required this.lastUpdated,
    this.timestamp,
    this.isLiked,
    this.isWatchLater = false,
    this.isTop5 = false,
    this.posterUrl,
    this.completedCount = 0,
  });
}
