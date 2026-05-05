class MediaItem {
  String title;
  String type;
  String status;
  int progress;
  int total;
  String lastUpdated;
  bool? isLiked;
  bool isWatchLater;
  String? posterUrl;
  int completedCount; // NEW: Tracks rewatches!

  MediaItem({
    required this.title,
    required this.type,
    required this.status,
    this.progress = 0,
    this.total = 1,
    required this.lastUpdated,
    this.isLiked,
    this.isWatchLater = false,
    this.posterUrl,
    this.completedCount = 0, // Defaults to 0
  });
}