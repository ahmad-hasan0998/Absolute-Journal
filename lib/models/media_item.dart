import 'package:cloud_firestore/cloud_firestore.dart';

class MediaItem {
  String? id;
  int? tmdbId;
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
  int top5Order;
  String? posterUrl;
  int completedCount;
  DocumentSnapshot? snapshot;

  MediaItem({
    this.id,
    this.tmdbId,
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
    this.top5Order = 0,
    this.posterUrl,
    this.completedCount = 0,
    this.snapshot,
  });
}
