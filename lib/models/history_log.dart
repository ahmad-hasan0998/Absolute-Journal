class HistoryLog {
  String? id;
  String mediaId;
  String title;
  String type;
  String action;
  DateTime timestamp;
  String? posterUrl;
  bool? isLiked;
  HistoryLog({this.id, required this.mediaId, required this.title, required this.type, required this.action, required this.timestamp, this.posterUrl, this.isLiked});
}